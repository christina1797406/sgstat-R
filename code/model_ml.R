# =========================================================
# MACHINE LEARNING MODEL FOR TFR AND TLB
# =========================================================
#
# This script implements the client/Gerald feedback for the ML section:
#
# - start with lag1 to lag12 as candidate inputs
# - avoid using year as a direct predictor
# - keep the ML model simple and explainable
# - use backward elimination to remove weaker lag predictors
# - include Chinese Zodiac as an external categorical predictor
# - compare lag-only models against lag + Zodiac models
# - evaluate with MSE, RMSE, MAE, MAPE, actual-vs-predicted plots,
#   and training residual white-noise diagnostics
#
# The final ML model is intentionally presented as a comparison model, not as
# a replacement for ARIMA/SARIMA residual validation.

library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)

set.seed(123)

MAX_LAG <- 12
P_THRESHOLD <- 0.10
LJUNG_LAG <- 12
WHITE_NOISE_ALPHA <- 0.05

ZODIACS <- c(
  "Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
  "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"
)

dir.create("outputs", showWarnings = FALSE)
dir.create("outputs/forecasts", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/models", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/plots", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/plots/ml_summary", recursive = TRUE, showWarnings = FALSE)
dir.create("selected_figures/core", recursive = TRUE, showWarnings = FALSE)

zodiac_year <- function(year) {
  factor(ZODIACS[((year - 2020) %% 12) + 1], levels = ZODIACS)
}

read_series <- function(path, target_col) {
  data <- read_csv(path, show_col_types = FALSE)

  data %>%
    select(year, all_of(target_col)) %>%
    mutate(
      year = as.integer(year),
      across(all_of(target_col), as.numeric)
    ) %>%
    arrange(year) %>%
    drop_na()
}

create_lagged_data <- function(data, target_col, max_lag = MAX_LAG) {
  data <- data %>%
    arrange(year) %>%
    mutate(Zodiac = zodiac_year(year))

  for (lag_i in seq_len(max_lag)) {
    lag_name <- paste0("lag", lag_i)
    data[[lag_name]] <- c(
      rep(NA_real_, lag_i),
      data[[target_col]][seq_len(nrow(data) - lag_i)]
    )
  }

  data %>% drop_na()
}

fit_lag_model <- function(train_features, target_col, include_zodiac) {
  selected_lags <- paste0("lag", seq_len(MAX_LAG))
  removed_lags <- character(0)

  build_formula <- function(lag_terms) {
    rhs <- lag_terms
    if (include_zodiac) {
      rhs <- c(rhs, "Zodiac")
    }

    as.formula(paste(target_col, "~", paste(rhs, collapse = " + ")))
  }

  fit <- lm(build_formula(selected_lags), data = train_features)

  repeat {
    coef_table <- coef(summary(fit))
    available_lags <- intersect(selected_lags, rownames(coef_table))

    if (length(available_lags) <= 1) {
      break
    }

    lag_p_values <- coef_table[available_lags, "Pr(>|t|)", drop = TRUE]
    lag_p_values[is.na(lag_p_values)] <- 1

    worst_lag <- names(which.max(lag_p_values))
    worst_p <- max(lag_p_values, na.rm = TRUE)

    if (worst_p <= P_THRESHOLD) {
      break
    }

    selected_lags <- setdiff(selected_lags, worst_lag)
    removed_lags <- c(removed_lags, worst_lag)
    fit <- lm(build_formula(selected_lags), data = train_features)
  }

  list(
    fit = fit,
    selected_lags = selected_lags,
    removed_lags = removed_lags,
    include_zodiac = include_zodiac
  )
}

recursive_forecast <- function(model_info, train_data, test_data, target_col) {
  history <- as.numeric(train_data[[target_col]])
  predictions <- numeric(nrow(test_data))

  for (i in seq_len(nrow(test_data))) {
    new_row <- data.frame(year = as.integer(test_data$year[i]))
    new_row$Zodiac <- zodiac_year(new_row$year)

    for (lag_i in seq_len(MAX_LAG)) {
      new_row[[paste0("lag", lag_i)]] <- history[length(history) - lag_i + 1]
    }

    predictions[i] <- as.numeric(predict(model_info$fit, newdata = new_row))[1]
    history <- c(history, predictions[i])
  }

  predictions
}

calc_metrics <- function(actual, predicted) {
  error <- actual - predicted

  tibble(
    MSE = mean(error^2, na.rm = TRUE),
    RMSE = sqrt(mean(error^2, na.rm = TRUE)),
    MAE = mean(abs(error), na.rm = TRUE),
    MAPE = mean(abs(error / actual), na.rm = TRUE) * 100
  )
}

diagnose_training_residuals <- function(model_info) {
  residual_values <- na.omit(as.numeric(residuals(model_info$fit)))
  n <- length(residual_values)

  if (n < 4) {
    return(tibble(
      Ljung_Box_p_lag12 = NA_real_,
      ACF_Spikes = NA_integer_,
      PACF_Spikes = NA_integer_,
      Training_Residuals_White_Noise = "No"
    ))
  }

  lag_used <- min(LJUNG_LAG, n - 1)
  confidence_limit <- 1.96 / sqrt(n)

  acf_values <- as.numeric(acf(residual_values, plot = FALSE, lag.max = lag_used)$acf[-1])
  pacf_values <- as.numeric(pacf(residual_values, plot = FALSE, lag.max = lag_used)$acf)

  acf_spikes <- sum(abs(acf_values) > confidence_limit, na.rm = TRUE)
  pacf_spikes <- sum(abs(pacf_values) > confidence_limit, na.rm = TRUE)
  ljung_p <- Box.test(residual_values, lag = lag_used, type = "Ljung-Box")$p.value

  white_noise <- ljung_p > WHITE_NOISE_ALPHA && acf_spikes == 0 && pacf_spikes == 0

  tibble(
    Ljung_Box_p_lag12 = ljung_p,
    ACF_Spikes = acf_spikes,
    PACF_Spikes = pacf_spikes,
    Training_Residuals_White_Noise = if_else(white_noise, "Yes", "No")
  )
}

model_slug <- function(series_name, include_zodiac) {
  paste0(tolower(series_name), "_ml_", if_else(include_zodiac, "lag_zodiac", "lag_only"))
}

plot_actual_vs_predicted <- function(forecast_df, target_col, series_name, model_label, path) {
  plot_data <- forecast_df %>%
    select(year, actual, predicted) %>%
    pivot_longer(c(actual, predicted), names_to = "Type", values_to = "Value") %>%
    mutate(Type = recode(Type, actual = "Actual", predicted = "Predicted"))

  p <- ggplot(plot_data, aes(x = year, y = Value, colour = Type)) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2) +
    scale_colour_manual(values = c("Actual" = "#2B6CB0", "Predicted" = "#C53030")) +
    labs(
      title = paste(series_name, model_label, "Actual vs Predicted"),
      x = "Year",
      y = target_col,
      colour = NULL
    ) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())

  ggsave(path, p, width = 9, height = 5.6, dpi = 220)
}

plot_residual_correlation <- function(model_info, series_name, model_label, type, path) {
  residual_values <- na.omit(as.numeric(residuals(model_info$fit)))

  png(path, width = 900, height = 600)
  if (type == "acf") {
    acf(
      residual_values,
      lag.max = LJUNG_LAG,
      main = paste(series_name, model_label, "training residual ACF")
    )
  } else {
    pacf(
      residual_values,
      lag.max = LJUNG_LAG,
      main = paste(series_name, model_label, "training residual PACF")
    )
  }
  dev.off()
}

run_ml_model <- function(train_data, test_data, target_col, series_name, include_zodiac) {
  train_features <- create_lagged_data(train_data, target_col)
  model_info <- fit_lag_model(train_features, target_col, include_zodiac)
  predictions <- recursive_forecast(model_info, train_data, test_data, target_col)

  model_label <- if_else(include_zodiac, "Lag + Zodiac", "Lag only")
  slug <- model_slug(series_name, include_zodiac)

  forecast_df <- tibble(
    year = test_data$year,
    actual = test_data[[target_col]],
    predicted = predictions,
    error = actual - predicted,
    absolute_error = abs(error),
    percentage_error = error / actual * 100,
    absolute_percentage_error = abs(percentage_error),
    Zodiac = as.character(zodiac_year(test_data$year))
  )

  write_csv(forecast_df, paste0("outputs/forecasts/", slug, ".csv"))
  saveRDS(model_info$fit, paste0("outputs/models/", slug, ".rds"))

  actual_path <- paste0("outputs/plots/", slug, "_actual_vs_predicted.png")
  acf_path <- paste0("outputs/plots/", slug, "_residuals_acf.png")
  pacf_path <- paste0("outputs/plots/", slug, "_residuals_pacf.png")

  plot_actual_vs_predicted(forecast_df, target_col, series_name, model_label, actual_path)
  plot_residual_correlation(model_info, series_name, model_label, "acf", acf_path)
  plot_residual_correlation(model_info, series_name, model_label, "pacf", pacf_path)

  if (include_zodiac) {
    file.copy(
      actual_path,
      paste0("selected_figures/core/Figure_ML_", series_name, "_lag_zodiac_actual_vs_predicted.png"),
      overwrite = TRUE
    )
    file.copy(
      acf_path,
      paste0("selected_figures/core/Figure_ML_", series_name, "_lag_zodiac_residual_ACF.png"),
      overwrite = TRUE
    )
    file.copy(
      pacf_path,
      paste0("selected_figures/core/Figure_ML_", series_name, "_lag_zodiac_residual_PACF.png"),
      overwrite = TRUE
    )
  }

  selected_features <- model_info$selected_lags
  if (include_zodiac) {
    selected_features <- c(selected_features, "Zodiac")
  }

  bind_cols(
    tibble(
      Series = series_name,
      Model_Type = "ML",
      Model = if_else(
        include_zodiac,
        "Linear regression with backward lag elimination + Zodiac",
        "Linear regression with backward lag elimination"
      ),
      Scale = "original",
      Features = paste(selected_features, collapse = ", "),
      Removed_Lags = paste(model_info$removed_lags, collapse = ", "),
      AIC = NA_real_,
      AIC_Note = "N/A for ML models"
    ),
    calc_metrics(forecast_df$actual, forecast_df$predicted),
    diagnose_training_residuals(model_info)
  )
}

plot_zodiac_improvement <- function(ml_results) {
  metric_long <- ml_results %>%
    mutate(Model_Short = if_else(grepl("Zodiac", Model), "Lag + Zodiac", "Lag only")) %>%
    select(Series, Model_Short, MSE, RMSE, MAE, MAPE) %>%
    pivot_longer(c(MSE, RMSE, MAE, MAPE), names_to = "Metric", values_to = "Value")

  improvement <- metric_long %>%
    pivot_wider(names_from = Model_Short, values_from = Value) %>%
    mutate(
      Improvement = (`Lag only` - `Lag + Zodiac`) / `Lag only` * 100,
      Metric = factor(Metric, levels = c("MSE", "RMSE", "MAE", "MAPE"))
    )

  p <- ggplot(improvement, aes(x = Metric, y = Improvement, fill = Series)) +
    geom_col(position = position_dodge(width = 0.72), width = 0.62) +
    geom_text(
      aes(label = sprintf("%.1f%%", Improvement)),
      position = position_dodge(width = 0.72),
      vjust = -0.35,
      size = 3.5
    ) +
    geom_hline(yintercept = 0, colour = "grey40", linewidth = 0.4) +
    scale_fill_manual(values = c("TFR" = "#2B6CB0", "TLB" = "#C05621")) +
    labs(
      title = "Effect of Adding Chinese Zodiac to the ML Lag Model",
      subtitle = "Positive values mean Lag + Zodiac has lower forecast error than Lag-only",
      x = "Evaluation metric",
      y = "Error reduction (%)",
      fill = "Series"
    ) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())

  ggsave("outputs/plots/ml_summary/ml_zodiac_error_reduction.png", p, width = 9.5, height = 5.4, dpi = 220)
  ggsave("selected_figures/core/Figure_ML_zodiac_error_reduction.png", p, width = 9.5, height = 5.4, dpi = 220)
}

plot_selected_features <- function(ml_results) {
  feature_names <- c(paste0("lag", seq_len(MAX_LAG)), "Zodiac")

  feature_df <- ml_results %>%
    mutate(Model_Short = if_else(grepl("Zodiac", Model), "Lag + Zodiac", "Lag only")) %>%
    mutate(Row = paste(Series, Model_Short, sep = " - ")) %>%
    select(Row, Model_Short, Features) %>%
    crossing(Feature = feature_names) %>%
    rowwise() %>%
    mutate(
      Selected_List = list(trimws(strsplit(Features, ",")[[1]])),
      Status = case_when(
        Feature == "Zodiac" && Model_Short == "Lag only" ~ "Not candidate",
        Feature %in% Selected_List ~ "Kept",
        TRUE ~ "Removed"
      )
    ) %>%
    ungroup() %>%
    mutate(
      Feature = factor(Feature, levels = feature_names),
      Row = factor(Row, levels = rev(unique(Row))),
      Status = factor(Status, levels = c("Kept", "Removed", "Not candidate"))
    )

  p <- ggplot(feature_df, aes(x = Feature, y = Row, fill = Status)) +
    geom_tile(colour = "white", linewidth = 0.8) +
    scale_fill_manual(values = c(
      "Kept" = "#2F855A",
      "Removed" = "#E2E8F0",
      "Not candidate" = "#F7FAFC"
    )) +
    labs(
      title = "Selected ML Inputs After Backward Elimination",
      subtitle = "Started with lag1-lag12, then retained only useful predictors",
      x = "Candidate input feature",
      y = NULL,
      fill = "Final status"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      panel.grid = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )

  ggsave("outputs/plots/ml_summary/ml_backward_elimination_selected_features.png", p, width = 10, height = 4.8, dpi = 220)
  ggsave("selected_figures/core/Figure_ML_backward_elimination_selected_features.png", p, width = 10, height = 4.8, dpi = 220)
}

plot_residual_summary <- function(ml_results) {
  diag_df <- ml_results %>%
    mutate(
      Model_Short = if_else(grepl("Zodiac", Model), "Lag + Zodiac", "Lag only"),
      Residual_Status = if_else(Training_Residuals_White_Noise == "Yes", "White noise", "Not white noise"),
      Total_Spikes = ACF_Spikes + PACF_Spikes,
      Label = sprintf("p=%.3f\nACF/PACF spikes=%d", Ljung_Box_p_lag12, Total_Spikes)
    )

  p <- ggplot(diag_df, aes(x = Model_Short, y = Ljung_Box_p_lag12, fill = Residual_Status)) +
    geom_col(width = 0.58) +
    geom_hline(yintercept = WHITE_NOISE_ALPHA, linetype = "dashed", colour = "#4A5568") +
    geom_text(aes(label = Label), vjust = -0.35, size = 3.3) +
    facet_wrap(~ Series, nrow = 1) +
    scale_fill_manual(values = c("White noise" = "#2F855A", "Not white noise" = "#C53030")) +
    coord_cartesian(ylim = c(0, max(diag_df$Ljung_Box_p_lag12, na.rm = TRUE) + 0.18)) +
    labs(
      title = "ML Training Residual Diagnostics",
      subtitle = "A useful ML candidate should reduce forecast error and leave white-noise residuals",
      x = NULL,
      y = "Ljung-Box p-value at lag 12",
      fill = "Residual status"
    ) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank())

  ggsave("outputs/plots/ml_summary/ml_residual_diagnostics_summary.png", p, width = 9.5, height = 5, dpi = 220)
  ggsave("selected_figures/core/Figure_ML_residual_diagnostics_summary.png", p, width = 9.5, height = 5, dpi = 220)
}

plot_forecast_error_timeline <- function() {
  forecast_df <- bind_rows(
    read_csv("outputs/forecasts/tfr_ml_lag_zodiac.csv", show_col_types = FALSE) %>% mutate(Series = "TFR"),
    read_csv("outputs/forecasts/tlb_ml_lag_zodiac.csv", show_col_types = FALSE) %>% mutate(Series = "TLB")
  ) %>%
    mutate(Signed_Percentage_Error = (predicted - actual) / actual * 100)

  p <- ggplot(forecast_df, aes(x = year, y = Signed_Percentage_Error, colour = Series)) +
    geom_hline(yintercept = 0, colour = "grey35", linewidth = 0.45) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2.5) +
    geom_text(aes(label = Zodiac), size = 2.7, vjust = -0.8, check_overlap = TRUE, show.legend = FALSE) +
    facet_wrap(~ Series, nrow = 1) +
    scale_x_continuous(breaks = seq(2013, 2025, 2), limits = c(2012.7, 2025.3)) +
    scale_colour_manual(values = c("TFR" = "#2B6CB0", "TLB" = "#C05621")) +
    labs(
      title = "Where the Lag + Zodiac ML Forecast Over- or Under-Predicts",
      subtitle = "Positive values mean the model predicted too high; labels show the test-year Zodiac",
      x = "Test year",
      y = "Signed percentage forecast error (%)",
      colour = "Series"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      panel.spacing.x = grid::unit(1.4, "lines")
    )

  ggsave("outputs/plots/ml_summary/ml_forecast_percentage_error_timeline.png", p, width = 11, height = 5.4, dpi = 220)
  ggsave("selected_figures/core/Figure_ML_forecast_percentage_error_timeline.png", p, width = 11, height = 5.4, dpi = 220)
}

tfr_train <- read_series("data/clean_data/tfr_train.csv", "TFR")
tfr_test <- read_series("data/clean_data/tfr_test.csv", "TFR")
tlb_train <- read_series("data/clean_data/tlb_train.csv", "TLB")
tlb_test <- read_series("data/clean_data/tlb_test.csv", "TLB")

ml_results <- bind_rows(
  run_ml_model(tfr_train, tfr_test, "TFR", "TFR", include_zodiac = TRUE),
  run_ml_model(tfr_train, tfr_test, "TFR", "TFR", include_zodiac = FALSE),
  run_ml_model(tlb_train, tlb_test, "TLB", "TLB", include_zodiac = TRUE),
  run_ml_model(tlb_train, tlb_test, "TLB", "TLB", include_zodiac = FALSE)
) %>%
  arrange(Series, desc(grepl("Zodiac", Model))) %>%
  mutate(
    across(c(MSE, RMSE, MAE, MAPE, Ljung_Box_p_lag12), ~ round(.x, 6))
  )

write_csv(ml_results, "outputs/model_comparison_ml.csv")
write_csv(
  ml_results %>% filter(grepl("Zodiac", Model)),
  "outputs/model_comparison_ml_lag_zodiac.csv"
)

plot_zodiac_improvement(ml_results)
plot_selected_features(ml_results)
plot_residual_summary(ml_results)
plot_forecast_error_timeline()

cat("\nMachine learning comparison complete.\n")
cat("Client feedback implemented: lag1-lag12, no direct year input, backward elimination, Zodiac comparison, residual checks.\n\n")
print(ml_results)

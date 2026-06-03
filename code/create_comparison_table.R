# Create model comparison tables from saved model and forecast outputs.

library(tidyverse)
library(Metrics)

tfr_test <- read_csv("data/clean_data/tfr_test.csv", show_col_types = FALSE) %>%
  select(year, TFR)
tlb_test <- read_csv("data/clean_data/tlb_test.csv", show_col_types = FALSE) %>%
  select(year, TLB)

calc_metrics <- function(actual, predicted) {
  tibble(
    RMSE = rmse(actual, predicted),
    MAE = mae(actual, predicted),
    MAPE = mape(actual, predicted) * 100
  )
}

read_predictions <- function(path, preferred_col = NULL) {
  pred_df <- read_csv(path, show_col_types = FALSE, name_repair = "unique_quiet")

  if (!is.null(preferred_col) && preferred_col %in% names(pred_df)) {
    return(pred_df[[preferred_col]])
  }

  if ("predicted" %in% names(pred_df)) {
    return(pred_df$predicted)
  }

  forecast_col <- names(pred_df)[str_detect(names(pred_df), "Point") & str_detect(names(pred_df), "Forecast")]
  if (length(forecast_col) == 1) {
    return(pred_df[[forecast_col]])
  }

  stop("Could not find prediction column in ", path)
}

model_aic <- function(fit) {
  if (!is.null(fit$aic)) {
    return(as.numeric(fit$aic))
  }

  as.numeric(AIC(fit))
}

arima_label <- function(fit, prefix = "ARIMA") {
  if (is.null(fit$arma)) {
    return(prefix)
  }

  p <- fit$arma[1]
  d <- fit$arma[6]
  q <- fit$arma[2]
  paste0(prefix, "(", p, ",", d, ",", q, ")")
}

diagnose_residuals <- function(fit, strict_lag = 20) {
  residual_values <- na.omit(as.numeric(residuals(fit)))
  n <- length(residual_values)

  if (n < 3) {
    return(tibble(
      AIC = model_aic(fit),
      Ljung_Box_p_lag10 = NA_real_,
      Ljung_Box_p_lag20 = NA_real_,
      ACF_Spikes = NA_integer_,
      PACF_Spikes = NA_integer_,
      ACF_PACF_OK = "N/A",
      Diagnostic_Status = "Too few residuals",
      Viable = "No"
    ))
  }

  lag10 <- min(10, n - 1)
  lag20 <- min(strict_lag, n - 1)
  confidence_limit <- 1.96 / sqrt(n)

  acf_values <- as.numeric(acf(residual_values, plot = FALSE, lag.max = lag20)$acf[-1])
  pacf_values <- as.numeric(pacf(residual_values, plot = FALSE, lag.max = lag20)$acf)

  acf_spikes <- sum(abs(acf_values) > confidence_limit, na.rm = TRUE)
  pacf_spikes <- sum(abs(pacf_values) > confidence_limit, na.rm = TRUE)
  lb10 <- Box.test(residual_values, lag = lag10, type = "Ljung-Box")$p.value
  lb20 <- Box.test(residual_values, lag = lag20, type = "Ljung-Box")$p.value

  strict_pass <- lb10 > 0.05 && lb20 > 0.05 && acf_spikes == 0 && pacf_spikes == 0

  tibble(
    AIC = model_aic(fit),
    Ljung_Box_p_lag10 = lb10,
    Ljung_Box_p_lag20 = lb20,
    ACF_Spikes = acf_spikes,
    PACF_Spikes = pacf_spikes,
    ACF_PACF_OK = if_else(acf_spikes == 0 && pacf_spikes == 0, "Yes", "No"),
    Diagnostic_Status = if_else(
      strict_pass,
      "Passes strict white-noise check",
      "Mixed / fails strict white-noise check"
    ),
    Viable = if_else(strict_pass, "Yes", "No")
  )
}

make_ts_row <- function(series, model_type, model_label, scale, features, forecast_path, model_path, actual, aic_note) {
  fit <- readRDS(model_path)
  predicted <- read_predictions(forecast_path)

  bind_cols(
    tibble(
      Series = series,
      Model_Type = model_type,
      Model = model_label,
      Scale = scale,
      Features = features
    ),
    diagnose_residuals(fit),
    calc_metrics(actual, predicted),
    tibble(AIC_Note = aic_note)
  )
}

make_ml_rows <- function(path = "outputs/model_comparison_ml.csv") {
  if (!file.exists(path)) {
    return(tibble())
  }

  read_csv(path, show_col_types = FALSE) %>%
    mutate(
      AIC = NA_real_,
      Ljung_Box_p_lag10 = NA_real_,
      Ljung_Box_p_lag20 = NA_real_,
      ACF_PACF_OK = if_else(ACF_Spikes == 0 & PACF_Spikes == 0, "Yes", "No"),
      Diagnostic_Status = if_else(
        Training_Residuals_White_Noise == "Yes",
        "Passes ML training residual white-noise check",
        "Fails ML training residual white-noise check"
      ),
      Viable = "Comparison only",
      AIC_Note = "N/A for ML models"
    ) %>%
    select(
      Series,
      Model_Type,
      Model,
      Scale,
      Features,
      Removed_Lags,
      AIC,
      Ljung_Box_p_lag10,
      Ljung_Box_p_lag20,
      Ljung_Box_p_lag12,
      ACF_Spikes,
      PACF_Spikes,
      ACF_PACF_OK,
      Diagnostic_Status,
      Viable,
      MSE,
      RMSE,
      MAE,
      MAPE,
      AIC_Note
    )
}

tfr_selected_fit <- readRDS("outputs/models/tfr_arima-1-1-1.rds")
tlb_selected_fit <- readRDS("outputs/models/tlb_arima-1-1-1.rds")
tfr_auto_fit <- readRDS("outputs/models/tfr_arima.rds")
tlb_auto_fit <- readRDS("outputs/models/tlb_arima.rds")
tfr_log_fit <- readRDS("outputs/models/tfr_log_arima-1-1-1.rds")
tlb_log_fit <- readRDS("outputs/models/tlb_log_arima-1-1-1.rds")
tfr_ets_fit <- readRDS("outputs/models/tfr_ets.rds")
tlb_ets_fit <- readRDS("outputs/models/tlb_ets.rds")

comparison_table <- bind_rows(
  make_ts_row("TFR", "ARIMA", arima_label(tfr_auto_fit), "original", "-", "outputs/forecasts/tfr_arima.csv", "outputs/models/tfr_arima.rds", tfr_test$TFR, "Comparable only with original-scale time-series models"),
  make_ts_row("TFR", "ARIMA", arima_label(tfr_selected_fit), "original", "-", "outputs/forecasts/tfr_arima-1-1-1.csv", "outputs/models/tfr_arima-1-1-1.rds", tfr_test$TFR, "Comparable only with original-scale time-series models"),
  make_ts_row("TFR", "ARIMA", arima_label(tfr_log_fit, "log-ARIMA"), "log", "-", "outputs/forecasts/tfr_log_arima-1-1-1.csv", "outputs/models/tfr_log_arima-1-1-1.rds", tfr_test$TFR, "Log-scale AIC; do not compare directly with original-scale AIC"),
  make_ts_row("TFR", "ETS", tfr_ets_fit$method, "original", "-", "outputs/forecasts/tfr_ets.csv", "outputs/models/tfr_ets.rds", tfr_test$TFR, "Comparable only with original-scale time-series models"),
  make_ts_row("TLB", "ARIMA", arima_label(tlb_auto_fit), "original", "-", "outputs/forecasts/tlb_arima.csv", "outputs/models/tlb_arima.rds", tlb_test$TLB, "Comparable only with original-scale time-series models"),
  make_ts_row("TLB", "ARIMA", arima_label(tlb_selected_fit), "original", "-", "outputs/forecasts/tlb_arima-1-1-1.csv", "outputs/models/tlb_arima-1-1-1.rds", tlb_test$TLB, "Comparable only with original-scale time-series models"),
  make_ts_row("TLB", "ARIMA", arima_label(tlb_log_fit, "log-ARIMA"), "log", "-", "outputs/forecasts/tlb_log_arima-1-1-1.csv", "outputs/models/tlb_log_arima-1-1-1.rds", tlb_test$TLB, "Log-scale AIC; do not compare directly with original-scale AIC"),
  make_ts_row("TLB", "ETS", tlb_ets_fit$method, "original", "-", "outputs/forecasts/tlb_ets.csv", "outputs/models/tlb_ets.rds", tlb_test$TLB, "Comparable only with original-scale time-series models"),
  make_ml_rows()
) %>%
  arrange(Series, RMSE) %>%
  mutate(
    across(
      any_of(c("AIC", "Ljung_Box_p_lag10", "Ljung_Box_p_lag20", "Ljung_Box_p_lag12", "MSE", "RMSE", "MAE", "MAPE")),
      ~ round(.x, 4)
    )
  )

write_csv(comparison_table, "outputs/model_comparison_full.csv")
write_csv(filter(comparison_table, Series == "TFR"), "outputs/model_comparison_tfr.csv")
write_csv(filter(comparison_table, Series == "TLB"), "outputs/model_comparison_tlb.csv")

print(comparison_table)

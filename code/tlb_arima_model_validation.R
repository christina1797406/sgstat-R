# TLB MODEL VALIDATION

library(forecast)

# LOAD CLEAN DATA

train <- read.csv("clean_data/train.csv")
test <- read.csv("clean_data/test.csv")

TLBa <- ts(train$TLB, start = 1960, frequency = 1)

dir.create("outputs/model_validation/tlb", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/forecasts/tlb", recursive = TRUE, showWarnings = FALSE)

# LOAD VALID MODELS TABLE

valid_models <- read.csv("processed_data/tlb_arima_valid_models.csv")

# SELECT TOP MODELS

top_models <- head(valid_models, 5)

print(top_models)

# VALIDATION FUNCTION

validate_tlb_model <- function(model_row) {
  
  model_name <- model_row$model_name
  p <- model_row$p
  d <- model_row$d
  q <- model_row$q
  
  model_path <- paste0("outputs/models/raw/", model_name, ".rds")
  model <- readRDS(model_path)
  
  pred <- predict(model, n.ahead = nrow(test))
  
  forecast <- data.frame(
    year = test$year,
    actual = test$TLB,
    predicted = as.numeric(pred$pred)
  )
  
  rmse <- sqrt(mean((forecast$actual - forecast$predicted)^2))
  mae <- mean(abs(forecast$actual - forecast$predicted))
  
  lb <- Box.test(
    model$residuals,
    lag = 20,
    type = "Ljung-Box",
    fitdf = p + q
  )
  
  # SAVE RESIDUAL ACF
  
  png(
    paste0("outputs/model_validation/tlb/", model_name, "_residuals_acf.png"),
    res = 300,
    width = 2000,
    height = 1400
  )
  
  acf(
    model$residuals,
    lag.max = 40,
    main = paste0("ACF of Residuals for TLB ARIMA(", p, ",", d, ",", q, ")")
  )
  
  dev.off()
  
  # SAVE RESIDUAL PACF
  
  png(
    paste0("outputs/model_validation/tlb/", model_name, "_residuals_pacf.png"),
    res = 300,
    width = 2000,
    height = 1400
  )
  
  pacf(
    model$residuals,
    lag.max = 40,
    main = paste0("PACF of Residuals for TLB ARIMA(", p, ",", d, ",", q, ")")
  )
  
  dev.off()
  
  # SAVE FORECAST PLOT
  
  png(
    paste0("outputs/model_validation/tlb/", model_name, "_forecast.png"),
    res = 300,
    width = 2000,
    height = 1400
  )
  
  plot(
    forecast$year,
    forecast$actual,
    type = "l",
    col = "blue",
    lwd = 2,
    ylim = range(c(forecast$actual, forecast$predicted)),
    xlab = "Year",
    ylab = "Total Live Births",
    main = paste0("Actual vs Forecasted TLB for ARIMA(", p, ",", d, ",", q, ")"),
    sub = paste("RMSE =", round(rmse, 2), "| MAE =", round(mae, 2))
  )
  
  lines(
    forecast$year,
    forecast$predicted,
    col = "red",
    lwd = 2
  )
  
  legend(
    "bottomleft",
    legend = c("Actual", "Forecast"),
    col = c("blue", "red"),
    lty = 1,
    lwd = 2
  )
  
  dev.off()
  
  # SAVE FORECAST TABLE
  
  write.csv(
    forecast,
    paste0("outputs/forecasts/tlb/", model_name, "_forecast.csv"),
    row.names = FALSE
  )
  
  return(
    data.frame(
      model_name = model_name,
      model = paste0("ARIMA(", p, ",", d, ",", q, ")"),
      AIC = AIC(model),
      LjungBox_p = lb$p.value,
      RMSE = rmse,
      MAE = mae
    )
  )
}

# RUN VALIDATION

validation_results <- data.frame()

for (i in 1:nrow(top_models)) {
  
  validation_results <- rbind(
    validation_results,
    validate_tlb_model(top_models[i, ])
  )
}

# SORT VALIDATION RESULTS

validation_results <- validation_results[order(validation_results$RMSE, validation_results$AIC), ]

print(validation_results)

write.csv(
  validation_results,
  "processed_data/tlb_arima_validation_results.csv",
  row.names = FALSE
)

cat("\nTLB ARIMA model validation complete.\n")
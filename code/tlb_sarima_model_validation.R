# TLB CORRECTED SARIMA MODEL VALIDATION

library(forecast)

train <- read.csv("clean_data/train.csv")
test <- read.csv("clean_data/test.csv")

TLBa <- ts(train$TLB, start = min(train$year), frequency = 1)

dir.create("outputs/model_validation/tlb_sarima", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/forecasts/tlb_sarima", recursive = TRUE, showWarnings = FALSE)

valid_models <- read.csv("processed_data/tlb_sarima_valid_models.csv")

top_models <- head(valid_models, 5)

print(top_models)

validate_sarima_model <- function(model_row) {
  
  model_name <- model_row$model_name
  model_label <- model_row$model
  parameter_count <- model_row$parameter_count
  
  model_path <- paste0("outputs/models/sarima/", model_name, ".rds")
  model <- readRDS(model_path)
  
  forecast_result <- forecast(model, h = nrow(test))
  
  forecast_table <- data.frame(
    year = test$year,
    actual = test$TLB,
    predicted = as.numeric(forecast_result$mean)
  )
  
  rmse <- sqrt(mean((forecast_table$actual - forecast_table$predicted)^2, na.rm = TRUE))
  mae <- mean(abs(forecast_table$actual - forecast_table$predicted), na.rm = TRUE)
  
  lb <- Box.test(
    residuals(model),
    lag = 20,
    type = "Ljung-Box",
    fitdf = parameter_count
  )
  
  png(
    paste0("outputs/model_validation/tlb_sarima/", model_name, "_forecast.png"),
    res = 300,
    width = 2000,
    height = 1400
  )
  
  plot(
    forecast_table$year,
    forecast_table$actual,
    type = "l",
    col = "blue",
    lwd = 2,
    ylim = range(c(forecast_table$actual, forecast_table$predicted)),
    xlab = "Year",
    ylab = "Total Live Births",
    main = paste0("Actual vs Forecasted TLB for ", model_label),
    sub = paste("RMSE =", round(rmse, 2), "| MAE =", round(mae, 2))
  )
  
  lines(
    forecast_table$year,
    forecast_table$predicted,
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
  
  png(
    paste0("outputs/model_validation/tlb_sarima/", model_name, "_residuals_acf.png"),
    res = 300,
    width = 2000,
    height = 1400
  )
  acf(residuals(model), lag.max = 40, main = paste0("Residual ACF for ", model_label))
  dev.off()
  
  png(
    paste0("outputs/model_validation/tlb_sarima/", model_name, "_residuals_pacf.png"),
    res = 300,
    width = 2000,
    height = 1400
  )
  pacf(residuals(model), lag.max = 40, main = paste0("Residual PACF for ", model_label))
  dev.off()
  
  write.csv(
    forecast_table,
    paste0("outputs/forecasts/tlb_sarima/", model_name, "_forecast.csv"),
    row.names = FALSE
  )
  
  return(
    data.frame(
      model_name = model_name,
      model = model_label,
      AIC = AIC(model),
      LjungBox_p = lb$p.value,
      RMSE = rmse,
      MAE = mae
    )
  )
}

validation_results <- data.frame()

for (i in 1:nrow(top_models)) {
  validation_results <- rbind(
    validation_results,
    validate_sarima_model(top_models[i, ])
  )
}

validation_results <- validation_results[order(validation_results$RMSE, validation_results$AIC), ]

print(validation_results)

write.csv(
  validation_results,
  "processed_data/tlb_sarima_validation_results.csv",
  row.names = FALSE
)

cat("\nCorrected TLB SARIMA validation complete.\n")
library(forecast)

train <- read.csv("clean_data/train.csv")
test <- read.csv("clean_data/test.csv")

TLBa <- ts(train$TLB, start = min(train$year), frequency = 1)

dir.create("outputs/model_validation/tlb_sarima_selected", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/forecasts/tlb_sarima_selected", recursive = TRUE, showWarnings = FALSE)

selected_models <- data.frame(
  model = c(
    "SARIMA(3,1,0)(0,1,1)[12]",
    "SARIMA(0,1,0)(0,1,1)[12]",
    "SARIMA(0,1,0)(1,1,1)[12]"
  ),
  p = c(3, 0, 0),
  d = c(1, 1, 1),
  q = c(0, 0, 0),
  P = c(0, 0, 1),
  D = c(1, 1, 1),
  Q = c(1, 1, 1)
)

plot_selected_sarima <- function(model_row) {
  
  p <- model_row$p
  d <- model_row$d
  q <- model_row$q
  P <- model_row$P
  D <- model_row$D
  Q <- model_row$Q
  
  model_label <- model_row$model
  safe_name <- gsub("[(),\\[\\]]", "_", model_label)
  safe_name <- gsub("_+", "_", safe_name)
  
  fitted_model <- Arima(
    TLBa,
    order = c(p, d, q),
    seasonal = list(order = c(P, D, Q), period = 12),
    include.constant = FALSE
  )
  
  fc <- forecast(fitted_model, h = nrow(test))
  
  forecast_table <- data.frame(
    year = test$year,
    actual = test$TLB,
    predicted = as.numeric(fc$mean)
  )
  
  rmse <- sqrt(mean((forecast_table$actual - forecast_table$predicted)^2, na.rm = TRUE))
  mae <- mean(abs(forecast_table$actual - forecast_table$predicted), na.rm = TRUE)
  
  lb <- Box.test(
    residuals(fitted_model),
    lag = 20,
    type = "Ljung-Box",
    fitdf = p + q + P + Q
  )
  
  png(
    paste0("outputs/model_validation/tlb_sarima_selected/", safe_name, "_forecast.png"),
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
    sub = paste(
      "RMSE =", round(rmse, 2),
      "| MAE =", round(mae, 2),
      "| Ljung-Box p =", round(lb$p.value, 3)
    )
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
    paste0("outputs/model_validation/tlb_sarima_selected/", safe_name, "_residuals_acf.png"),
    res = 300,
    width = 2000,
    height = 1400
  )
  acf(
    residuals(fitted_model),
    lag.max = 40,
    main = paste0("Residual ACF for ", model_label)
  )
  dev.off()
  
  png(
    paste0("outputs/model_validation/tlb_sarima_selected/", safe_name, "_residuals_pacf.png"),
    res = 300,
    width = 2000,
    height = 1400
  )
  pacf(
    residuals(fitted_model),
    lag.max = 40,
    main = paste0("Residual PACF for ", model_label)
  )
  dev.off()
  
  write.csv(
    forecast_table,
    paste0("outputs/forecasts/tlb_sarima_selected/", safe_name, "_forecast.csv"),
    row.names = FALSE
  )
  
  return(
    data.frame(
      model = model_label,
      AIC = AIC(fitted_model),
      LjungBox_p = lb$p.value,
      RMSE = rmse,
      MAE = mae
    )
  )
}

results <- data.frame()

for (i in 1:nrow(selected_models)) {
  results <- rbind(results, plot_selected_sarima(selected_models[i, ]))
}

print(results)

write.csv(
  results,
  "processed_data/tlb_selected_sarima_plot_summary.csv",
  row.names = FALSE
)
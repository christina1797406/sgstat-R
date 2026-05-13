# =========================================================
# MODEL VALIDATION ARIMA(15,2,0) FOR TFR
# =========================================================

# =========================================================
# 1. LOAD MODELS
# =========================================================

best_model  <- arima(TFRa, order = c(15,2,0))

# Include the next best three models (by AIC)
tfr_m8  <- arima(TFRa, order = c(12,2,3))
tfr_m15  <- arima(TFRa, order = c(15,2,1))
tfr_m11  <- arima(TFRa, order = c(15,1,1))

# =========================================================
# 2. FORECASTING ACCURACY
# =========================================================

pred <- predict(best_model, n.ahead = 13)

forecast <- data.frame(
  year = test$year,
  actual = test$TFR,
  predicted = as.numeric(pred$pred)
)

# View forecast results
forecast

# Calculate Root Mean Squared Error
rmse <- sqrt(mean((forecast$actual - forecast$predicted)^2))

# =========================================================
# 3. PLOT ACTUAL AND FORECASTED RESULTS
# =========================================================

dir.create("outputs/model_validation", recursive = TRUE, showWarnings = FALSE)

png(
  "outputs/model_validation/tfr_m7_forecast.png", res = 300, width = 2000, height = 1400)

plot(
  test$year,
  test$TFR,
  type = "l",
  col = "blue",
  lwd = 2,
  ylim = range(c(test$TFR, forecast$predicted)),
  xlab = "Year",
  ylab = "TFR",
  main = "Actual vs Forecasted TFR for ARIMA(15,2,0)",
  sub = paste("RMSE =", round(rmse, 4))
)

lines(
  test$year,
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
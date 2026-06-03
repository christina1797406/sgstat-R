# =========================================================
# COMPARE BEST AIC MODEL VS BEST RMSE MODEL
# =========================================================

dir.create("outputs/model_comparison",
           recursive = TRUE,
           showWarnings = FALSE)

# Forecasts
pred_m7 <- predict(tfr_m7, n.ahead = nrow(test))
pred_m8 <- predict(tfr_m8, n.ahead = nrow(test))

# Save comparison plot
png(
  "outputs/model_comparison/tfr_best_models_comparison.png",
  width = 2200,
  height = 1600,
  res = 300
)

plot(
  test$year,
  test$TFR,
  type = "l",
  lwd = 3,
  col = "black",
  ylim = range(
    c(
      test$TFR,
      pred_m7$pred,
      pred_m8$pred
    )
  ),
  xlab = "Year",
  ylab = "Total Fertility Rate (TFR)",
  main = "Comparison of Best AIC and Best RMSE ARIMA Models",
  sub = "Lowest AIC: ARIMA(15,2,0) | Lowest RMSE: ARIMA(12,2,3)"
)

# Lowest AIC model
lines(
  test$year,
  pred_m7$pred,
  col = "red",
  lwd = 2
)

# Lowest RMSE model
lines(
  test$year,
  pred_m8$pred,
  col = "blue",
  lwd = 2
)

legend(
  "bottomleft",
  legend = c(
    "Actual",
    "ARIMA(15,2,0)  (AIC = -63.54, RMSE = 0.1745)",
    "ARIMA(12,2,3)  (AIC = -62.57, RMSE = 0.1213)"
  ),
  col = c("black", "red", "blue"),
  lwd = c(3,2,2),
  lty = 1
)

dev.off()

cat("\nComparison plot saved to:\n")
cat("outputs/model_comparison/tfr_best_models_comparison.png\n")
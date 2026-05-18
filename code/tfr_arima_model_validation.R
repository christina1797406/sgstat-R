# =========================================================
# TFR MODEL VALIDATION FOR ARIMA MODELS WITH LOWEST AIC
# =========================================================

dir.create("outputs/model_validation", recursive = TRUE, showWarnings = FALSE)

validate_arima <- function(model, model_name, train_ts, test_df) {
  
  # Forecast
  pred <- predict(model, n.ahead = nrow(test_df))
  
  forecast <- data.frame(
    year = test_df$year,
    actual = test_df$TFR,
    predicted = as.numeric(pred$pred)
  )
  
  # RMSE
  rmse <- sqrt(mean((forecast$actual - forecast$predicted)^2))
  
  cat("\n============================\n")
  cat("Model:", model_name, "\n")
  cat("RMSE:", rmse, "\n")
  cat("============================\n")
  
  p <- model$arma[1]
  d <- model$arma[6]
  q <- model$arma[2]
  main_title <- paste0("Actual vs Forecasted TFR for ARIMA(", p, ",", d, ",", q, ")")
  
  # Save plot
  png(
    paste0("outputs/model_validation/", model_name, "_forecast.png"),
    width = 2000,
    height = 1400,
    res = 300
  )
  
  plot(
    test_df$year,
    test_df$TFR,
    type = "l",
    col = "blue",
    lwd = 2,
    ylim = range(c(test_df$TFR, forecast$predicted)),
    xlab = "Year",
    ylab = "TFR",
    main = main_title,
    sub = paste("RMSE =", round(rmse, 4))
  )
  
  lines(test_df$year, forecast$predicted,
        col = "red", lwd = 2)
  
  legend(
    "bottomleft",
    legend = c("Actual", "Forecast"),
    col = c("blue", "red"),
    lty = 1,
    lwd = 2
  )
  
  dev.off()
  
  return(rmse)
}

# Load the best model (tfr_m7) and the next best three models (by AIC)
rmse_m7 <- validate_arima(tfr_m7, "tfr_m7", TFRa, test)
rmse_m8 <- validate_arima(tfr_m8, "tfr_m8", TFRa, test)
rmse_m15 <- validate_arima(tfr_m15, "tfr_m15", TFRa, test)
rmse_m11 <- validate_arima(tfr_m11, "tfr_m11", TFRa, test)

rmse_results <- data.frame(
  model = c("ARIMA(15,2,0)", "ARIMA(12,2,3)", "ARIMA(15,2,1)", "ARIMA(15,1,1)"),
  name = c("tfr_m7", "tfr_m8", "tfr_m15", "tfr_m11"),
  rmse = c(rmse_m7, rmse_m8, rmse_m15, rmse_m11)
)

sorted_rmse <- rmse_results[order(rmse_results$rmse), ]
print(sorted_rmse)


# Save TFR ARIMA models
dir.create("outputs/models/raw", recursive = TRUE, showWarnings = FALSE)

saveRDS(tfr_m7, "outputs/models/raw/tfr_m7_ARIMA_15_2_0.rds")
saveRDS(tfr_m8, "outputs/models/raw/tfr_m8_ARIMA_12_2_3.rds")
saveRDS(tfr_m15, "outputs/models/raw/tfr_m15_ARIMA_15_2_1.rds")
saveRDS(tfr_m11, "outputs/models/raw/tfr_m11_ARIMA_15_1_1.rds")

cat("\nARIMA models saved to outputs/models/raw\n")
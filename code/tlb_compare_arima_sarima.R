# COMPARE NON-SEASONAL ARIMA AND CORRECTED SARIMA MODELS FOR TLB

arima_results <- read.csv("processed_data/tlb_arima_validation_results.csv")
sarima_results <- read.csv("processed_data/tlb_sarima_validation_results.csv")

arima_results$type <- "Non-seasonal ARIMA"
sarima_results$type <- "SARIMA"

combined_results <- rbind(
  arima_results[, c("type", "model_name", "model", "AIC", "LjungBox_p", "RMSE", "MAE")],
  sarima_results[, c("type", "model_name", "model", "AIC", "LjungBox_p", "RMSE", "MAE")]
)

combined_results <- combined_results[order(combined_results$RMSE, combined_results$AIC), ]

print(combined_results)

write.csv(
  combined_results,
  "processed_data/tlb_arima_sarima_corrected_comparison.csv",
  row.names = FALSE
)
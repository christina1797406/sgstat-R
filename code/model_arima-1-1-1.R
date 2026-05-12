# Time series model 1 - ARIMA 1, 1, 1 Revised

library(forecast)
library(tseries)

# Load data
tfr_train <- read.csv("data/clean_data/tfr_train.csv")
tfr_test  <- read.csv("data/clean_data/tfr_test.csv")

tlb_train <- read.csv("data/clean_data/tlb_train.csv")
tlb_test  <- read.csv("data/clean_data/tlb_test.csv")

# Convert to time series
tfr_ts <- ts(tfr_train$TFR, start=min(tfr_train$year), frequency=1)
tlb_ts <- ts(tlb_train$TLB, start=min(tlb_train$year), frequency=1)

# Model selection TFR ----------
fit1 <- Arima(tfr_ts, order=c(1,1,1))
fit2 <- Arima(tfr_ts, order=c(2,1,1))
fit3 <- Arima(tfr_ts, order=c(1,1,2))

# Compare models
aic_tfr_results <- data.frame(
  model = c("ARIMA(1,1,1)", "ARIMA(2,1,1)", "ARIMA(1,1,2)"),
  AIC = c(AIC(fit1), AIC(fit2), AIC(fit3))
)
print(aic_tfr_results)

# Choose best model based on AIC
best_tfr <- which.min(aic_tfr_results$AIC)
tfr_arima <- list(fit1, fit2, fit3)[[best_tfr]]

# Residual diagnostics acf and pacf
png("outputs/plots/tfr_residuals_acf.png")
acf(tfr_arima$residuals, lag=40)
dev.off()

png("outputs/plots/tfr_residuals_pacf.png")
pacf(tfr_arima$residuals, lag=40)
dev.off()

png("outputs/plots/tfr_residuals_tsdisplay.png")
tsdisplay(tfr_arima$residuals, lag=40)
dev.off()

# Ljung-Box test
lb_test <- Box.test(tfr_arima$residuals, lag=40, type="Ljung-Box")
print(lb_test)

# Save forecasts
tfr_forecast <- forecast(tfr_arima, h=nrow(tfr_test))
png("outputs/plots/tfr_forecast.png")
plot(tfr_forecast)
dev.off()


# Repeat model selection TLB ----------
tlb_fit1 <- Arima(tlb_ts, order=c(1,1,1))
tlb_fit2 <- Arima(tlb_ts, order=c(2,1,1))
tlb_fit3 <- Arima(tlb_ts, order=c(1,1,2))

aic_tlb_results <- data.frame(
  model = c("ARIMA(1,1,1)", "ARIMA(2,1,1)", "ARIMA(1,1,2)"),
  AIC = c(AIC(tlb_fit1), AIC(tlb_fit2), AIC(tlb_fit3))
)
print(aic_tlb_results)

# Choose best model based on AIC
tlb_arima <- list(tlb_fit1, tlb_fit2, tlb_fit3)[[which.min(aic_tlb_results$AIC)]]

png("outputs/plots/tlb_residuals_acf.png")
acf(tlb_arima$residuals)
dev.off()

png("outputs/plots/tlb_residuals_pacf.png")
pacf(tlb_arima$residuals)
dev.off()

png("outputs/plots/tlb_residuals_tsdisplay.png")
tsdisplay(tlb_arima$residuals)
dev.off()

# Ljung-Box test
tlb_lb <- Box.test(tlb_arima$residuals, lag=10, type="Ljung-Box")
print(tlb_lb)

# Save forecast
tlb_forecast <- forecast(tlb_arima, h=nrow(tlb_test))
png("outputs/plots/tlb_forecast.png")
plot(tlb_forecast)
dev.off()


# Save outputs
write.csv(data.frame(tfr_forecast), "outputs/forecasts/tfr_arima-1-1-1.csv")
write.csv(data.frame(tlb_forecast), "outputs/forecasts/tlb_arima-1-1-1.csv")

saveRDS(tfr_arima, "outputs/models/tfr_arima-1-1-1.rds")
saveRDS(tlb_arima, "outputs/models/tlb_arima-1-1-1.rds")

write.csv(aic_tfr_results, "outputs/model_comparison_tfr.csv", row.names = FALSE)
write.csv(aic_tlb_results, "outputs/model_comparison_tlb.csv", row.names = FALSE)

cat("Improved ARIMA models complete.\n")
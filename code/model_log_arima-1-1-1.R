# Time series model 3 - Log-ARIMA 1, 1, 1 (TFR and TLB)

library(forecast)
library(tseries)
library(tidyverse)

# Load data
tfr_train <- read_csv("data/clean_data/tfr_train.csv") %>% pull(TFR)
tfr_test  <- read_csv("data/clean_data/tfr_test.csv") %>% pull(TFR)
tlb_train <- read_csv("data/clean_data/tlb_train.csv") %>% pull(TLB)
tlb_test  <- read_csv("data/clean_data/tlb_test.csv") %>% pull(TLB)

# ============ TFR Log-ARIMA ============
tfr_ts <- ts(tfr_train)
tfr_log_ts <- log(tfr_ts)

fit_tfr_log <- Arima(tfr_log_ts, order=c(1,1,1))
tfr_log_forecast <- forecast(fit_tfr_log, h=length(tfr_test))
tfr_log_pred <- exp(tfr_log_forecast$mean)  # Back-transform

# Check residuals for TFR
tfr_log_ljung <- Box.test(residuals(fit_tfr_log), lag=10, type='Ljung-Box')$p.value

# Diagnostics plots
png("outputs/plots/tfr_log_residuals_acf.png")
acf(fit_tfr_log$residuals, main="TFR log-ARIMA ACF")
dev.off()

png("outputs/plots/tfr_log_residuals_pacf.png")
pacf(fit_tfr_log$residuals, main="TFR log-ARIMA PACF")
dev.off()

png("outputs/plots/tfr_log_residuals_tsdisplay.png")
tsdisplay(fit_tfr_log$residuals, main="TFR log-ARIMA Residuals")
dev.off()

# Forecast plot
png("outputs/plots/tfr_log_forecast.png")
plot(forecast(fit_tfr_log, h=length(tfr_test)), main="TFR log-ARIMA Forecast")
dev.off()

# Save outputs
write.csv(data.frame(year=1:length(tfr_log_pred), Point.Forecast=tfr_log_pred),
          "outputs/forecasts/tfr_log_arima-1-1-1.csv", row.names=FALSE)
saveRDS(fit_tfr_log, "outputs/models/tfr_log_arima-1-1-1.rds")

cat("TFR log-ARIMA(1,1,1) - Ljung-Box p-value:", tfr_log_ljung, "\n")

# ============ TLB Log-ARIMA ============
tlb_ts <- ts(tlb_train)
tlb_log_ts <- log(tlb_ts)

fit_tlb_log <- Arima(tlb_log_ts, order=c(1,1,1))
tlb_log_forecast <- forecast(fit_tlb_log, h=length(tlb_test))
tlb_log_pred <- exp(tlb_log_forecast$mean)  # Back-transform

# Check residuals for TLB
tlb_log_ljung <- Box.test(residuals(fit_tlb_log), lag=10, type='Ljung-Box')$p.value

# Diagnostics plots
png("outputs/plots/tlb_log_residuals_acf.png")
acf(fit_tlb_log$residuals, main="TLB log-ARIMA ACF")
dev.off()

png("outputs/plots/tlb_log_residuals_pacf.png")
pacf(fit_tlb_log$residuals, main="TLB log-ARIMA PACF")
dev.off()

png("outputs/plots/tlb_log_residuals_tsdisplay.png")
tsdisplay(fit_tlb_log$residuals, main="TLB log-ARIMA Residuals")
dev.off()

# Forecast plot
png("outputs/plots/tlb_log_forecast.png")
plot(forecast(fit_tlb_log, h=length(tlb_test)), main="TLB log-ARIMA Forecast")
dev.off()

# Save outputs
write.csv(data.frame(year=1:length(tlb_log_pred), Point.Forecast=tlb_log_pred),
          "outputs/forecasts/tlb_log_arima-1-1-1.csv", row.names=FALSE)
saveRDS(fit_tlb_log, "outputs/models/tlb_log_arima-1-1-1.rds")

cat("TLB log-ARIMA(1,1,1) - Ljung-Box p-value:", tlb_log_ljung, "\n")
cat("Log-ARIMA models complete.\n")

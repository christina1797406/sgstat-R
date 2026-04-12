# Time series model 1 - ARIMA

library(forecast)

# Load data
tfr_train <- read.csv("data/clean_data/tfr_train.csv")
tfr_test  <- read.csv("data/clean_data/tfr_test.csv")

tlb_train <- read.csv("data/clean_data/tlb_train.csv")
tlb_test  <- read.csv("data/clean_data/tlb_test.csv")

# Convert to time series
tfr_ts <- ts(tfr_train$TFR, start=min(tfr_train$Year), frequency=1)
tlb_ts <- ts(tlb_train$TLB, start=min(tlb_train$Year), frequency=1)

# TFR ARIMA
tfr_arima <- auto.arima(tfr_ts)
tfr_forecast <- forecast(tfr_arima, h=nrow(tfr_test))

# TLB ARIMA
tlb_arima <- auto.arima(tlb_ts)
tlb_forecast <- forecast(tlb_arima, h=nrow(tlb_test))

# Save forecasts
write.csv(data.frame(tfr_forecast), "outputs/forecasts/tfr_arima.csv")
write.csv(data.frame(tlb_forecast), "outputs/forecasts/tlb_arima.csv")

# Save models
saveRDS(tfr_arima, "outputs/models/tfr_arima.rds")
saveRDS(tlb_arima, "outputs/models/tlb_arima.rds")

cat("ARIMA models complete.\n")
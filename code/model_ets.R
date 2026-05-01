# Time series model 2 - ETS

library(forecast)

# Load data
tfr_train <- read.csv("data/clean_data/tfr_train.csv")
tfr_test  <- read.csv("data/clean_data/tfr_test.csv")

tlb_train <- read.csv("data/clean_data/tlb_train.csv")
tlb_test  <- read.csv("data/clean_data/tlb_test.csv")

# Convert to time series
tfr_ts <- ts(tfr_train$TFR, start=min(tfr_train$year), frequency=1)
tlb_ts <- ts(tlb_train$TLB, start=min(tlb_train$year), frequency=1)

# TFR ETS
tfr_ets <- ets(tfr_ts)
tfr_forecast <- forecast(tfr_ets, h=nrow(tfr_test))

# TLB ETS
tlb_ets <- ets(tlb_ts)
tlb_forecast <- forecast(tlb_ets, h=nrow(tlb_test))

# Save forecasts
write.csv(data.frame(tfr_forecast), "outputs/forecasts/tfr_ets.csv")
write.csv(data.frame(tlb_forecast), "outputs/forecasts/tlb_ets.csv")

# Save models
saveRDS(tfr_ets, "outputs/models/tfr_ets.rds")
saveRDS(tlb_ets, "outputs/models/tlb_ets.rds")

cat("ETS models complete.\n")
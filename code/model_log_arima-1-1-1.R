# Time series model 3 - Log-ARIMA 1, 1, 1 Revised

library(forecast)
library(tseries)

# Load data
tfr_train <- read.csv("data/clean_data/tfr_train.csv")
tfr_test  <- read.csv("data/clean_data/tfr_test.csv")

# Convert to time series
tfr_ts <- ts(tfr_train$TFR, start=min(tfr_train$year), frequency=1)

tfr_log_ts <- log(tfr_ts)

fit_log <- Arima(tfr_log_ts, order=c(1,1,1))
summary(fit_log)

checkresiduals(fit_log)

acf(fit_log$residuals)
pacf(fit_log$residuals)
tsdisplay(fit_log$residuals)

log_forecast <- forecast(fit_log, h=nrow(tfr_test))

# Back-transform forecasts
forecast_values <- exp(log_forecast$mean)

# Save outputs
write.csv(data.frame(forecast_values),
          "outputs/forecasts/tfr_log_arima.csv")

saveRDS(fit_log, "outputs/models/tfr_log_arima.rds")

# Compare against ARIMA-1-1-1 model
fit_base <- Arima(tfr_ts, order=c(1,1,1))
AIC(fit_base, fit_log)

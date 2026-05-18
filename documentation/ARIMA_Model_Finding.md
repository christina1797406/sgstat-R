# ARIMA Model Selection Guide for TFR and TLB

This guide explains the full workflow used to find suitable ARIMA models for:

- Total Fertility Rate (TFR)
- Total Live Births (TLB)

The process includes:

- Rebuilding and cleaning the raw dataset
- Creating time series objects
- Checking stationarity
- Applying differencing
- Testing candidate ARIMA models
- Performing residual diagnostics
- Validating forecasts using RMSE
- Selecting the final model

This guide is designed so that commands can be copied directly into the R Console step-by-step.

---

## 1. Rebuild the Clean Dataset

Run the preprocessing script:

```
source("code/rebuild_data.R")
```

This will:

- clean the raw data
- reshape the dataset
- split train/test sets
- export cleaned CSV files into clean_data/

## 2. Verify the Cleaned Data

Load the cleaned datasets:

```
train <- read.csv("clean_data/train.csv")
test <- read.csv("clean_data/test.csv")
```

Check the datasets:

```
nrow(train)
nrow(test)

head(train)
tail(train)

head(test)
tail(test)
```

Expected:

```
Training set: 1960–2012
Test set: 2013–2025
```

## 3. Create Time Series Objects

Create time series objects for TFR and TLB:

```
TFRa <- ts(train$TFR, start = 1960, frequency = 1)
TLBa <- ts(train$TLB, start = 1960, frequency = 1)
```

## 4. Plot Original Time Series

Plot the original series to inspect overall trends:

```
plot(TFRa, main = "TFR Time Series")
plot(TLBa, main = "TLB Time Series")
```

Look for:

- trends
- seasonality
- structural changes
- large fluctuations

## 5. Check Stationarity Visually

Check the ACF and PACF plots:

```
acf(TFRa, lag = 40)
pacf(TFRa, lag = 40)

acf(TLBa, lag = 40)
pacf(TLBa, lag = 40)
```

If:

- ACF decays slowly
- many spikes remain significant

then the series is likely non-stationary.

## 6. Apply First Differencing
Create first-differenced series:

```
diff_tfr <- diff(TFRa)
diff_tlb <- diff(TLBa)
```

Plot differenced series:

```
plot(diff_tfr)
plot(diff_tlb)
```

Check ACF and PACF again:

```
acf(diff_tfr, lag = 40)
pacf(diff_tfr, lag = 40)

acf(diff_tlb, lag = 40)
pacf(diff_tlb, lag = 40)
```

If the series still appears non-stationary, test second differencing.

## 7. Apply Second Differencing if Needed

Create second-differenced series:

```
diff2_tfr <- diff(TFRa, differences = 2)
diff2_tlb <- diff(TLBa, differences = 2)
```

Plot the series:

```
plot(diff2_tfr)
plot(diff2_tlb)
```

Check ACF and PACF:

```
acf(diff2_tfr, lag = 40)
pacf(diff2_tfr, lag = 40)

acf(diff2_tlb, lag = 40)
pacf(diff2_tlb, lag = 40)
```

Use these plots to estimate:
- AR terms from PACF
- MA terms from ACF

## 8. Fit Candidate ARIMA Models for TFR

Example candidate models:
```
tfr_m1 <- arima(TFRa, order = c(10,2,0))
tfr_m2 <- arima(TFRa, order = c(10,2,1))
tfr_m3 <- arima(TFRa, order = c(10,2,2))
tfr_m4 <- arima(TFRa, order = c(12,2,1))
tfr_m5 <- arima(TFRa, order = c(12,2,2))
tfr_m6 <- arima(TFRa, order = c(13,2,1))
```

## 9. Compare Candidate Models Using AIC

Run:
```
AIC(
  tfr_m1,
  tfr_m2,
  tfr_m3,
  tfr_m4,
  tfr_m5,
  tfr_m6
)
```

Interpretation:
- Lower AIC = better model fit
- AIC alone should not determine the final model

## 10. Perform Residual Diagnostics

Assume the best model is:

```
tfr_m5
```

Check residual autocorrelation:

```
acf(tfr_m5$resid, lag = 40)
pacf(tfr_m5$resid, lag = 40)
```

Good residuals should:
- appear random
- contain few significant spikes

## 11. Run Ljung-Box Test

Run:
```
Box.test(
  tfr_m5$resid,
  lag = 20,
  type = "Ljung-Box",
  fitdf = 14
)
```

Interpretation:
p-value > 0.05 → residuals resemble white noise
p-value < 0.05 → residual autocorrelation still exists

## 12. Validate Forecast Accuracy

Forecast future values:
```
pred <- predict(tfr_m5, n.ahead = 13)
```

Create forecast table:

```
forecast <- data.frame(
  year = test$year,
  actual = test$TFR,
  predicted = as.numeric(pred$pred)
)
```

View forecast results:
```
forecast
```

## 13. Compute RMSE

Calculate Root Mean Squared Error:
```
sqrt(mean((forecast$actual - forecast$predicted)^2))
```

Interpretation:
Lower RMSE = better forecasting performance
RMSE is often more important than AIC

## 14. Plot Actual vs Forecasted Values
```
plot(
  test$year,
  test$TFR,
  type = "l",
  col = "blue",
  lwd = 2,
  ylim = range(c(test$TFR, forecast$predicted)),
  xlab = "Year",
  ylab = "TFR",
  main = "Actual vs Forecasted TFR"
)

lines(
  test$year,
  forecast$predicted,
  col = "red",
  lwd = 2
)

legend(
  "topright",
  legend = c("Actual", "Forecast"),
  col = c("blue", "red"),
  lty = 1,
  lwd = 2
)
```

## 15. Select Final TFR Model

The final model should balance:
- low AIC
- low RMSE
- good residual behaviour
- reasonable forecast trends
- acceptable Ljung-Box result

## 16. Repeat the Same Process for TLB

Example candidate models:
```
tlb_m1 <- arima(TLBa, order = c(10,2,0))
tlb_m2 <- arima(TLBa, order = c(10,2,1))
tlb_m3 <- arima(TLBa, order = c(10,2,2))
tlb_m4 <- arima(TLBa, order = c(12,2,1))
tlb_m5 <- arima(TLBa, order = c(12,2,2))
tlb_m6 <- arima(TLBa, order = c(13,2,1))
```

Then repeat:
- AIC comparison
- residual diagnostics
- Ljung-Box test
- forecasting
- RMSE evaluation
# Time Series Model - Non-Seasonal ARIMA(2,0,1)

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

# Systematic ARIMA Search - TFR ----------
tfr_results <- data.frame(
  p = integer(),
  d = integer(),
  q = integer(),
  AIC = double(),
  LB_pvalue = double()
)

# Test multiple ARIMA(p,d,q) combinations
for (p in 0:5) {
  for (d in 0:1) {
    for (q in 0:5) {
      
      fit <- tryCatch(
        Arima(tfr_ts, order = c(p,d,q)),
        error = function(e) NULL
      )
      
      if (!is.null(fit)) {
        
        # Ljung-Box test
        lb <- Box.test(
          residuals(fit),
          lag = 20,
          type = "Ljung-Box",
          fitdf = p + q
        )$p.value
        
        # Store results
        tfr_results <- rbind(
          tfr_results,
          data.frame(
            p = p,
            d = d,
            q = q,
            AIC = AIC(fit),
            LB_pvalue = lb
          )
        )
      }
    }
  }
}

# Sort Results (high p-value, low AIC)
tfr_results <- tfr_results[
  order(-tfr_results$LB_pvalue, tfr_results$AIC),
]

print(tfr_results)

# Save all tested models
write.csv(
  tfr_results,
  "outputs/tfr_arima_systematic_model_comparison.csv",
  row.names = FALSE
)

# Filter Models (p-value > 0.05)
valid_tfr_models <- subset(
  tfr_results,
  LB_pvalue > 0.05
)

print(valid_tfr_models)

write.csv(
  valid_tfr_models,
  "outputs/tfr_valid_models.csv",
  row.names = FALSE
)

# Final Baseline Model
tfr_arima <- Arima(
  tfr_ts,
  order = c(2,0,1)
)

summary(tfr_arima)

saveRDS(
  tfr_arima,
  "outputs/models/tfr_arima_2_0_1.rds"
)

# Residual Diagnostics
png("outputs/plots/tfr_systematic_residuals_acf.png")
acf(
  tfr_arima$residuals,
  lag.max = 40,
  main = "TFR Residuals for ARIMA(2,0,1) Model - ACF"
)
dev.off()

png("outputs/plots/tfr_systematic_residuals_pacf.png")
pacf(
  tfr_arima$residuals,
  lag.max = 40,
  main = "TFR Residuals for ARIMA(2,0,1) Model - PACF"
)
dev.off()

png("outputs/plots/tfr_systematic_residuals_tsdisplay.png")
tsdisplay(
  tfr_arima$residuals,
  main = "Residual Diagnostics for ARIMA(2,0,1) Model Applied to TFR",
  lag.max = 40
)
dev.off()

# Ljung-Box test
tfr_lb <- Box.test(
  tfr_arima$residuals,
  lag = 20,
  type = "Ljung-Box",
  fitdf = 2
)

print(tfr_lb)

# Forecasting - NOT DONE

# Forecast Accuracy - NOT DONE


# Systematic ARIMA Search - TFR ----------
tlb_results <- data.frame(
  p = integer(),
  d = integer(),
  q = integer(),
  AIC = double(),
  LB_pvalue = double()
)

for (p in 0:5) {
  for (d in 0:1) {
    for (q in 0:5) {
      
      fit <- tryCatch(
        Arima(tlb_ts, order = c(p,d,q)),
        error = function(e) NULL
      )
      
      if (!is.null(fit)) {
        
        lb <- Box.test(
          residuals(fit),
          lag = 20,
          type = "Ljung-Box",
          fitdf = p + q
        )$p.value
        
        tlb_results <- rbind(
          tlb_results,
          data.frame(
            p = p,
            d = d,
            q = q,
            AIC = AIC(fit),
            LB_pvalue = lb
          )
        )
      }
    }
  }
}

# Sort Results (high p-value, low AIC)
tlb_results <- tlb_results[
  order(-tlb_results$LB_pvalue, tlb_results$AIC),
]

print(tlb_results)

write.csv(
  tlb_results,
  "outputs/tlb_systematic_model_comparison.csv",
  row.names = FALSE
)

# Filter Models (p-value > 0.05)
valid_tlb_models <- subset(
  tlb_results,
  LB_pvalue > 0.05
)

print(valid_tlb_models)

write.csv(
  valid_tlb_models,
  "outputs/tlb_valid_models.csv",
  row.names = FALSE
)

# Final Baseline Model
tlb_arima <- Arima(
  tlb_ts,
  order = c(4,1,4)
)

summary(tlb_arima)

saveRDS(
  tlb_arima,
  "outputs/models/tlb_arima_4_1_4.rds"
)

# Residual Diagnostics
png("outputs/plots/tlb_systematic_residuals_acf.png")
acf(
  tlb_arima$residuals,
  lag.max = 40,
  main = "TLB Residuals for ARIMA(4,1,4) Model - ACF"
)
dev.off()

png("outputs/plots/tlb_systematic_residuals_pacf.png")
pacf(
  tlb_arima$residuals,
  lag.max = 40,
  main = "TLB Residuals for ARIMA(4,1,4) Model - PACF"
)
dev.off()

png("outputs/plots/tlb_systematic_residuals_tsdisplay.png")
tsdisplay(
  tlb_arima$residuals,
  main = "Residual Diagnostics for ARIMA(4,1,4) Model Applied to TFR",
  lag.max = 40
)
dev.off()

# Ljung-Box test
tlb_lb <- Box.test(
  tlb_arima$residuals,
  lag = 20,
  type = "Ljung-Box",
  fitdf = 2
)

print(tlb_lb)

# Forecasting - NOT DONE

# Forecast Accuracy - NOT DONE

cat("Systematic non-seasonal ARIMA search complete.\n")

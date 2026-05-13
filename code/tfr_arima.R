# =========================================================
# FIND BEST ARIMA MODEL FOR TFR
# =========================================================

# =========================================================
# 1. IMPORT DATA
# =========================================================

train <- read.csv("clean_data/train.csv")

# =========================================================
# 2. CREATE TIME SERIES
# =========================================================

TFRa <- ts(train$TFR, start = 1960, frequency = 1)

# =========================================================
# 3. FIT ARIMA MODELS
# =========================================================

tfr_m1  <- arima(TFRa, order = c(10,2,0))
tfr_m2  <- arima(TFRa, order = c(10,2,1))
tfr_m3  <- arima(TFRa, order = c(10,2,2))
tfr_m4  <- arima(TFRa, order = c(12,2,1))
tfr_m5  <- arima(TFRa, order = c(12,2,2))
tfr_m6  <- arima(TFRa, order = c(13,2,1))
tfr_m7  <- arima(TFRa, order = c(15,2,0))
tfr_m8  <- arima(TFRa, order = c(12,2,3))
tfr_m9  <- arima(TFRa, order = c(11,2,3))
tfr_m10 <- arima(TFRa, order = c(10,2,3))

# =========================================================
# 4. COMPARE MODELS USING AIC
# =========================================================

aic_results <- AIC(
  tfr_m1,
  tfr_m2,
  tfr_m3,
  tfr_m4,
  tfr_m5,
  tfr_m6,
  tfr_m7,
  tfr_m8,
  tfr_m9,
  tfr_m10
)

# Sort from lowest AIC to highest AIC
aic_results_sorted <- aic_results[order(aic_results$AIC), ]

# Display results
cat("Sorted models based from lowest to highest AIC:\n")
print(aic_results_sorted)

# =========================================================
# 5. SELECT BEST MODEL
# =========================================================

best_model_name <- rownames(aic_results_sorted)[1]

cat("\nBest model based on lowest AIC:\n")
cat(best_model_name)
cat(
  paste0(
    ": ARIMA(",
    tfr_m7$arma[1], ",",
    tfr_m7$arma[6], ",",
    tfr_m7$arma[2],
    ")\n"
  )
)

# =========================================================
# 6. STORE BEST MODEL
# =========================================================

best_model <- tfr_m7

# =========================================================
# 7. RESIDUAL DIAGNOSTICS
# =========================================================

# Residual plots
acf(best_model$resid, lag = 40,
    main = "ACF of Residuals")

pacf(best_model$resid, lag = 40,
     main = "PACF of Residuals")

# Ljung-Box test
Box.test(
  best_model$resid,
  lag = 20,
  type = "Ljung-Box",
  fitdf = 15
)

# =========================================================
# 8. SAVE RESIDUAL DIAGNOSTIC PLOTS
# =========================================================

dir.create("outputs/ts_plots", recursive = TRUE, showWarnings = FALSE)

# ACF
png(
  "outputs/ts_plots/tfr_m7_residuals_acf.png", res = 300, width = 2000, height = 1400)
acf(
  best_model$resid,
  lag.max = 40,
  main = "ACF of tfr_m7 Residuals"
)

dev.off()

# PACF
png(
  "outputs/ts_plots/tfr_m7_residuals_pacf.png", res = 300, width = 2000, height = 1400)
pacf(
  best_model$resid,
  lag.max = 40,
  main = "PACF of tfr_m7 Residuals"
)

dev.off()

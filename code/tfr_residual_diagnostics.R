# =========================================================
# TFR RESIDUAL DIAGNOSTICS FOR ARIMA MODELS
# =========================================================

dir.create(
  "outputs/residual_diagnostics",
  recursive = TRUE,
  showWarnings = FALSE
)

# ---------------------------------------------------------
# LOAD SAVED MODELS
# ---------------------------------------------------------

tfr_m7  <- readRDS("outputs/models/raw/tfr_m7_ARIMA_15_2_0.rds")
tfr_m8  <- readRDS("outputs/models/raw/tfr_m8_ARIMA_12_2_3.rds")
tfr_m15 <- readRDS("outputs/models/raw/tfr_m15_ARIMA_15_2_1.rds")
tfr_m11 <- readRDS("outputs/models/raw/tfr_m11_ARIMA_15_1_1.rds")
tfr_m12 <- readRDS("outputs/models/raw/tfr_m12_ARIMA_14_2_3.rds")

# ---------------------------------------------------------
# FUNCTION TO SAVE ACF + PACF
# ---------------------------------------------------------

save_residual_diagnostics <- function(model, model_name) {
  
  p <- model$arma[1]
  d <- model$arma[6]
  q <- model$arma[2]
  
  model_label <- paste0(
    "ARIMA(",
    p, ",", d, ",", q, ")"
  )
  
  png(
    paste0(
      "outputs/residual_diagnostics/",
      model_name,
      "_acf_pacf.png"
    ),
    width = 3000,
    height = 1400,
    res = 300
  )
  
  par(mfrow = c(1,2))
  
  # ACF
  acf(
    model$resid,
    lag.max = 40,
    main = paste0(
      "ACF of Residuals for TFR ",
      model_label
      )
  )
  
  # PACF
  pacf(
    model$resid,
    lag.max = 40,
    main = paste0(
      "PACF of Residuals for TFR ",
      model_label
    )
  )
  
  dev.off()
  
  cat(
    "\nSaved diagnostics for ",
    model_label,
    "\n",
    sep = ""
  )
}

# ---------------------------------------------------------
# GENERATE PLOTS
# ---------------------------------------------------------

save_residual_diagnostics(tfr_m7, "tfr_m7")
save_residual_diagnostics(tfr_m8, "tfr_m8")
save_residual_diagnostics(tfr_m15, "tfr_m15")
save_residual_diagnostics(tfr_m11, "tfr_m11")
save_residual_diagnostics(tfr_m12, "tfr_m12")

cat("\nAll residual diagnostics saved.\n")
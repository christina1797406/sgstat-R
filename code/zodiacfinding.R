# =========================================================
# ARIMA PARAMETER FINDING — TFR & TLB
# Singapore, 1960–2012 (train) | 2013–2025 (test)
#
# STRUCTURE:
#   Phase 1 — Plot raw series
#   Phase 2 — Differencing & stationarity checks
#   Phase 3 — ACF / PACF on differenced series → read p, q
#   Phase 4 — Fit three candidate groups (NO zodiac)
#             Group A: compact ARIMA(p,1,q)  p,q ≤ 3
#             Group B: high-order AR (p = 10..15) — lecturer style
#             Group C: seasonal ARIMA, S = 12
#   Phase 5 — Select best baseline model by AIC + RMSE
#   Phase 6 — Layer zodiac on top in three ways:
#             Z1: zodiac dummy regressors (xreg)
#             Z2: zodiac as a categorical fixed effect (same as Z1 but explicit)
#             Z3: 12-year cosine/sine cycle regressor (soft periodic)
#   Phase 7 — Compare all zodiac layers vs baseline on test RMSE
# =========================================================

library(ggplot2)
library(dplyr)
library(forecast)
library(tseries)

# =========================================================
# 0. LOAD DATA
# =========================================================

train <- read.csv("clean_data/train.csv")
test  <- read.csv("clean_data/test.csv")

TFRa     <- ts(train$TFR, start = 1960, frequency = 1)
TLBa     <- ts(train$TLB, start = 1960, frequency = 1)
TFRa_log <- log(TFRa)
TLBa_log <- log(TLBa)

cat("Training:", nrow(train), "obs (", min(train$year), "-", max(train$year), ")\n")
cat("Test    :", nrow(test),  "obs (", min(test$year),  "-", max(test$year),  ")\n")

# =========================================================
# PHASE 1: RAW TIME SERIES PLOTS
# =========================================================

# --- TFR ---
ggplot(train, aes(x = year, y = TFR)) +
  geom_line(colour = "#378ADD", linewidth = 1.1) +
  geom_point(size = 1.8, colour = "#378ADD") +
  labs(title    = "Singapore Total Fertility Rate — Training Series (1960–2012)",
       subtitle = "Clear downward trend; non-stationary in mean. Structural break ~1975.",
       x = "Year", y = "TFR (births per female)") +
  theme_minimal(base_size = 12)

# --- TLB ---
ggplot(train, aes(x = year, y = TLB)) +
  geom_line(colour = "#1D9E75", linewidth = 1.1) +
  geom_point(size = 1.8, colour = "#1D9E75") +
  scale_y_continuous(labels = scales::comma) +
  labs(title    = "Singapore Total Live Births — Training Series (1960–2012)",
       subtitle = "Downward trend with notable dip 1986, spike 1988 (Dragon year).",
       x = "Year", y = "Total Live Births") +
  theme_minimal(base_size = 12)

# =========================================================
# PHASE 2: DIFFERENCING & STATIONARITY
# =========================================================

# ADF tests on raw series
cat("\n=== ADF: Raw TFR ===\n");  print(adf.test(TFRa))
cat("\n=== ADF: Raw TLB ===\n");  print(adf.test(TLBa))

# First-differenced series
d1_TFR <- diff(TFRa)
d1_TLB <- diff(TLBa)

cat("\n=== ADF: TFR (d=1) ===\n"); print(adf.test(d1_TFR))
cat("\n=== ADF: TLB (d=1) ===\n"); print(adf.test(d1_TLB))

# Second-differenced (check if d=1 is enough)
d2_TFR <- diff(TFRa, differences = 2)
d2_TLB <- diff(TLBa, differences = 2)

cat("\n=== ADF: TFR (d=2) ===\n"); print(adf.test(d2_TFR))
cat("\n=== ADF: TLB (d=2) ===\n"); print(adf.test(d2_TLB))

# Plot differenced series side by side
par(mfrow = c(2, 2))
plot(d1_TFR, main = "TFR — 1st Difference",  ylab = "Δ TFR",  col = "#378ADD")
abline(h = 0, lty = 2, col = "grey50")
plot(d2_TFR, main = "TFR — 2nd Difference",  ylab = "Δ² TFR", col = "#7F77DD")
abline(h = 0, lty = 2, col = "grey50")
plot(d1_TLB, main = "TLB — 1st Difference",  ylab = "Δ TLB",  col = "#1D9E75")
abline(h = 0, lty = 2, col = "grey50")
plot(d2_TLB, main = "TLB — 2nd Difference",  ylab = "Δ² TLB", col = "#BA7517")
abline(h = 0, lty = 2, col = "grey50")
par(mfrow = c(1, 1))

# Decision helper
# Interpretation: if ADF p < 0.05 after d=1, use d=1. If not, use d=2.
# For this dataset both series typically become stationary at d=1.

# =========================================================
# PHASE 3: ACF / PACF — READ p AND q
# =========================================================
# Rules:
#   PACF cuts off at lag p  → AR(p)
#   ACF  cuts off at lag q  → MA(q)
#   Both tail off           → ARMA(p, q)
#   Spike at lag 12         → seasonal component S=12 likely
#   Many significant lags   → consider high-order AR (like lecturer: p=12..15)

par(mfrow = c(2, 2))
acf(d1_TFR,  main = "ACF  — TFR d=1",  lag.max = 30)
pacf(d1_TFR, main = "PACF — TFR d=1",  lag.max = 30)
acf(d1_TLB,  main = "ACF  — TLB d=1",  lag.max = 30)
pacf(d1_TLB, main = "PACF — TLB d=1",  lag.max = 30)
par(mfrow = c(1, 1))

# Also check log-differenced series (useful if variance grows over time)
par(mfrow = c(2, 2))
acf(diff(TFRa_log),  main = "ACF  — log(TFR) d=1",  lag.max = 30)
pacf(diff(TFRa_log), main = "PACF — log(TFR) d=1",  lag.max = 30)
acf(diff(TLBa_log),  main = "ACF  — log(TLB) d=1",  lag.max = 30)
pacf(diff(TLBa_log), main = "PACF — log(TLB) d=1",  lag.max = 30)
par(mfrow = c(1, 1))

# =========================================================
# PHASE 4: FIT CANDIDATE MODELS (NO ZODIAC)
# =========================================================

safe_fit <- function(y, order,
                     seasonal = list(order = c(0, 0, 0), period = NA),
                     label = "") {
  tryCatch({
    fit <- Arima(y, order = order, seasonal = seasonal)
    cat(sprintf("  [OK]   %-35s AIC = %8.2f\n", label, AIC(fit)))
    fit
  },
  error   = function(e) { cat(sprintf("  [SKIP] %-35s — %s\n", label, conditionMessage(e))); NULL },
  warning = function(w) { cat(sprintf("  [WARN] %-35s — %s\n", label, conditionMessage(w))); NULL })
}

# Helper to run a whole group and return only successful fits
fit_group <- function(specs, y) {
  fits <- lapply(specs, function(s) {
    safe_fit(y, s$order,
             seasonal = if (!is.null(s$seasonal)) s$seasonal
             else list(order = c(0,0,0), period = NA),
             label = s$label)
  })
  names(fits) <- sapply(specs, `[[`, "label")
  Filter(Negate(is.null), fits)
}

# ---- GROUP A: compact ARIMA p,q ≤ 3 ----
grp_A_specs <- list(
  list(label="ARIMA(1,1,0)",  order=c(1,1,0)),
  list(label="ARIMA(0,1,1)",  order=c(0,1,1)),
  list(label="ARIMA(1,1,1)",  order=c(1,1,1)),
  list(label="ARIMA(2,1,0)",  order=c(2,1,0)),
  list(label="ARIMA(0,1,2)",  order=c(0,1,2)),
  list(label="ARIMA(2,1,1)",  order=c(2,1,1)),
  list(label="ARIMA(1,1,2)",  order=c(1,1,2)),
  list(label="ARIMA(2,1,2)",  order=c(2,1,2)),
  list(label="ARIMA(3,1,0)",  order=c(3,1,0)),
  list(label="ARIMA(3,1,1)",  order=c(3,1,1)),
  list(label="ARIMA(3,1,2)",  order=c(3,1,2)),
  # Also test d=2 variants suggested by the original guide
  list(label="ARIMA(1,2,1)",  order=c(1,2,1)),
  list(label="ARIMA(2,2,1)",  order=c(2,2,1)),
  list(label="ARIMA(2,2,2)",  order=c(2,2,2))
)

# ---- GROUP B: high-order AR (lecturer style) ----
# A high p "absorbs" any long periodic structure without needing to
# specify it as seasonal. Expensive but sometimes wins on AIC.
grp_B_specs <- list(
  list(label="ARIMA(10,1,0)", order=c(10,1,0)),
  list(label="ARIMA(10,2,0)", order=c(10,2,0)),
  list(label="ARIMA(12,1,0)", order=c(12,1,0)),
  list(label="ARIMA(12,1,1)", order=c(12,1,1)),
  list(label="ARIMA(12,2,1)", order=c(12,2,1)),
  list(label="ARIMA(13,1,0)", order=c(13,1,0)),
  list(label="ARIMA(13,1,1)", order=c(13,1,1)),
  list(label="ARIMA(15,1,0)", order=c(15,1,0)),
  list(label="ARIMA(15,1,1)", order=c(15,1,1))
)

# ---- GROUP C: seasonal ARIMA S=12 ----
# Directly models the 12-year zodiac cycle as a periodic component.
# Seasonal AR (P): spike at lag 12 in PACF
# Seasonal MA (Q): spike at lag 12 in ACF
grp_C_specs <- list(
  list(label="SARIMA(1,1,0)(1,0,0)[12]", order=c(1,1,0),
       seasonal=list(order=c(1,0,0),period=12)),
  list(label="SARIMA(0,1,1)(0,0,1)[12]", order=c(0,1,1),
       seasonal=list(order=c(0,0,1),period=12)),
  list(label="SARIMA(1,1,1)(1,0,0)[12]", order=c(1,1,1),
       seasonal=list(order=c(1,0,0),period=12)),
  list(label="SARIMA(1,1,1)(0,0,1)[12]", order=c(1,1,1),
       seasonal=list(order=c(0,0,1),period=12)),
  list(label="SARIMA(1,1,1)(1,0,1)[12]", order=c(1,1,1),
       seasonal=list(order=c(1,0,1),period=12)),
  list(label="SARIMA(2,1,1)(1,0,0)[12]", order=c(2,1,1),
       seasonal=list(order=c(1,0,0),period=12)),
  list(label="SARIMA(2,1,1)(0,0,1)[12]", order=c(2,1,1),
       seasonal=list(order=c(0,0,1),period=12)),
  list(label="SARIMA(2,1,2)(1,0,0)[12]", order=c(2,1,2),
       seasonal=list(order=c(1,0,0),period=12)),
  list(label="SARIMA(3,1,1)(1,0,0)[12]", order=c(3,1,1),
       seasonal=list(order=c(1,0,0),period=12))
)

# =========================================================
# 4a. FIT ALL GROUPS FOR TFR
# =========================================================

cat("\n\n========== TFR — GROUP A (compact) ==========\n")
fits_TFR_A <- fit_group(grp_A_specs, TFRa)

cat("\n========== TFR — GROUP B (high-order AR) ==========\n")
fits_TFR_B <- fit_group(grp_B_specs, TFRa)

cat("\n========== TFR — GROUP C (seasonal S=12) ==========\n")
fits_TFR_C <- fit_group(grp_C_specs, TFRa)

# =========================================================
# 4b. FIT ALL GROUPS FOR TLB
# =========================================================

cat("\n\n========== TLB — GROUP A (compact) ==========\n")
fits_TLB_A <- fit_group(grp_A_specs, TLBa)

cat("\n========== TLB — GROUP B (high-order AR) ==========\n")
fits_TLB_B <- fit_group(grp_B_specs, TLBa)

cat("\n========== TLB — GROUP C (seasonal S=12) ==========\n")
fits_TLB_C <- fit_group(grp_C_specs, TLBa)

# =========================================================
# PHASE 5: SELECT BEST BASELINE — AIC TABLE + TEST RMSE
# =========================================================

aic_rmse_table <- function(fits_A, fits_B, fits_C, test_actual, series_name,
                           h = nrow(test)) {
  all_fits <- c(fits_A, fits_B, fits_C)
  rows <- lapply(names(all_fits), function(nm) {
    fit  <- all_fits[[nm]]
    grp  <- if (nm %in% names(fits_A)) "A-compact"
    else if (nm %in% names(fits_B)) "B-highAR"
    else "C-seasonal"
    aic_val <- round(AIC(fit), 2)
    fc    <- tryCatch(forecast(fit, h = h), error = function(e) NULL)
    rmse  <- if (!is.null(fc)) {
      round(sqrt(mean((test_actual - as.numeric(fc$mean))^2)), 5)
    } else NA
    data.frame(Series = series_name, Group = grp, Model = nm,
               AIC = aic_val, RMSE = rmse, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

cat("\n\n==========================================================\n")
cat(" FULL COMPARISON TABLE — TFR (no zodiac)\n")
cat("==========================================================\n")
tbl_TFR <- aic_rmse_table(fits_TFR_A, fits_TFR_B, fits_TFR_C, test$TFR, "TFR")
print(tbl_TFR[order(tbl_TFR$RMSE), ], row.names = FALSE)

cat("\n==========================================================\n")
cat(" FULL COMPARISON TABLE — TLB (no zodiac)\n")
cat("==========================================================\n")
tbl_TLB <- aic_rmse_table(fits_TLB_A, fits_TLB_B, fits_TLB_C, test$TLB, "TLB")
print(tbl_TLB[order(tbl_TLB$RMSE), ], row.names = FALSE)

# ---- Pick best by RMSE (change to AIC if preferred) ----
best_TFR_name <- tbl_TFR$Model[which.min(tbl_TFR$RMSE)]
best_TLB_name <- tbl_TLB$Model[which.min(tbl_TLB$RMSE)]

all_TFR_fits <- c(fits_TFR_A, fits_TFR_B, fits_TFR_C)
all_TLB_fits <- c(fits_TLB_A, fits_TLB_B, fits_TLB_C)

best_TFR <- all_TFR_fits[[best_TFR_name]]
best_TLB <- all_TLB_fits[[best_TLB_name]]

cat("\n>>> Best baseline TFR model:", best_TFR_name, "\n")
cat(">>> Best baseline TLB model:", best_TLB_name, "\n")

# ---- Residual diagnostics for best models ----
cat("\n=== Residual diagnostics — TFR ===\n")
checkresiduals(best_TFR)
Box.test(residuals(best_TFR), lag = 20, type = "Ljung-Box")

cat("\n=== Residual diagnostics — TLB ===\n")
checkresiduals(best_TLB)
Box.test(residuals(best_TLB), lag = 20, type = "Ljung-Box")

# =========================================================
# PHASE 6: ZODIAC LAYERS
# =========================================================
# Now that the best baseline model is known, we add zodiac
# in three increasingly sophisticated ways and compare.
#
# Z0 = best baseline (no zodiac)           ← already fitted
# Z1 = best baseline + zodiac dummies (xreg)
# Z2 = best baseline + cosine/sine 12-year cycle (xreg)
#      — a "soft" continuous encoding of the zodiac period;
#        avoids 11 extra parameters from dummy variables
# Z3 = best baseline + Dragon dummy only
#      — tests whether only the Dragon year matters
# =========================================================

zodiac_levels <- c("Rat","Ox","Tiger","Rabbit","Dragon","Snake",
                   "Horse","Goat","Monkey","Rooster","Dog","Pig")
assign_zodiac <- function(yrs) {
  factor(zodiac_levels[((yrs - 2020) %% 12) + 1], levels = zodiac_levels)
}

train$Zodiac   <- assign_zodiac(train$year)
test$Zodiac    <- assign_zodiac(test$year)
train$Dragon   <- as.integer(train$Zodiac == "Dragon")
test$Dragon    <- as.integer(test$Zodiac  == "Dragon")

# Zodiac dummy matrix (Z1)
xreg_z1_train <- model.matrix(~ Zodiac, data = train)[, -1]
xreg_z1_test  <- model.matrix(~ Zodiac, data = test)[, -1]
# Align missing columns (test may not have all 12 animals)
for (col in setdiff(colnames(xreg_z1_train), colnames(xreg_z1_test)))
  xreg_z1_test <- cbind(xreg_z1_test, setNames(data.frame(rep(0, nrow(xreg_z1_test))), col))
xreg_z1_test <- xreg_z1_test[, colnames(xreg_z1_train), drop = FALSE]

# Cosine/sine cycle regressors — 12-year period (Z2)
# This encodes the zodiac cycle as a smooth sinusoidal wave.
# cos(2π·year/12) + sin(2π·year/12) uses only 2 parameters
# but still captures the periodic rhythm.
xreg_z2_train <- cbind(
  cos12 = cos(2 * pi * train$year / 12),
  sin12 = sin(2 * pi * train$year / 12)
)
xreg_z2_test <- cbind(
  cos12 = cos(2 * pi * test$year / 12),
  sin12 = sin(2 * pi * test$year / 12)
)

# Dragon-only dummy (Z3)
xreg_z3_train <- matrix(train$Dragon, ncol = 1, dimnames = list(NULL, "Dragon"))
xreg_z3_test  <- matrix(test$Dragon,  ncol = 1, dimnames = list(NULL, "Dragon"))

# ---- Helper: re-fit best model with xreg ----
refit_with_xreg <- function(base_fit, y, xreg_train, xreg_test, test_actual,
                            label, is_seasonal = FALSE) {
  ord <- base_fit$arma  # [p,q,P,Q,S,d,D]
  # Reconstruct order and seasonal from arma slot
  p <- ord[1]; q <- ord[2]; P <- ord[3]; Q <- ord[4]
  S <- ord[5]; d <- ord[6]; D <- ord[7]
  fit <- tryCatch(
    Arima(y, order = c(p, d, q),
          seasonal = list(order = c(P, D, Q), period = S),
          xreg = xreg_train),
    error = function(e) { cat("  [SKIP]", label, "—", conditionMessage(e), "\n"); NULL }
  )
  if (is.null(fit)) return(NULL)
  fc   <- forecast(fit, xreg = xreg_test, h = nrow(xreg_test))
  rmse <- sqrt(mean((test_actual - as.numeric(fc$mean))^2))
  cat(sprintf("  %-40s AIC = %8.2f   RMSE = %.5f\n",
              label, AIC(fit), rmse))
  list(fit = fit, fc = fc, rmse = rmse, aic = AIC(fit), label = label)
}

cat("\n\n==========================================================\n")
cat(" ZODIAC LAYER COMPARISON — TFR\n")
cat("==========================================================\n")

# Baseline RMSE for comparison
fc_base_TFR  <- forecast(best_TFR, h = nrow(test))
rmse_base_TFR <- sqrt(mean((test$TFR - as.numeric(fc_base_TFR$mean))^2))
cat(sprintf("  %-40s AIC = %8.2f   RMSE = %.5f  [baseline]\n",
            best_TFR_name, AIC(best_TFR), rmse_base_TFR))

z1_TFR <- refit_with_xreg(best_TFR, TFRa, xreg_z1_train, xreg_z1_test,
                          test$TFR, paste0(best_TFR_name, " + Zodiac dummies (Z1)"))
z2_TFR <- refit_with_xreg(best_TFR, TFRa, xreg_z2_train, xreg_z2_test,
                          test$TFR, paste0(best_TFR_name, " + cos/sin cycle (Z2)"))
z3_TFR <- refit_with_xreg(best_TFR, TFRa, xreg_z3_train, xreg_z3_test,
                          test$TFR, paste0(best_TFR_name, " + Dragon dummy (Z3)"))

cat("\n\n==========================================================\n")
cat(" ZODIAC LAYER COMPARISON — TLB\n")
cat("==========================================================\n")

fc_base_TLB  <- forecast(best_TLB, h = nrow(test))
rmse_base_TLB <- sqrt(mean((test$TLB - as.numeric(fc_base_TLB$mean))^2))
cat(sprintf("  %-40s AIC = %8.2f   RMSE = %.2f  [baseline]\n",
            best_TLB_name, AIC(best_TLB), rmse_base_TLB))

z1_TLB <- refit_with_xreg(best_TLB, TLBa, xreg_z1_train, xreg_z1_test,
                          test$TLB, paste0(best_TLB_name, " + Zodiac dummies (Z1)"))
z2_TLB <- refit_with_xreg(best_TLB, TLBa, xreg_z2_train, xreg_z2_test,
                          test$TLB, paste0(best_TLB_name, " + cos/sin cycle (Z2)"))
z3_TLB <- refit_with_xreg(best_TLB, TLBa, xreg_z3_train, xreg_z3_test,
                          test$TLB, paste0(best_TLB_name, " + Dragon dummy (Z3)"))

# =========================================================
# PHASE 7: FINAL SUMMARY PLOT
# =========================================================

plot_forecast_comparison <- function(test_df, actual_col,
                                     base_fc, z1, z2, z3,
                                     title_str, y_label) {
  yrs <- test_df$year
  act <- test_df[[actual_col]]
  df  <- data.frame(
    year   = rep(yrs, 4),
    value  = c(as.numeric(base_fc$mean),
               if (!is.null(z1)) as.numeric(z1$fc$mean) else rep(NA, length(yrs)),
               if (!is.null(z2)) as.numeric(z2$fc$mean) else rep(NA, length(yrs)),
               if (!is.null(z3)) as.numeric(z3$fc$mean) else rep(NA, length(yrs))),
    model  = rep(c("Baseline","Z1: Dummies","Z2: cos/sin","Z3: Dragon"), each=length(yrs))
  )
  ggplot() +
    geom_line(data = test_df, aes(x = year, y = .data[[actual_col]]),
              colour = "black", linewidth = 1.3) +
    geom_line(data = df, aes(x = year, y = value, colour = model, linetype = model),
              linewidth = 0.9) +
    scale_colour_manual(values = c("Baseline"    = "#378ADD",
                                   "Z1: Dummies" = "#D85A30",
                                   "Z2: cos/sin" = "#1D9E75",
                                   "Z3: Dragon"  = "#7F77DD")) +
    scale_linetype_manual(values = c("Baseline"    = "solid",
                                     "Z1: Dummies" = "dashed",
                                     "Z2: cos/sin" = "dotted",
                                     "Z3: Dragon"  = "dotdash")) +
    labs(title    = title_str,
         subtitle = "Black = actual; coloured lines = model forecasts (2013–2025)",
         x = "Year", y = y_label, colour = "Model", linetype = "Model") +
    theme_minimal(base_size = 12)
}

plot_forecast_comparison(test, "TFR",
                         fc_base_TFR, z1_TFR, z2_TFR, z3_TFR,
                         "TFR: Baseline vs Zodiac-enhanced Forecasts",
                         "TFR (births per female)")

plot_forecast_comparison(test, "TLB",
                         fc_base_TLB, z1_TLB, z2_TLB, z3_TLB,
                         "TLB: Baseline vs Zodiac-enhanced Forecasts",
                         "Total Live Births")

# =========================================================
# BEST AIC MODELS
# =========================================================

best_TFR_AIC_name <- tbl_TFR$Model[which.min(tbl_TFR$AIC)]
best_TLB_AIC_name <- tbl_TLB$Model[which.min(tbl_TLB$AIC)]

best_TFR_AIC <- all_TFR_fits[[best_TFR_AIC_name]]
best_TLB_AIC <- all_TLB_fits[[best_TLB_AIC_name]]

cat("\nBest AIC TFR:", best_TFR_AIC_name)
cat("\nBest AIC TLB:", best_TLB_AIC_name)

fc_TFR_AIC <- forecast(best_TFR_AIC, h = nrow(test))
fc_TLB_AIC <- forecast(best_TLB_AIC, h = nrow(test))

fc_TFR_RMSE <- forecast(best_TFR, h = nrow(test))
fc_TLB_RMSE <- forecast(best_TLB, h = nrow(test))

plot_single_forecast <- function(
    years,
    actual,
    forecast_values,
    title_text,
    ylab_text
){
  actual_df <- data.frame(
    year   = years,
    actual = actual
  )
  fc_df <- data.frame(
    year     = years,
    forecast = as.numeric(forecast_values)
  )
  
  ggplot() +
    geom_line(
      data = actual_df,
      aes(x = year, y = actual),
      linewidth = 1.2,
      colour = "black"
    ) +
    geom_line(
      data = fc_df,
      aes(x = year, y = forecast),
      linewidth = 1.2,
      colour = "red"
    ) +
    labs(
      title    = title_text,
      subtitle = "Black = Actual | Red = Forecast",
      x = "Year",
      y = ylab_text
    ) +
    theme_minimal()
}

# visual plot

plot_single_forecast(
  test$year,
  test$TFR,
  fc_TFR_AIC$mean,
  paste("TFR Best AIC:", best_TFR_AIC_name),
  "TFR"
)

plot_single_forecast(
  test$year,
  test$TLB,
  fc_TLB_AIC$mean,
  paste("TLB Best AIC:", best_TLB_AIC_name),
  "Live Births"
)

plot_single_forecast(
  test$year,
  test$TFR,
  fc_TFR_RMSE$mean,
  paste("TFR Best RMSE:", best_TFR_name),
  "TFR"
)

plot_single_forecast( 
  test$year,
  test$TLB,
  fc_TLB_RMSE$mean,
  paste("TLB Best RMSE:", best_TLB_name),
  "Live Births"
)
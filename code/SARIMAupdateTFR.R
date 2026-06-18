# =========================================================
# SARIMA PARAMETER FINDING — TFR
# Singapore, 1960–2012 (train) | 2013–2025 (test)

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
TFRa_log <- log(TFRa)

cat("Training:", nrow(train), "obs (", min(train$year), "-", max(train$year), ")\n")
cat("Test    :", nrow(test),  "obs (", min(test$year),  "-", max(test$year),  ")\n")

# =========================================================
# PHASE 1: RAW TIME SERIES PLOT
# =========================================================

ggplot(train, aes(x = year, y = TFR)) +
  geom_line(colour = "#378ADD", linewidth = 1.1) +
  geom_point(size = 1.8, colour = "#378ADD") +
  scale_y_continuous(labels = scales::comma) +
  labs(title    = "Singapore Total Fertility Rate - Training Series (1960-2012)",
       subtitle = "Clear downward trend; non-stationary in mean. Structural break ~1975.",
       x = "Year", y = "Total Fertility Rate") +
  theme_minimal(base_size = 12)

# =========================================================
# PHASE 2: DIFFERENCING & STATIONARITY
# =========================================================
# For SARIMA(p,1,q)(P,1,Q)[12] we apply:
#   d = 1  non-seasonal difference
#   D = 1  seasonal difference (lag 12)
# Check stationarity at each stage.

cat("\n=== ADF: Raw TFR ===\n"); print(adf.test(TFRa))

# Non-seasonal first difference
d1_TFR <- diff(TFRa)
cat("\n=== ADF: TFR (d=1) ===\n"); print(adf.test(d1_TFR))

# Seasonal difference on top of d=1 (lag = 12)
d1D1_TFR <- diff(d1_TFR, lag = 12)
cat("\n=== ADF: TFR (d=1, D=1) ===\n"); print(adf.test(d1D1_TFR))

# Plot differenced series
par(mfrow = c(1, 2))
plot(d1_TFR,   main = "TFR - d=1",      ylab = "delta TFR",      col = "#378ADD")
abline(h = 0, lty = 2, col = "grey50")
plot(d1D1_TFR, main = "TFR - d=1, D=1", ylab = "delta delta12 TFR", col = "#7F77DD")
abline(h = 0, lty = 2, col = "grey50")
par(mfrow = c(1, 1))

# =========================================================
# PHASE 3: ACF / PACF - READ p, q, P, Q
# =========================================================
# On the fully-differenced series (d=1, D=1):
#   Non-seasonal lags (1..11):
#     PACF cuts off at lag p  -> AR(p)
#     ACF  cuts off at lag q  -> MA(q)
#   Seasonal lags (12, 24, 36):
#     PACF cuts off at lag 12*P -> SAR(P)
#     ACF  cuts off at lag 12*Q -> SMA(Q)
#   Both tailing off at either scale -> mixed ARMA / SARMA

par(mfrow = c(1, 2))
acf(d1D1_TFR,  main = "ACF  - TFR (d=1, D=1)", lag.max = 40)
pacf(d1D1_TFR, main = "PACF - TFR (d=1, D=1)", lag.max = 40)
par(mfrow = c(1, 1))

# Log-differenced (useful if variance grows over time)
par(mfrow = c(1, 2))
acf(diff(diff(TFRa_log), lag = 12),  main = "ACF  - log(TFR) d=1, D=1", lag.max = 40)
pacf(diff(diff(TFRa_log), lag = 12), main = "PACF - log(TFR) d=1, D=1", lag.max = 40)
par(mfrow = c(1, 1))

# =========================================================
# PHASE 4: FIT SARIMA CANDIDATE GRID
# ALL follow (p, 1, q)(P, 1, Q)[12]
# =========================================================

safe_fit <- function(y, p, q, P, Q, label) {
  tryCatch({
    fit <- Arima(y,
                 order    = c(p, 1, q),
                 seasonal = list(order = c(P, 1, Q), period = 12))
    cat(sprintf("  [OK]   %-45s AIC = %8.2f\n", label, AIC(fit)))
    fit
  },
  error   = function(e) {
    cat(sprintf("  [SKIP] %-45s - %s\n", label, conditionMessage(e))); NULL
  },
  warning = function(w) {
    cat(sprintf("  [WARN] %-45s - %s\n", label, conditionMessage(w))); NULL
  })
}

make_label <- function(p, q, P, Q)
  sprintf("SARIMA(%d,1,%d)(%d,1,%d)[12]", p, q, P, Q)

fit_sarima_grid <- function(y, p_vals, q_vals, P_vals, Q_vals) {
  fits <- list()
  for (p in p_vals) for (q in q_vals) for (P in P_vals) for (Q in Q_vals) {
    lbl <- make_label(p, q, P, Q)
    fit <- safe_fit(y, p, q, P, Q, lbl)
    if (!is.null(fit)) fits[[lbl]] <- fit
  }
  fits
}

# p,q in {0,1,2}, P,Q in {0,1,2}
cat("\n\n========== SARIMA CANDIDATE GRID (p,q <= 4 ; P,Q <= 4) ==========\n")
fits_TFR <- fit_sarima_grid(TFRa,
                            p_vals = 0:3, q_vals = 0:3,
                            P_vals = 0:3, Q_vals = 0:3)

# =========================================================
# PHASE 5: SELECT BEST BASELINE - AIC TABLE + TEST RMSE
# =========================================================

tbl_TFR <- do.call(rbind, lapply(names(fits_TFR), function(nm) {
  fit     <- fits_TFR[[nm]]
  aic_val <- round(AIC(fit), 2)
  fc      <- tryCatch(forecast(fit, h = nrow(test)), error = function(e) NULL)
  rmse    <- if (!is.null(fc))
    round(sqrt(mean((test$TFR - as.numeric(fc$mean))^2)), 5)
  else NA
  data.frame(Model = nm, AIC = aic_val, RMSE = rmse, stringsAsFactors = FALSE)
}))

cat("\n\n==========================================================\n")
cat(" FULL COMPARISON TABLE - TFR (no zodiac)\n")
cat("==========================================================\n")
print(tbl_TFR[order(tbl_TFR$RMSE), ], row.names = FALSE)

# ---- Pick best by RMSE and by AIC ----
best_TFR_name     <- tbl_TFR$Model[which.min(tbl_TFR$RMSE)]
best_TFR_AIC_name <- tbl_TFR$Model[which.min(tbl_TFR$AIC)]

best_TFR     <- fits_TFR[[best_TFR_name]]
best_TFR_AIC <- fits_TFR[[best_TFR_AIC_name]]

cat("\n>>> Best baseline TFR model (RMSE):", best_TFR_name, "\n")
cat(">>> Best baseline TFR model (AIC) :", best_TFR_AIC_name, "\n")

# ---- Residual diagnostics ----
cat("\n=== Residual diagnostics - best RMSE model ===\n")
checkresiduals(best_TFR)

# =========================================================
# PHASE 6: ZODIAC LAYERS
# =========================================================
# Z0 = best baseline (no zodiac)
# Z1 = + zodiac dummy regressors (xreg; 11 dummies, Rat = reference)
# Z2 = + 12-year cosine/sine cycle (xreg; 2 parameters, soft encoding)
# Z3 = + Dragon dummy only (xreg; 1 parameter)

zodiac_levels <- c("Rat","Ox","Tiger","Rabbit","Dragon","Snake",
                   "Horse","Goat","Monkey","Rooster","Dog","Pig")
assign_zodiac <- function(yrs) {
  factor(zodiac_levels[((yrs - 2020) %% 12) + 1], levels = zodiac_levels)
}

train$Zodiac <- assign_zodiac(train$year)
test$Zodiac  <- assign_zodiac(test$year)
train$Dragon <- as.integer(train$Zodiac == "Dragon")
test$Dragon  <- as.integer(test$Zodiac  == "Dragon")

# Z1: zodiac dummy matrix (reference = Rat)
xreg_z1_train <- model.matrix(~ Zodiac, data = train)[, -1]
xreg_z1_test  <- model.matrix(~ Zodiac, data = test)[, -1]
for (col in setdiff(colnames(xreg_z1_train), colnames(xreg_z1_test)))
  xreg_z1_test <- cbind(xreg_z1_test,
                        setNames(data.frame(rep(0, nrow(xreg_z1_test))), col))
xreg_z1_test <- xreg_z1_test[, colnames(xreg_z1_train), drop = FALSE]

# Z2: cosine/sine 12-year cycle
xreg_z2_train <- cbind(cos12 = cos(2 * pi * train$year / 12),
                       sin12 = sin(2 * pi * train$year / 12))
xreg_z2_test  <- cbind(cos12 = cos(2 * pi * test$year  / 12),
                       sin12 = sin(2 * pi * test$year  / 12))

# Z3: Dragon dummy
xreg_z3_train <- matrix(train$Dragon, ncol = 1,
                        dimnames = list(NULL, "Dragon"))
xreg_z3_test  <- matrix(test$Dragon,  ncol = 1,
                        dimnames = list(NULL, "Dragon"))

# ---- Helper: re-fit SARIMA with xreg ----
refit_with_xreg <- function(base_fit, y, xreg_train, xreg_test, test_actual, label) {
  ord <- base_fit$arma   # [p, q, P, Q, S, d, D]
  p <- ord[1]; q <- ord[2]; P <- ord[3]; Q <- ord[4]
  S <- ord[5]; d <- ord[6]; D <- ord[7]
  fit <- tryCatch(
    Arima(y,
          order    = c(p, d, q),
          seasonal = list(order = c(P, D, Q), period = S),
          xreg     = xreg_train),
    error = function(e) {
      cat("  [SKIP]", label, "-", conditionMessage(e), "\n"); NULL
    }
  )
  if (is.null(fit)) return(NULL)
  fc   <- forecast(fit, xreg = xreg_test, h = nrow(xreg_test))
  rmse <- sqrt(mean((test_actual - as.numeric(fc$mean))^2))
  cat(sprintf("  %-55s AIC = %8.2f   RMSE = %.5f\n", label, AIC(fit), rmse))
  list(fit = fit, fc = fc, rmse = rmse, aic = AIC(fit), label = label)
}

cat("\n\n==========================================================\n")
cat(" ZODIAC LAYER COMPARISON - TFR\n")
cat("==========================================================\n")

fc_base_TFR   <- forecast(best_TFR, h = nrow(test))
rmse_base_TFR <- sqrt(mean((test$TFR - as.numeric(fc_base_TFR$mean))^2))
cat(sprintf("  %-55s AIC = %8.2f   RMSE = %.5f  [baseline]\n",
            best_TFR_name, AIC(best_TFR), rmse_base_TFR))

z1_TFR <- refit_with_xreg(best_TFR, TFRa,
                          xreg_z1_train, xreg_z1_test, test$TFR,
                          paste0(best_TFR_name, " + Zodiac dummies (Z1)"))
z2_TFR <- refit_with_xreg(best_TFR, TFRa,
                          xreg_z2_train, xreg_z2_test, test$TFR,
                          paste0(best_TFR_name, " + cos/sin cycle (Z2)"))
z3_TFR <- refit_with_xreg(best_TFR, TFRa,
                          xreg_z3_train, xreg_z3_test, test$TFR,
                          paste0(best_TFR_name, " + Dragon dummy (Z3)"))

# =========================================================
# PHASE 7: FINAL SUMMARY PLOTS
# =========================================================

plot_single_forecast <- function(train_years, train_actual,
                                 test_years,  test_actual,
                                 forecast_values,
                                 title_text, ylab_text) {
  ggplot() +
    geom_line(data = data.frame(year = train_years, value = train_actual),
              aes(x = year, y = value),
              linewidth = 1.1, colour = "black") +
    geom_line(data = data.frame(year = test_years, value = test_actual),
              aes(x = year, y = value),
              linewidth = 1.1, colour = "black", linetype = "dashed") +
    geom_line(data = data.frame(year  = test_years,
                                value = as.numeric(forecast_values)),
              aes(x = year, y = value),
              linewidth = 1.1, colour = "red") +
    geom_vline(xintercept = min(test_years) - 0.5,
               linetype = "dotted", colour = "grey50") +
    labs(title    = title_text,
         subtitle = "Black solid = training | Black dashed = test actual | Red = SARIMA forecast",
         x = "Year", y = ylab_text) +
    theme_minimal()
}

# Best RMSE and best AIC individual plots
fc_TFR_RMSE <- forecast(best_TFR,     h = nrow(test))
fc_TFR_AIC  <- forecast(best_TFR_AIC, h = nrow(test))

plot_single_forecast(train$year, train$TFR,
                     test$year,  test$TFR,
                     fc_TFR_RMSE$mean,
                     paste("TFR Best RMSE:", best_TFR_name),
                     "Total Fertility Rate")

plot_single_forecast(train$year, train$TFR,
                     test$year,  test$TFR,
                     fc_TFR_AIC$mean,
                     paste("TFR Best AIC:", best_TFR_AIC_name),
                     "Total Fertility Rate")

# Zodiac comparison plot
yrs <- test$year
df_zodiac <- data.frame(
  year  = rep(yrs, 4),
  value = c(as.numeric(fc_base_TFR$mean),
            if (!is.null(z1_TFR)) as.numeric(z1_TFR$fc$mean) else rep(NA, length(yrs)),
            if (!is.null(z2_TFR)) as.numeric(z2_TFR$fc$mean) else rep(NA, length(yrs)),
            if (!is.null(z3_TFR)) as.numeric(z3_TFR$fc$mean) else rep(NA, length(yrs))),
  model = rep(c("Baseline","Z1: Dummies","Z2: cos/sin","Z3: Dragon"),
              each = length(yrs))
)

ggplot() +
  geom_line(data = test,
            aes(x = year, y = TFR),
            colour = "black", linewidth = 1.3) +
  geom_line(data = df_zodiac,
            aes(x = year, y = value, colour = model, linetype = model),
            linewidth = 0.9) +
  scale_colour_manual(values = c("Baseline"    = "#378ADD",
                                 "Z1: Dummies" = "#D85A30",
                                 "Z2: cos/sin" = "#1D9E75",
                                 "Z3: Dragon"  = "#7F77DD")) +
  scale_linetype_manual(values = c("Baseline"    = "solid",
                                   "Z1: Dummies" = "dashed",
                                   "Z2: cos/sin" = "dotted",
                                   "Z3: Dragon"  = "dotdash")) +
  labs(title    = "TFR: Baseline SARIMA vs Zodiac-enhanced Forecasts",
       subtitle = "Black = actual; coloured lines = SARIMA forecasts (2013-2025)",
       x = "Year", y = "Total Fertility Rate",
       colour = "Model", linetype = "Model") +
  theme_minimal(base_size = 12)
x

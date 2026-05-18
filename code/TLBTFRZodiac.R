library(readxl)
library(ggplot2)
library(dplyr)
library(forecast)
library(tseries)

zodiacs <- c("Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
             "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig")

zodiac_year <- function(year) {
  factor(zodiacs[((year - 2020) %% 12) + 1])
}

# Safely fit an ARIMA model; returns NULL on failure
safe_arima <- function(y, order, xreg = NULL, label = "") {
  tryCatch(
    {
      fit <- Arima(y, order = order, xreg = xreg)
      cat("  [OK]", label, "| AIC =", round(AIC(fit), 2), "\n")
      fit
    },
    error   = function(e) { cat("  [SKIP]", label, "- Error:",   conditionMessage(e), "\n"); NULL },
    warning = function(w) { cat("  [WARN]", label, "- Warning:", conditionMessage(w), "\n"); NULL }
  )
}

# Select & report the best model from a named list by AIC
select_best <- function(candidates) {
  aic_vals <- sapply(candidates, AIC)
  aic_df   <- data.frame(Model = names(aic_vals), AIC = round(aic_vals, 2))
  cat("\n=== AIC Comparison ===\n")
  print(aic_df[order(aic_df$AIC), ], row.names = FALSE)
  best_name <- names(which.min(aic_vals))
  best_fit  <- candidates[[best_name]]
  cat("\nBest model:", best_name, "| AIC =", round(AIC(best_fit), 2), "\n\n")
  list(name = best_name, fit = best_fit)
}

# ============================================================
#  PART 1 — TOTAL LIVE BIRTHS (TLB)
# ============================================================

cat("\n", strrep("=", 60), "\n")
cat(" PART 1: TOTAL LIVE BIRTHS\n")
cat(strrep("=", 60), "\n")

# ---- 1a. Data Cleaning ----------------------------------------

raw <- read_excel("M810091.xlsx", sheet = "M810091")

births_row <- raw[grep("TotalLive-Births\\(Number\\)", raw$DataSeries), ]
years_raw  <- as.numeric(names(births_row)[-1])
vals_raw   <- as.numeric(births_row[1, -1])

tlb <- data.frame(Year = years_raw, Births = vals_raw) %>%
  filter(Year >= 1977, Year <= 2013) %>%
  arrange(Year) %>%
  filter(!is.na(Births), !is.infinite(Births))

tlb$Zodiac <- factor(zodiac_year(tlb$Year), levels = zodiacs)

cat("TLB dataset:", nrow(tlb), "observations |",
    min(tlb$Year), "-", max(tlb$Year), "\n")
cat("Missing values removed. Zodiac labels assigned.\n")

# ADF stationarity check (informs differencing order)
cat("\n--- Stationarity (ADF) ---\n")
cat("Original:      p =", round(adf.test(tlb$Births)$p.value, 4), "\n")
cat("1st Difference: p =", round(adf.test(diff(tlb$Births))$p.value, 4), "\n")
cat("=> d = 1 selected\n")

# ---- 1b. Build Zodiac Regressor Matrix ------------------------

xreg_tlb <- model.matrix(~ Zodiac, data = tlb)[, -1]

# ---- 1c. Model Selection (ARIMA candidates, d = 1) -------------

cat("\n--- Fitting TLB Candidates ---\n")

tlb_candidates <- Filter(Negate(is.null), list(
  "ARIMA(1,1,2) [reference]" = safe_arima(tlb$Births, c(1,1,2), xreg_tlb, "ARIMA(1,1,2)"),
  "ARIMA(0,1,0)"             = safe_arima(tlb$Births, c(0,1,0), xreg_tlb, "ARIMA(0,1,0)"),
  "ARIMA(1,1,0)"             = safe_arima(tlb$Births, c(1,1,0), xreg_tlb, "ARIMA(1,1,0)"),
  "ARIMA(2,1,0)"             = safe_arima(tlb$Births, c(2,1,0), xreg_tlb, "ARIMA(2,1,0)"),
  "ARIMA(3,1,0)"             = safe_arima(tlb$Births, c(3,1,0), xreg_tlb, "ARIMA(3,1,0)"),
  "ARIMA(0,1,1)"             = safe_arima(tlb$Births, c(0,1,1), xreg_tlb, "ARIMA(0,1,1)"),
  "ARIMA(0,1,2)"             = safe_arima(tlb$Births, c(0,1,2), xreg_tlb, "ARIMA(0,1,2)"),
  "ARIMA(0,1,3)"             = safe_arima(tlb$Births, c(0,1,3), xreg_tlb, "ARIMA(0,1,3)"),
  "ARIMA(1,1,1)"             = safe_arima(tlb$Births, c(1,1,1), xreg_tlb, "ARIMA(1,1,1)"),
  "ARIMA(1,1,3)"             = safe_arima(tlb$Births, c(1,1,3), xreg_tlb, "ARIMA(1,1,3)"),
  "ARIMA(2,1,1)"             = safe_arima(tlb$Births, c(2,1,1), xreg_tlb, "ARIMA(2,1,1)"),
  "ARIMA(2,1,2)"             = safe_arima(tlb$Births, c(2,1,2), xreg_tlb, "ARIMA(2,1,2)"),
  "ARIMA(2,1,3)"             = safe_arima(tlb$Births, c(2,1,3), xreg_tlb, "ARIMA(2,1,3)"),
  "ARIMA(3,1,1)"             = safe_arima(tlb$Births, c(3,1,1), xreg_tlb, "ARIMA(3,1,1)"),
  "ARIMA(3,1,2)"             = safe_arima(tlb$Births, c(3,1,2), xreg_tlb, "ARIMA(3,1,2)"),
  "ARIMA(3,1,3)"             = safe_arima(tlb$Births, c(3,1,3), xreg_tlb, "ARIMA(3,1,3)")
))

if (length(tlb_candidates) == 0) stop("All TLB candidate models failed to fit.")

tlb_best <- select_best(tlb_candidates)

# ---- 1d. Diagnostics ------------------------------------------

cat("--- Residual Diagnostics ---\n")
checkresiduals(tlb_best$fit)

lb_tlb <- Box.test(residuals(tlb_best$fit), lag = 12, type = "Ljung-Box")
cat("Ljung-Box p =", round(lb_tlb$p.value, 4))
cat(if (lb_tlb$p.value > 0.05) " => Residuals OK (white noise)\n"
    else                        " => WARNING: residual autocorrelation detected\n")

# ---- 1e. Fitted vs Actual Plot --------------------------------

tlb$Fitted <- as.numeric(fitted(tlb_best$fit))

print(
  ggplot(tlb, aes(x = Year)) +
    geom_line(aes(y = Births, colour = "Actual"), linewidth = 1.2) +
    geom_line(aes(y = Fitted, colour = "Fitted"), linewidth = 1, linetype = "dashed") +
    scale_y_continuous(labels = scales::comma) +
    labs(title = paste("TLB — Actual vs Fitted:", tlb_best$name),
         y = "Total Live Births", colour = NULL) +
    theme_minimal()
)

# ---- 1f. Forecast (10-year horizon) ----------------------------

tlb_future_years  <- (max(tlb$Year) + 1):(max(tlb$Year) + 10)
tlb_future_zodiac <- factor(zodiac_year(tlb_future_years), levels = levels(tlb$Zodiac))
tlb_future_xreg   <- model.matrix(~ Zodiac,
                                  data = data.frame(Zodiac = tlb_future_zodiac))[, -1]

tlb_fc <- forecast(tlb_best$fit, xreg = tlb_future_xreg, h = length(tlb_future_years))

plot(tlb_fc,
     main = paste("TLB Forecast —", tlb_best$name),
     ylab = "Total Live Births")

tlb_fc_df <- data.frame(
  Year     = tlb_future_years,
  Zodiac   = as.character(tlb_future_zodiac),
  Forecast = round(tlb_fc$mean),
  Lo80     = round(tlb_fc$lower[, 1]),
  Hi80     = round(tlb_fc$upper[, 1]),
  Lo95     = round(tlb_fc$lower[, 2]),
  Hi95     = round(tlb_fc$upper[, 2])
)

cat("\n=== TLB Forecast Table ===\n")
print(tlb_fc_df, row.names = FALSE)


# ============================================================
#  PART 2 — TOTAL FERTILITY RATE (TFR)
# ============================================================

cat("\n", strrep("=", 60), "\n")
cat(" PART 2: TOTAL FERTILITY RATE\n")
cat(strrep("=", 60), "\n")

# ---- 2a. Data Cleaning ----------------------------------------

tfr_row  <- raw[raw$DataSeries == "TotalFertilityRate(TFR)(PerFemale)", ]
years_tfr <- as.numeric(names(tfr_row)[-1])
vals_tfr  <- as.numeric(tfr_row[1, -1])

tfr <- data.frame(Year = years_tfr, TFR = vals_tfr) %>%
  filter(Year >= 1960, Year <= 2012) %>%
  arrange(Year) %>%
  filter(!is.na(TFR), !is.infinite(TFR))

tfr$Zodiac <- factor(zodiac_year(tfr$Year), levels = zodiacs)

cat("TFR dataset:", nrow(tfr), "observations |",
    min(tfr$Year), "-", max(tfr$Year), "\n")

# ---- 2b. Build Zodiac Regressor Matrix ------------------------

xreg_tfr <- model.matrix(~ Zodiac, data = tfr)[, -1]

# ---- 2c. Model Selection (ARIMA candidates, d = 1) ------------

cat("\n--- Fitting TFR Candidates ---\n")

tfr_candidates <- Filter(Negate(is.null), list(
  "ARIMA(0,1,0)" = safe_arima(tfr$TFR, c(0,1,0), xreg_tfr, "ARIMA(0,1,0)"),
  "ARIMA(1,1,0)" = safe_arima(tfr$TFR, c(1,1,0), xreg_tfr, "ARIMA(1,1,0)"),
  "ARIMA(0,1,1)" = safe_arima(tfr$TFR, c(0,1,1), xreg_tfr, "ARIMA(0,1,1)"),
  "ARIMA(1,1,1)" = safe_arima(tfr$TFR, c(1,1,1), xreg_tfr, "ARIMA(1,1,1)"),
  "ARIMA(2,1,0)" = safe_arima(tfr$TFR, c(2,1,0), xreg_tfr, "ARIMA(2,1,0)"),
  "ARIMA(2,1,1)" = safe_arima(tfr$TFR, c(2,1,1), xreg_tfr, "ARIMA(2,1,1)"),
  "ARIMA(1,1,2)" = safe_arima(tfr$TFR, c(1,1,2), xreg_tfr, "ARIMA(1,1,2)")
))

if (length(tfr_candidates) == 0) stop("All TFR candidate models failed to fit.")

tfr_best <- select_best(tfr_candidates)

# ---- 2d. Diagnostics ------------------------------------------

cat("--- Residual Diagnostics ---\n")
checkresiduals(tfr_best$fit)

lb_tfr <- Box.test(residuals(tfr_best$fit), lag = 12, type = "Ljung-Box")
cat("Ljung-Box p =", round(lb_tfr$p.value, 4))
cat(if (lb_tfr$p.value > 0.05) " => Residuals OK (white noise)\n"
    else                        " => WARNING: residual autocorrelation detected\n")

# ---- 2e. Fitted vs Actual Plot --------------------------------

tfr$Fitted <- as.numeric(fitted(tfr_best$fit))

print(
  ggplot(tfr, aes(x = Year)) +
    geom_line(aes(y = TFR,    colour = "Actual"), linewidth = 1.2) +
    geom_line(aes(y = Fitted, colour = "Fitted"), linewidth = 1, linetype = "dashed") +
    labs(title = paste("TFR — Actual vs Fitted:", tfr_best$name),
         y = "Total Fertility Rate", colour = NULL) +
    theme_minimal()
)

# ---- 2f. Forecast (2013–2025) ---------------------------------

tfr_future_years  <- 2013:2025
tfr_future_zodiac <- factor(zodiac_year(tfr_future_years), levels = levels(tfr$Zodiac))
tfr_future_xreg   <- model.matrix(~ Zodiac,
                                  data = data.frame(Zodiac = tfr_future_zodiac))[, -1]

tfr_fc <- forecast(tfr_best$fit, xreg = tfr_future_xreg, h = length(tfr_future_years))

plot(tfr_fc,
     main = paste("TFR Forecast —", tfr_best$name),
     ylab = "Total Fertility Rate")

tfr_fc_df <- data.frame(
  Year     = tfr_future_years,
  Zodiac   = as.character(tfr_future_zodiac),
  Forecast = round(tfr_fc$mean, 3),
  Lo80     = round(tfr_fc$lower[, 1], 3),
  Hi80     = round(tfr_fc$upper[, 1], 3),
  Lo95     = round(tfr_fc$lower[, 2], 3),
  Hi95     = round(tfr_fc$upper[, 2], 3)
)

cat("\n=== TFR Forecast Table ===\n")
print(tfr_fc_df, row.names = FALSE)

cat("\n", strrep("=", 60), "\n")
cat(" DONE\n")
cat(strrep("=", 60), "\n")
library(readxl)
library(ggplot2)
library(dplyr)
library(forecast)
library(tseries)

# ================== 1. DATA IMPORT & PREPARATION ==================

data <- read_excel("M810091.xlsx", sheet = "M810091")

# Extract TotalLive-Births (Number)
births_row <- data[grep("TotalLive-Births\\(Number\\)", data$DataSeries), ]

years  <- as.numeric(names(births_row)[-1])
values <- as.numeric(births_row[1, -1])

df <- data.frame(Year = years, Births = values)

# Filter to 1977–2012 (rows with data) and remove NAs
df <- df %>%
  filter(Year >= 1977 & Year <= 2013) %>%
  arrange(Year) %>%
  filter(!is.na(Births) & !is.infinite(Births))

# Chinese Zodiac
zodiacs <- c("Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
             "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig")

df$Zodiac <- factor(zodiacs[((df$Year - 2020) %% 12) + 1])

cat("Dataset ready:", nrow(df), "observations\n")
cat("Year range:", min(df$Year), "-", max(df$Year), "\n")

# ================== 2. EXPLORATORY ANALYSIS ==================

ggplot(df, aes(x = Year, y = Births)) +
  geom_line(color = "steelblue", linewidth = 1.2) +
  geom_point(size = 1.5) +
  scale_y_continuous(labels = scales::comma) +
  ggtitle("Singapore Total Live-Births (Number)") +
  ylab("Total Live Births") +
  theme_minimal()

ggplot(df, aes(x = Zodiac, y = Births)) +
  geom_boxplot(fill = "lightblue") +
  geom_jitter(width = 0.2, alpha = 0.6) +
  scale_y_continuous(labels = scales::comma) +
  ggtitle("Live Births Distribution by Chinese Zodiac Year") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ================== 3. STATIONARITY CHECK ==================

cat("\n=== ADF Test (Original Series) ===\n")
print(adf.test(df$Births))

cat("\n=== ADF Test (1st Difference) ===\n")
print(adf.test(diff(df$Births)))

par(mfrow = c(2, 2))

acf(df$Births,
    main = "ACF - Original Live Births",
    lag.max = 25)

pacf(df$Births,
     main = "PACF - Original Live Births",
     lag.max = 25)

acf(diff(df$Births),
    main = "ACF - 1st Differenced",
    lag.max = 25)

pacf(diff(df$Births),
     main = "PACF - 1st Differenced",
     lag.max = 25)

par(mfrow = c(1, 1))

# ================== 4. LINEAR REGRESSION BASELINE ==================

model_base   <- lm(Births ~ Year, data = df)
model_zodiac <- lm(Births ~ Year + Zodiac, data = df)

cat("\n=== Linear Regression Comparison ===\n")
summary(model_base)
summary(model_zodiac)

anova(model_base, model_zodiac)
print(AIC(model_base, model_zodiac))

df$Pred_Base   <- predict(model_base)
df$Pred_Zodiac <- predict(model_zodiac)

ggplot(df, aes(x = Year)) +
  geom_line(aes(y = Births,      colour = "Actual"),       linewidth = 1.2) +
  geom_line(aes(y = Pred_Base,   colour = "Base Model"),   linewidth = 1, linetype = "dashed") +
  geom_line(aes(y = Pred_Zodiac, colour = "Zodiac Model"), linewidth = 1, linetype = "dotted") +
  scale_y_continuous(labels = scales::comma) +
  labs(title    = "Live Births Prediction Comparison",
       subtitle = "Base Regression vs Zodiac-Enhanced Regression",
       x = "Year", y = "Total Live Births", colour = "Legend") +
  theme_minimal()

# ================== 5. ARIMA CANDIDATE MODELS ==================
# We always start with ARIMA(1,1,2) + Zodiac as the reference model,
# then compare against all candidates. The best by AIC is chosen.

xreg <- model.matrix(~ Zodiac, data = df)[, -1]

# Safely fit a model; returns NULL on failure (convergence, invertibility, etc.)
safe_arima <- function(y, order, xreg = NULL, label = "") {
  tryCatch(
    {
      fit <- Arima(y, order = order, xreg = xreg)
      cat("  [OK]", label, "| AIC =", round(AIC(fit), 2), "\n")
      fit
    },
    error   = function(e) { cat("  [SKIP]", label, "- Error:", conditionMessage(e), "\n");   NULL },
    warning = function(w) { cat("  [WARN]", label, "- Warning:", conditionMessage(w), "\n"); NULL }
  )
}

cat("\n=== Fitting ARIMA Candidates ===\n")

# Reference model from zodiacCBR — always fitted first
# Extended candidate grid covers p = 0..3, q = 0..3 with d = 1
# Each model is wrapped in safe_arima so failures are skipped gracefully

candidates_raw <- list(
  
  # ---- Reference ----
  "ARIMA(1,1,2) [reference]"  = safe_arima(df$Births, c(1,1,2), xreg, "ARIMA(1,1,2) [reference]"),
  
  # ---- Simple differencing ----
  "ARIMA(0,1,0)"              = safe_arima(df$Births, c(0,1,0), xreg, "ARIMA(0,1,0)"),
  
  # ---- Pure AR ----
  "ARIMA(1,1,0)"              = safe_arima(df$Births, c(1,1,0), xreg, "ARIMA(1,1,0)"),
  "ARIMA(2,1,0)"              = safe_arima(df$Births, c(2,1,0), xreg, "ARIMA(2,1,0)"),
  "ARIMA(3,1,0)"              = safe_arima(df$Births, c(3,1,0), xreg, "ARIMA(3,1,0)"),
  
  # ---- Pure MA ----
  "ARIMA(0,1,1)"              = safe_arima(df$Births, c(0,1,1), xreg, "ARIMA(0,1,1)"),
  "ARIMA(0,1,2)"              = safe_arima(df$Births, c(0,1,2), xreg, "ARIMA(0,1,2)"),
  "ARIMA(0,1,3)"              = safe_arima(df$Births, c(0,1,3), xreg, "ARIMA(0,1,3)"),
  
  # ---- ARMA mixed ----
  "ARIMA(1,1,1)"              = safe_arima(df$Births, c(1,1,1), xreg, "ARIMA(1,1,1)"),
  "ARIMA(1,1,3)"              = safe_arima(df$Births, c(1,1,3), xreg, "ARIMA(1,1,3)"),
  "ARIMA(2,1,1)"              = safe_arima(df$Births, c(2,1,1), xreg, "ARIMA(2,1,1)"),
  "ARIMA(2,1,2)"              = safe_arima(df$Births, c(2,1,2), xreg, "ARIMA(2,1,2)"),
  "ARIMA(2,1,3)"              = safe_arima(df$Births, c(2,1,3), xreg, "ARIMA(2,1,3)"),
  "ARIMA(3,1,1)"              = safe_arima(df$Births, c(3,1,1), xreg, "ARIMA(3,1,1)"),
  "ARIMA(3,1,2)"              = safe_arima(df$Births, c(3,1,2), xreg, "ARIMA(3,1,2)"),
  "ARIMA(3,1,3)"              = safe_arima(df$Births, c(3,1,3), xreg, "ARIMA(3,1,3)")
)

# Drop any models that failed to fit
candidates <- Filter(Negate(is.null), candidates_raw)

if (length(candidates) == 0) stop("All candidate models failed to fit.")

# ================== 6. MODEL SELECTION ==================


aic_table <- sapply(candidates, AIC)

cat("\n=== AIC Comparison Table ===\n")
aic_df <- data.frame(Model = names(aic_table), AIC = round(aic_table, 2))
aic_df <- aic_df[order(aic_df$AIC), ]
print(aic_df, row.names = FALSE)

# Always report what ARIMA(1,1,2) gave
ref_name <- "ARIMA(1,1,2) [reference]"
if (ref_name %in% names(aic_table)) {
  cat("\nReference ARIMA(1,1,2) AIC:", round(aic_table[ref_name], 2), "\n")
} else {
  cat("\nNote: Reference ARIMA(1,1,2) failed to fit and was skipped.\n")
}

best_name <- names(which.min(aic_table))
best_fit  <- candidates[[best_name]]

cat("\n=== Best Model Selected ===\n")
cat("Model:", best_name, "\n")
cat("AIC  :", round(AIC(best_fit), 2), "\n\n")

summary(best_fit)

# ================== 7. DIAGNOSTICS ==================

checkresiduals(best_fit)

par(mfrow = c(1, 2))

acf(residuals(best_fit),  main = "Best Model - Residuals ACF")
pacf(residuals(best_fit), main = "Best Model - Residuals PACF")

par(mfrow = c(1, 1))

lb_test <- Box.test(residuals(best_fit), lag = 12, type = "Ljung-Box")
cat("\n=== Ljung-Box Test ===\n")
print(lb_test)

if (lb_test$p.value > 0.05) {
  cat("Residuals appear white noise (p > 0.05). Model is adequate.\n")
} else {
  cat("Warning: residuals show autocorrelation (p <= 0.05). Consider further refinement.\n")
}

# ================== 8. FITTED VS ACTUAL ==================

df$Fitted <- as.numeric(fitted(best_fit))

ggplot(df, aes(x = Year)) +
  geom_line(aes(y = Births, colour = "Actual"),  linewidth = 1.2) +
  geom_line(aes(y = Fitted, colour = "Fitted"),  linewidth = 1, linetype = "dashed") +
  scale_y_continuous(labels = scales::comma) +
  ggtitle(paste("Actual vs Fitted —", best_name)) +
  ylab("Total Live Births") +
  theme_minimal()

# ================== 9. FORECASTING ==================

future_years  <- (max(df$Year) + 1):(max(df$Year) + 10)
future_zodiac <- zodiacs[((future_years - 2020) %% 12) + 1]

future_df <- data.frame(
  Zodiac = factor(future_zodiac, levels = levels(df$Zodiac))
)

future_xreg <- model.matrix(~ Zodiac, data = future_df)[, -1]

fc <- forecast(best_fit,
               xreg = future_xreg,
               h    = length(future_years))

plot(fc,
     main = paste("Live Births Forecast —", best_name),
     ylab = "Total Live Births")

# Tidy forecast table
fc_df <- data.frame(
  Year      = future_years,
  Forecast  = round(fc$mean),
  Lower_80  = round(fc$lower[, 1]),
  Upper_80  = round(fc$upper[, 1]),
  Lower_95  = round(fc$lower[, 2]),
  Upper_95  = round(fc$upper[, 2])
)

cat("\n=== Forecast Table ===\n")
print(fc_df, row.names = FALSE)

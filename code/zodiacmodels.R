library(readxl)
library(ggplot2)
library(dplyr)
library(forecast)

# ================== 1. DATA IMPORT & PREPARATION ==================
data <- read_excel("M810091.xlsx", sheet = "M810091")

# Extract TFR
tfr_row <- data[data$DataSeries == "TotalFertilityRate(TFR)(PerFemale)", ]
years   <- as.numeric(names(tfr_row)[-1])
values  <- as.numeric(tfr_row[1, -1])

df <- data.frame(Year = years, TFR = values)
df <- df %>% filter(Year >= 1960 & Year <= 2012) %>% arrange(Year)

# Chinese Zodiac
zodiacs <- c("Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
             "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig")

df$Zodiac <- factor(zodiacs[((df$Year - 2020) %% 12) + 1])

cat("Dataset ready:", nrow(df), "observations (1960-2012)\n")

# ================== 2. EXPLORATORY ANALYSIS ==================
ggplot(df, aes(x = Year, y = TFR)) +
  geom_line(color = "steelblue", size = 1) + 
  geom_point() +
  ggtitle("Singapore Total Fertility Rate (1960-2012)") +
  theme_minimal()

ggplot(df, aes(x = Zodiac, y = TFR)) +
  geom_boxplot(fill = "lightblue") +
  geom_jitter(width = 0.2, alpha = 0.5) +
  ggtitle("TFR Distribution by Chinese Zodiac Year") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Key ACF/PACF plots 
par(mfrow = c(2, 2))
acf(df$TFR, main = "ACF - Original TFR", lag.max = 25)
pacf(df$TFR, main = "PACF - Original TFR", lag.max = 25)
acf(diff(df$TFR), main = "ACF - 1st Differenced TFR", lag.max = 25)
pacf(diff(df$TFR), main = "PACF - 1st Differenced TFR", lag.max = 25)

# ================== 3. LINEAR REGRESSION ==================
model_base   <- lm(TFR ~ Year, data = df)
model_zodiac <- lm(TFR ~ Year + Zodiac, data = df)

cat("\n=== Linear Regression Comparison ===\n")
summary(model_base)
summary(model_zodiac)
anova(model_base, model_zodiac)
print(AIC(model_base, model_zodiac))

# ================== 4. ARIMA with Zodiac Regressors ==================
xreg <- model.matrix(~ Zodiac, data = df)[, -1]   # Dummy variables

# Manual candidate models (simple to complex)
candidates <- list(
  "Diff only + Zodiac"     = Arima(df$TFR, order = c(0,1,0), xreg = xreg),
  "AR(1) + Zodiac"         = Arima(df$TFR, order = c(1,1,0), xreg = xreg),
  "MA(1) + Zodiac"         = Arima(df$TFR, order = c(0,1,1), xreg = xreg),
  "ARMA(1,1) + Zodiac"     = Arima(df$TFR, order = c(1,1,1), xreg = xreg),
  "AR(2) + Zodiac"         = Arima(df$TFR, order = c(2,1,0), xreg = xreg),
  "ARMA(2,1) + Zodiac"     = Arima(df$TFR, order = c(2,1,1), xreg = xreg),
  "ARMA(1,2) + Zodiac"     = Arima(df$TFR, order = c(1,1,2), xreg = xreg)
)

# Compare all models by AIC
aic_table <- sapply(candidates, AIC)
print(aic_table)

# Select best model (lowest AIC)
best_name <- names(which.min(aic_table))
best_fit  <- candidates[[best_name]]

cat("\n=== Best Model Selected ===\n")
print(best_name)
summary(best_fit)

# ================== 5. DIAGNOSTICS ==================
checkresiduals(best_fit)

# Extra residual checks
par(mfrow = c(1, 2))
acf(residuals(best_fit), main = "Residuals ACF")
pacf(residuals(best_fit), main = "Residuals PACF")

Box.test(residuals(best_fit), lag = 12, type = "Ljung-Box")

# Fitted vs Actual
df$Fitted <- fitted(best_fit)
ggplot(df, aes(Year)) +
  geom_line(aes(y = TFR, color = "Actual")) +
  geom_line(aes(y = Fitted, color = "Fitted")) +
  ggtitle(paste("Actual vs Fitted -", best_name)) +
  theme_minimal()

# ================== 6. FORECASTING ==================
future_years <- 2013:2025
future_zodiac <- zodiacs[((future_years - 2020) %% 12) + 1]
future_df <- data.frame(Zodiac = factor(future_zodiac, levels = levels(df$Zodiac)))

future_xreg <- model.matrix(~ Zodiac, data = future_df)[, -1]

fc <- forecast(best_fit, xreg = future_xreg, h = length(future_years))

plot(fc, main = paste("TFR Forecast with Zodiac -", best_name))
print(fc)
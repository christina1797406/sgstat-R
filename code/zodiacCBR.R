library(readxl)
library(ggplot2)
library(dplyr)
library(forecast)

# ================== 1. DATA IMPORT & PREPARATION ==================
data <- read_excel("M810091.xlsx", sheet = "M810091")

# Extract Crude Birth Rate
cbr_row <- data[grep("CrudeBirthRate", data$DataSeries), ]

years   <- as.numeric(names(cbr_row)[-1])
values  <- as.numeric(cbr_row[1, -1])

df <- data.frame(Year = years, CBR = values)

# Filter years + remove missing values
df <- df %>%
  filter(Year >= 1960 & Year <= 2012) %>%
  arrange(Year) %>%
  filter(!is.na(CBR) & !is.infinite(CBR))

# Chinese Zodiac
zodiacs <- c("Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake",
             "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig")

df$Zodiac <- factor(zodiacs[((df$Year - 2020) %% 12) + 1])

cat("Dataset ready:", nrow(df), "observations (1960-2012)\n")

# ================== 2. EXPLORATORY ANALYSIS ==================

# Time Series Plot
ggplot(df, aes(x = Year, y = CBR)) +
  geom_line(color = "darkred", linewidth = 1.2) +
  geom_point() +
  ggtitle("Singapore Crude Birth Rate (1960-2012)") +
  ylab("CBR per 1,000 residents") +
  theme_minimal()

# Zodiac Comparison
ggplot(df, aes(x = Zodiac, y = CBR)) +
  geom_boxplot(fill = "lightcoral") +
  geom_jitter(width = 0.2, alpha = 0.6) +
  ggtitle("CBR Distribution by Chinese Zodiac Year") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ================== 3. ACF / PACF ==================
par(mfrow = c(2, 2))

acf(df$CBR,
    main = "ACF - Original CBR",
    lag.max = 25)

pacf(df$CBR,
     main = "PACF - Original CBR",
     lag.max = 25)

acf(diff(df$CBR),
    main = "ACF - 1st Differenced CBR",
    lag.max = 25)

pacf(diff(df$CBR),
     main = "PACF - 1st Differenced CBR",
     lag.max = 25)

# ================== 4. LINEAR REGRESSION ==================

model_base   <- lm(CBR ~ Year, data = df)
model_zodiac <- lm(CBR ~ Year + Zodiac, data = df)

cat("\n=== Linear Regression Comparison ===\n")

summary(model_base)
summary(model_zodiac)

anova(model_base, model_zodiac)

print(AIC(model_base, model_zodiac))

# ================== 5. PREDICTIONS ==================

df$Pred_Base   <- predict(model_base)
df$Pred_Zodiac <- predict(model_zodiac)

ggplot(df, aes(x = Year)) +
  
  # Actual
  geom_line(aes(y = CBR, colour = "Actual CBR"),
            linewidth = 1.2) +
  
  # Base model
  geom_line(aes(y = Pred_Base,
                colour = "Base Model"),
            linewidth = 1,
            linetype = "dashed") +
  
  # Zodiac model
  geom_line(aes(y = Pred_Zodiac,
                colour = "Zodiac Model"),
            linewidth = 1,
            linetype = "dotted") +
  
  labs(
    title = "CBR Prediction Comparison",
    subtitle = "Base Regression vs Zodiac-Enhanced Regression",
    x = "Year",
    y = "Crude Birth Rate",
    colour = "Legend"
  ) +
  
  theme_minimal()

# ================== 6. RESIDUAL COMPARISON ==================

par(mfrow = c(1, 2))

plot(model_base$fitted.values,
     resid(model_base),
     main = "Base Model Residuals",
     xlab = "Fitted Values",
     ylab = "Residuals",
     col = "blue",
     pch = 16)

abline(h = 0,
       col = "red",
       lwd = 2)

plot(model_zodiac$fitted.values,
     resid(model_zodiac),
     main = "Zodiac Model Residuals",
     xlab = "Fitted Values",
     ylab = "Residuals",
     col = "darkgreen",
     pch = 16)

abline(h = 0,
       col = "red",
       lwd = 2)

par(mfrow = c(1,1))

# ================== 7. R² & AIC COMPARISON ==================

comparison <- data.frame(
  Model = c("Base", "Zodiac"),
  
  R_Squared = c(summary(model_base)$r.squared,
                summary(model_zodiac)$r.squared),
  
  AIC = c(AIC(model_base),
          AIC(model_zodiac))
)

print(comparison)

# R² Plot
ggplot(comparison,
       aes(x = Model,
           y = R_Squared,
           fill = Model)) +
  
  geom_bar(stat = "identity") +
  
  labs(
    title = "R² Comparison",
    y = "R² Value"
  ) +
  
  theme_minimal()

# AIC Plot
ggplot(comparison,
       aes(x = Model,
           y = AIC,
           fill = Model)) +
  
  geom_bar(stat = "identity") +
  
  labs(
    title = "AIC Comparison",
    y = "AIC"
  ) +
  
  theme_minimal()

# ================== 8. ARIMA WITH ZODIAC REGRESSORS ==================

xreg <- model.matrix(~ Zodiac, data = df)[, -1]

# Candidate models
candidates <- list(
  
  "Diff only + Zodiac" =
    Arima(df$CBR,
          order = c(0,1,0),
          xreg = xreg),
  
  "AR(1) + Zodiac" =
    Arima(df$CBR,
          order = c(1,1,0),
          xreg = xreg),
  
  "MA(1) + Zodiac" =
    Arima(df$CBR,
          order = c(0,1,1),
          xreg = xreg),
  
  "ARMA(1,1) + Zodiac" =
    Arima(df$CBR,
          order = c(1,1,1),
          xreg = xreg),
  
  "AR(2) + Zodiac" =
    Arima(df$CBR,
          order = c(2,1,0),
          xreg = xreg),
  
  "ARMA(2,1) + Zodiac" =
    Arima(df$CBR,
          order = c(2,1,1),
          xreg = xreg),
  
  "ARMA(1,2) + Zodiac" =
    Arima(df$CBR,
          order = c(1,1,2),
          xreg = xreg)
)

# Compare AIC
aic_table <- sapply(candidates, AIC)

print(aic_table)

# Best model
best_name <- names(which.min(aic_table))
best_fit  <- candidates[[best_name]]

cat("\n=== Best Model Selected ===\n")

print(best_name)

summary(best_fit)

# ================== 9. DIAGNOSTICS ==================

checkresiduals(best_fit)

par(mfrow = c(1, 2))

acf(residuals(best_fit),
    main = "Residuals ACF")

pacf(residuals(best_fit),
     main = "Residuals PACF")

Box.test(residuals(best_fit),
         lag = 12,
         type = "Ljung-Box")

# ================== 10. FITTED VS ACTUAL ==================

df$Fitted <- fitted(best_fit)

ggplot(df, aes(Year)) +
  
  geom_line(aes(y = CBR,
                color = "Actual")) +
  
  geom_line(aes(y = Fitted,
                color = "Fitted")) +
  
  ggtitle(paste("Actual vs Fitted -", best_name)) +
  
  ylab("Crude Birth Rate") +
  
  theme_minimal()

# ================== 11. FORECASTING ==================

future_years <- 2013:2025

future_zodiac <- zodiacs[((future_years - 2020) %% 12) + 1]

future_df <- data.frame(
  Zodiac = factor(future_zodiac,
                  levels = levels(df$Zodiac))
)

future_xreg <- model.matrix(~ Zodiac,
                            data = future_df)[, -1]

fc <- forecast(best_fit,
               xreg = future_xreg,
               h = length(future_years))

plot(fc,
     main = paste("CBR Forecast with Zodiac -", best_name))

print(fc)
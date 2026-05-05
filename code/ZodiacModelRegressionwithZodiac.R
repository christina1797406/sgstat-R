library(readxl)
library(ggplot2)
library(tidyr) # maybe need to install these packages
library(dplyr)
library(forecast)
library(tseries)

# An important disclosure is that due to the way the data is tracked, >1980 will have less overall.
data <- read_excel("M810091.xlsx")


head(data)
str(data)


tfr_row <- data[data$DataSeries == "TotalFertilityRate(TFR)(PerFemale)", ]
tfr_values <- tfr_row[, -1]
years <- as.numeric(names(tfr_values))
values <- as.numeric(tfr_values[1, ])

keep <- years >= 1960 & years <= 2012

years_filtered <- years[keep]
values_filtered <- values[keep]


order_idx <- order(years_filtered)

years_filtered <- years_filtered[order_idx]
values_filtered <- values_filtered[order_idx]

zodiacs <- c(
  "Rat", "Ox", "Tiger", "Rabbit",
  "Dragon", "Snake", "Horse", "Goat",
  "Monkey", "Rooster", "Dog", "Pig"
)

zodiac_year <- zodiacs[((years_filtered - 2020) %% 12) + 1] # maps it out

# Final dataframe
df <- data.frame(
  Year = years_filtered,
  TFR = values_filtered,
  Zodiac = zodiac_year
)

df$Zodiac <- as.factor(df$Zodiac)

# plot(df, main = "Total Fertility Rate (1980+)")

model1 <- lm(TFR ~ Zodiac, data=df)
summary(model1)

model2 <- lm(TFR ~ Zodiac + Year, data=df)
summary(model2)

xreg <- model.matrix(~ Zodiac, data=df)[, -1]

fit <- Arima(df$TFR,
             order=c(1,1,1),
             xreg=xreg)

anova(model1, model2)

summary(fit)

head(df)

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

keep <- years >= 1980 # for better accuracy

years_filtered <- years[keep]
values_filtered <- values[keep]


order_idx <- order(years_filtered)

years_filtered <- years_filtered[order_idx]
values_filtered <- values_filtered[order_idx]

ts_data <- ts(values_filtered,
              start = min(years_filtered),
              frequency = 1)

plot(ts_data, main = "Total Fertility Rate (1980+)")

model <- auto.arima(ts_data)
summary(model)

forecast(model, h = 5)

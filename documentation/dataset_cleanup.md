# Dataset Cleanup in RStudio
This script demonstrates how to clean, transform and visualise population data (Total Fertility Rate and Total Live Births) from 1960-2025 in **RStudio**.
---

## Table of Contents

1. [Install Packages](#1-install-packages-only-once)  
2. [Load Libraries](#2-load-libraries)  
3. [Load CSV](#3-load-csv)  
4. [Reshape Data](#4-reshape-the-data-from-wide-format-to-long-format-for-easier-analysis)  
5. [Filter Series](#5-filter-selection-for-series)  
6. [Split into Training & Testing](#6-split-into-training-and-testing-subsets)  
7. [Save Clean Data](#7-save-as-csv)  
8. [Visualisation](#8-visualisation)  

---
## 1. Install packages (only once)
```r
install.packages(c("tidyverse", "lubridate", "forecast", "tseries", "janitor"))
```

### Load libraries
```r
library(tidyverse) # includes readr, dplyr, tidyr
library(janitor)
# library(lubridate)
# library(forecast)
# library(tseries)
```

## 2. Load CSV
### Remove metadata (actual data between rows 10-26)
```r
data <- read_csv("~/2025/projects/ict-s1-2026/sgstat-R/raw_data/1960-2025.csv",
skip = 9, 
n_max = 17,
col_names = TRUE)
```

### Clean column names for easier access
```r
data <- data %>%
clean_names() 
```
### Convert all columns except 'data_series' to numeric
```r
data <- data %>%
mutate(across(-data_series, ~ as.numeric(.)))
```

## 3. Reshape the data from wide format to long format for easier analysis
```r
data_long <- data %>%
pivot_longer(cols = -data_series, 
    names_to = "year", 
    values_to = "value"
    ) %>%
mutate(year = as.numeric(str_remove(year, "x"))) # Remove 'x' prefix if any
```

### Print summary to check
```r
glimpse(data_long)
summary(data_long)
```     

### Check in for missing values
```r
sum(is.na(data_long$value)) # 128 NA's
```

## 4. Filter selection for series
### Total Fertility Rate
```r
tfr_data <- data_long %>%
filter(data_series == "Total Fertility Rate (TFR) (Per Female)") %>%
arrange(year)
summary(tfr_data)
```
### Total Live Births
```r
tlb_data <- data_long %>%
filter(data_series == "Total Live-Births (Number)") %>%
arrange(year)

summary(tlb_data)
head(tlb_data)
```

## 5. Split into training and testing subsets
```r
train_years <- 1960:2012
test_years <- 2013:2025

tfr_train <- tfr_data %>% filter(year %in% train_years)
tfr_test <- tfr_data %>% filter(year %in% test_years)

tlb_train <- tlb_data %>% filter(year %in% train_years)
tlb_test <- tlb_data %>% filter(year %in% test_years)
```

### Save as CSV
```r
write_csv(tfr_train, "~/2025/projects/ict-s1-2026/sgstat-R/clean_data/tfr_train.csv")
write_csv(tfr_test,  "~/2025/projects/ict-s1-2026/sgstat-R/clean_data/tfr_test.csv")

write_csv(tlb_train, "~/2025/projects/ict-s1-2026/sgstat-R/clean_data/tlb_train.csv")
write_csv(tlb_test,  "~/2025/projects/ict-s1-2026/sgstat-R/clean_data/tlb_test.csv")

getwd() # Check current working directory
list.files()
```
## 6. Visualisation
### Converst to time-series objects
```r
tfr_ts <- ts(tfr_train$value, start = min(tfr_train$year), end = max(tfr_train$year), frequency = 1)
tlb_ts <- ts(tlb_train$value, start = min(tlb_train$year), end = max(tlb_train$year), frequency = 1)
```

### Check the structure of the time-series objects
```r
str(tfr_ts)
str(tlb_ts)
```

### Plot the time-series data
```r
plot(tfr_ts, main = "Total Fertility Rate (1960-2012)", xlab = "Year", ylab = "TFR")
plot(tlb_ts, main = "Total Live Births (1960-2012)", xlab = "Year", ylab = "TLB")
```


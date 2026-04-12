# Data Preprocessing Script

install.packages(c("tidyverse", "lubridate", "forecast", "tseries", "janitor"))

# Load libraries
library(tidyverse) # includes readr, dplyr, tidyr
library(janitor)

# Load data, clean names
data <- read_csv("data/raw_data/1960-2025.csv",
                 skip = 9,
                 n_max = 17,
                 col_names = TRUE) %>%
  clean_names()

# Convert columns except 'data_series' to numeric
data <- data %>%
  mutate(across(-data_series, as.numeric))

# Reshape data from wide to long format
data_long <- data %>%
  pivot_longer(
    cols = -data_series,
    names_to = "year",
    values_to = "value"
  ) %>%
  mutate(year = as.numeric(str_remove(year, "x"))) # Remove 'x' prefix

## Print summary to check
# glimpse(data_long)
# summary(data_long)

## Check in for missing values
# sum(is.na(data_long$value)) # 128 NA's

# Total Fertility Rate
tfr_data <- data_long %>%
  filter(data_series == "Total Fertility Rate (TFR) (Per Female)") %>%
  arrange(year) %>%
  rename(TFR = value)

# Total Live Births
tlb_data <- data_long %>%
  filter(data_series == "Total Live-Births (Number)") %>%
  arrange(year) %>%
  rename(TLB = value)

# Train-test split
train_years <- 1960:2012
test_years  <- 2013:2025

tfr_train <- tfr_data %>% filter(year %in% train_years)
tfr_test  <- tfr_data %>% filter(year %in% test_years)

tlb_train <- tlb_data %>% filter(year %in% train_years)
tlb_test  <- tlb_data %>% filter(year %in% test_years)

# Save processed data
write_csv(tfr_train, "data/clean_data/tfr_train.csv")
write_csv(tfr_test,  "data/clean_data/tfr_test.csv")

write_csv(tlb_train, "data/clean_data/tlb_train.csv")
write_csv(tlb_test,  "data/clean_data/tlb_test.csv")

cat("Preprocessing complete.\n")
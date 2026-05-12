# =========================================================
# TIME SERIES DATA CLEANING & PREPARATION
# =========================================================

# Load libraries
library(readr)
library(dplyr)
library(tidyr)
library(stringr)

# =========================================================
# 1. IMPORT DATA
# =========================================================

raw <- read.csv(
  "raw_data/1960-2025.csv",
  skip = 9,
  stringsAsFactors = FALSE,
  check.names = TRUE
)

# =========================================================
# 2. CONVERT WIDE FORMAT TO LONG FORMAT
# =========================================================

clean_long <- raw %>%
  mutate(across(starts_with("X"), as.character)) %>%
  pivot_longer(
    cols = starts_with("X"),
    names_to = "year",
    values_to = "value"
  ) %>%
  mutate(
    year = as.numeric(str_remove(year, "X")),
    value = na_if(value, "na"),
    value = as.numeric(gsub(",", "", value))
  )

# =========================================================
# 3. FILTER VARIABLES
# =========================================================

tfr_data <- clean_long %>%
  filter(Data.Series == "Total Fertility Rate (TFR) (Per Female)") %>%
  arrange(year) %>%
  select(year, TFR = value)

tlb_data <- clean_long %>%
  filter(Data.Series == "Total Live-Births (Number)") %>%
  arrange(year) %>%
  select(year, TLB = value)

# =========================================================
# 4. CLEAN DATA
# =========================================================

full_clean <- tfr_data %>%
  inner_join(tlb_data, by = "year") %>%
  filter(year >= 1960, year <= 2025)

train <- full_clean %>%
  filter(year >= 1960, year <= 2012)

test <- full_clean %>%
  filter(year >= 2013, year <= 2025)

dir.create("clean_data", showWarnings = FALSE)

# =========================================================
# 5. SPLIT DATA
# =========================================================

train_tfr <- tfr_data %>%
  filter(year >= 1960, year <= 2012)
test_tfr <- tfr_data %>%
  filter(year >= 2013, year <= 2025)

train_tlb <- tlb_data %>%
  filter(year >= 1960, year <= 2012)
test_tlb <- tlb_data %>%
  filter(year >= 2013, year <= 2025)

# =========================================================
# 6. EXPORT CLEAN DATA CSV FILES
# =========================================================

write.csv(full_clean, "clean_data/full_clean.csv", row.names = FALSE)
write.csv(train, "clean_data/train.csv", row.names = FALSE)
write.csv(test, "clean_data/test.csv", row.names = FALSE)

# =========================================================
# 7. EXPORT TFR AND TLB CSV FILES
# =========================================================

write.csv(train %>% select(year, TFR), "clean_data/tfr_train.csv", row.names = FALSE)
write.csv(test %>% select(year, TFR), "clean_data/tfr_test.csv", row.names = FALSE)

write.csv(train %>% select(year, TLB), "clean_data/tlb_train.csv", row.names = FALSE)
write.csv(test %>% select(year, TLB), "clean_data/tlb_test.csv", row.names = FALSE)

# =========================================================
# 8. PREPROCESSING COMPLETE
# =========================================================

cat("Preprocessing complete.\n")
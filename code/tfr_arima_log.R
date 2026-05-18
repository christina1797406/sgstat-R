# =========================================================
# FIND BEST ARIMA LOG-TRANSFORMED MODEL FOR TFR
# =========================================================

# =========================================================
# 1. IMPORT DATA
# =========================================================

train <- read.csv("clean_data/train.csv")

# =========================================================
# 2. CREATE TIME SERIES
# =========================================================

TFRa <- ts(train$TFR, start = 1960, frequency = 1)
log_TFRa <- log(TFRa)
plot(log_TFRa, main = "Log-Transformed TFR Series")
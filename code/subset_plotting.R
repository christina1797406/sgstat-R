# =========================================================
# CREATE AND SAVE TFRa & TLBa PLOTS
# =========================================================

# Load libraries
library(ggplot2)

# =========================================================
# 1. IMPORT DATA
# =========================================================

train <- read.csv("clean_data/train.csv")
test  <- read.csv("clean_data/test.csv")

dir.create("outputs/ts_plots", recursive = TRUE, showWarnings = FALSE)

# =========================================================
# 2. CREATE TIME SERIES OBJECTS
# =========================================================

TFRa <- ts(train$TFR, start = 1960, frequency = 1)
TLBa <- ts(train$TLB, start = 1960, frequency = 1)

# =========================================================
# 3. PLOT TFR
# =========================================================

png("outputs/ts_plots/TFRa_plot.png", res = 300, width = 2000, height = 1400)

plot(
  TFRa,
  main = "Total Fertility Rate (TFR) Time Series",
  xlab = "Year",
  ylab = "TFR",
  lwd = 2
)

grid()
dev.off()

# =========================================================
# 4. PLOT TLB
# =========================================================

png("outputs/ts_plots/TLBa_plot.png", res = 300, width = 2000, height = 1400)

plot(
  TLBa,
  main = "Total Live Births (TLB) Time Series",
  xlab = "Year",
  ylab = "Live Births",
  lwd = 2
)

grid()
dev.off()

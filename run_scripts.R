# Create output folders if not already there
dir.create("outputs", showWarnings = FALSE)
# dir.create("outputs/forecasts", recursive = TRUE, showWarnings = FALSE)
# dir.create("outputs/models", recursive = TRUE, showWarnings = FALSE)

# Run all R scripts
source("code/preprocessing.R")
source("code/subset_plotting.R")
source("code/tfr_arima.R")
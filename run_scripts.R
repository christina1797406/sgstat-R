# Create output folders if not already there
dir.create("outputs", showWarnings = FALSE)

# Run all R scripts
source("code/preprocessing.R")
source("code/subset_plotting.R")

# ARIMA modelling scripts
source("code/tfr_arima.R")
source("code/tfr_arima_model_validation.R")
# source("code/tfr_arima_15_2_0_validation.R")

# ARIMA log-transformation modelling scripts
# source("code/tfr_arima_log.R")

# Machine learning comparison models
source("code/model_ml.R")

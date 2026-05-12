# Create output folders if not already there
dir.create("outputs", showWarnings = FALSE)
dir.create("outputs/forecasts", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/models", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/plots", recursive = TRUE, showWarnings = FALSE)

# Run all R scripts
source("code/preprocessing.R")
source("code/model_arima-1-1-1.R")
source("code/model_log_arima-1-1-1.R")
source("code/model_arima.R")
source("code/model_ets.R")
source("code/model_ml.R")
source("code/create_comparison_table.R")

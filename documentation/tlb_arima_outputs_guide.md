# TLB ARIMA Files and Outputs Guide

This document explains where the Total Live Births (TLB) ARIMA code, results and output plots are stored, and how to run the files in the correct order.

## 1. Data Cleaning File

**File location:**

```r
code/rebuild_data.R
```

Run this file first:

```r
source("code/preprocessing.R")
```

This script rebuilds the cleaned dataset from the raw Singapore fertility dataset. It reshapes the original dataset, extracts the Total Fertility Rate (TFR) and Total Live Births (TLB) variables, and creates the training and testing datasets.

The cleaned files are saved in:

```
clean_data/
```

Important outputs include:

```
clean_data/full_clean.csv
clean_data/train.csv
clean_data/test.csv
clean_data/tfr_train.csv
clean_data/tfr_test.csv
clean_data/tlb_train.csv
clean_data/tlb_test.csv
```

## 2. TLB ARIMA Model Search

**File location:**

```r
code/tlb_arima_search.R
```

Run this file after rebuilding the data:

```r
source("code/tlb_arima_search.R")
```

This script tests multiple ARIMA models for the TLB time series. It compares different combinations of `p`, `d` and `q` values and records each model's AIC, Ljung-Box p-value, RMSE and MAE.

The purpose of this file is to identify possible candidate models that have:

- acceptable residual behaviour
- Ljung-Box p-value greater than 0.05
- reasonable AIC
- low forecast error on the testing dataset

The model search results are saved in:

```
outputs/tlb_arima_search_results.csv
```

## 3. TLB ARIMA Model Validation

**File location:**

```r
code/tlb_arima_model_validation.R
```

Run this file after the model search:

```r
source("code/tlb_arima_model_validation.R")
```

This script validates the shortlisted TLB ARIMA models. It generates forecast plots and residual diagnostic plots for the best candidate models.

The main candidate models currently include:

```
ARIMA(13,2,4)
ARIMA(17,2,0)
ARIMA(16,2,0)
ARIMA(14,1,3)
ARIMA(15,2,1)
```

The validation summary is saved in:

```
outputs/tlb_arima_validation_summary.csv
```

## 4. TLB Output Plots

The TLB plots are saved in:

```
outputs/plots/tlb/
```

This folder contains:

- actual vs forecasted plots
- residual ACF plots
- residual PACF plots

Example output files include:

```
tlb_m86_ARIMA_13_2_4_forecast.png
tlb_m86_ARIMA_13_2_4_residuals_acf.png
tlb_m86_ARIMA_13_2_4_residuals_pacf.png
```

These plots are used to visually assess model performance and residual behaviour.

## 5. Recommended Run Order

Run the scripts in this order:

```r
source("code/rebuild_data.R")
source("code/tlb_arima_search.R")
source("code/tlb_arima_model_validation.R")
```

## 6. Current Best TLB Model

The current preferred TLB model is:

```
ARIMA(13,2,4)
```

This model was selected because it achieved the lowest forecast error among the shortlisted models while still passing the Ljung-Box test threshold.

Current results:

```text
AIC = 961.13
Ljung-Box p-value = 0.052
RMSE = 3541.00
MAE = 2648.35
```

Although the Ljung-Box result is close to the 0.05 threshold, the model provides the best balance between acceptable residual diagnostics and forecast accuracy.

## 7. Notes

The residual ACF and PACF plots should be checked alongside the numerical results. A model should not be selected based on AIC alone. Forecast accuracy and white noise residuals are both important for selecting a suitable ARIMA model.

Some model warnings may appear during the search stage. These warnings should be reviewed, especially convergence warnings, because they may indicate that some model estimates are unstable. Models with strong warnings should be treated carefully and should not be selected purely because they have a good AIC or RMSE value.

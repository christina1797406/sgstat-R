# Singapore Birth and Fertility Forecasting

ICT Capstone Project, Group S1-2026-10

This repository contains the data cleaning, modelling code, output files, and documentation for the Singapore birth and fertility forecasting project. The project analyses historical Singapore fertility data and compares forecasting approaches for:

- **Total Fertility Rate (TFR)**
- **Total Live Births (TLB)**

The main workflow cleans the raw dataset, creates training and testing splits, runs ARIMA and SARIMA models, checks residual diagnostics, compares forecast accuracy, and stores output plots and result tables for the final report.

## Team Members

| Name | Student ID |
|---|---:|
| Brandon Ho | 1926054 |
| Christina Nguyen | 1797406 |
| Lara Grocke | 1802741 |
| Minh Quant Tran | 1897916 |
| Xinhai Li | 1881755 |

## Project Summary

The project investigates long-term fertility and birth patterns in Singapore using public demographic data from 1960 to 2025. The training period is 1960 to 2012 and the testing period is 2013 to 2025. The testing period is used to compare how well each model forecasts unseen data.

The main modelling approaches in this repository are:

- ARIMA models for TFR and TLB
- Corrected SARIMA models for TLB with a 12-year seasonal period
- Zodiac-related exploratory analysis
- Machine learning comparison models
- Literature and dataset documentation for report support

## Quick Start

Open the project in RStudio and set the working directory to the project root. The project root should contain folders such as `code`, `raw_data`, `clean_data`, `documentation`, `outputs`, and `processed_data`.

Run the preprocessing script first:

```r
source("code/preprocessing.R")
```

This rebuilds the cleaned data files in `clean_data/`.


## Data Cleaning

The main data cleaning file is:

```r
code/preprocessing.R
```

Run it with:

```r
source("code/preprocessing.R")
```

This script:

- imports the raw dataset from `raw_data/1960-2025.csv`
- reshapes the dataset from wide format into long format
- extracts TFR and TLB values
- cleans numeric formatting
- creates the training and testing datasets
- exports cleaned files into `clean_data/`

Expected split:

```text
Training set: 1960 to 2012
Testing set: 2013 to 2025
```

To check the cleaned data:

```r
train <- read.csv("clean_data/train.csv")
test <- read.csv("clean_data/test.csv")

head(train)
tail(train)
head(test)
tail(test)
```

## Main Code Files

### Data Preparation

| File | Purpose |
|---|---|
| `code/preprocessing.R` | Rebuilds cleaned TFR and TLB datasets from the raw Singapore fertility data. |
| `code/subset_plotting.R` | Creates basic TFR and TLB time series plots from the cleaned training data. |

### TFR Modelling

| File | Purpose |
|---|---|
| `code/tfr_arima.R` | Runs ARIMA model exploration for Total Fertility Rate. |
| `code/tfr_arima_model_validation.R` | Validates selected TFR ARIMA models and produces forecast outputs. |
| `code/tfr_residual_diagnostics.R` | Produces residual diagnostic plots for selected TFR ARIMA models. |
| `code/tfr-model-comparison.R` | Compares the best AIC and best RMSE TFR ARIMA models. |

### TLB Modelling

| File | Purpose |
|---|---|
| `code/tlb_arima_search.R` | Searches non-seasonal TLB ARIMA candidate models. |
| `code/tlb_arima_model_validation.R` | Validates the strongest TLB ARIMA candidates and creates forecast and residual plots. |
| `code/tlb_sarima_search.R` | Runs the corrected TLB SARIMA search using seasonal differencing with `D = 1` and period 12. |
| `code/tlb_sarima_model_validation.R` | Validates the strongest corrected TLB SARIMA models. |
| `code/tlb_compare_arima_sarima.R` | Compares the strongest TLB ARIMA and SARIMA models in one output table. |
| `code/tlb_sarima_selected_plots.R` | Generates report-ready plots for selected corrected SARIMA models. |

### Zodiac Analysis

| File | Purpose |
|---|---|
| `code/zodiacfinding.R` | Explores ARIMA and SARIMA model groups for Zodiac-related 12-year structure. |
| `code/zodiacmodels.R` | Tests Zodiac-enhanced model ideas for TFR. |
| `code/zodiacTLB.R` | Explores Zodiac effects for Total Live Births. |
| `code/zodiacCBR.R` | Explores Zodiac effects for Crude Birth Rate. |
| `code/TLBTFRZodiac.R` | Combined TFR, TLB, and Zodiac exploratory script. |
| `code/ZodiacModelRegressionwithZodiac.R` | Legacy Zodiac regression exploration. |
| `code/TotalFertlityRate1980.R` | Legacy TFR exploration from 1980 onwards. |

### Machine Learning Comparison

| File | Purpose |
|---|---|
| `code/model_ml.R` | Builds comparison models using lag-based inputs and Zodiac information for TFR and TLB. |
| `code/create_comparison_table.R` | Creates comparison tables from saved model and forecast outputs. |

### Archived Files

| Folder | Purpose |
|---|---|
| `code/archive/` | Stores older experimental scripts that are kept for traceability but are not part of the final workflow. |

## Documentation Folder

The `documentation/` folder explains how to run individual code sections and how the modelling workflow was developed.

| File | Purpose |
|---|---|
| [`documentation/dataset_cleanup.md`](documentation/dataset_cleanup.md) | Explains the dataset cleaning process. |
| [`documentation/ARIMA_Model_Finding.md`](documentation/ARIMA_Model_Finding.md) | Explains the ARIMA model identification and testing workflow. |
| [`documentation/tlb_arima_outputs_guide.md`](documentation/tlb_arima_outputs_guide.md) | Explains Lara's TLB ARIMA and SARIMA files, outputs, and run order. |
| [`documentation/zodiacfindings_documentation.md`](documentation/zodiacfindings_documentation.md) | Explains the Zodiac analysis and related modelling workflow. |

Read the relevant documentation file before changing model parameters or rerunning a specific section.

## Recommended Run Order

### 1. Rebuild cleaned data

```r
source("code/preprocessing.R")
```

### 2. Run TLB ARIMA and SARIMA models

```r
source("code/tlb_arima_search.R")
source("code/tlb_arima_model_validation.R")
source("code/tlb_sarima_search.R")
source("code/tlb_sarima_model_validation.R")
source("code/tlb_compare_arima_sarima.R")
source("code/tlb_sarima_selected_plots.R")
```

### 3. Run TFR ARIMA models

```r
source("code/tfr_arima.R")
source("code/tfr_arima_model_validation.R")
source("code/tfr_residual_diagnostics.R")
source("code/tfr-model-comparison.R")
```

### 4. Run Zodiac analysis

```r
source("code/zodiacfinding.R")
source("code/zodiacmodels.R")
source("code/zodiacTLB.R")
source("code/zodiacCBR.R")
```

### 5. Run machine learning comparison models

```r
source("code/model_ml.R")
```

## Important Outputs

| Folder or file | Contents |
|---|---|
| `clean_data/` | Cleaned training and testing CSV files. |
| `processed_data/` | Model comparison CSV files and validation summaries. |
| `outputs/ts_plots/` | Time series and differencing plots. |
| `outputs/model_validation/tlb/` | TLB ARIMA forecast and residual plots. |
| `outputs/model_validation/tlb_sarima/` | Corrected TLB SARIMA forecast and residual plots. |
| `outputs/model_validation/tlb_sarima_selected/` | Report-ready plots for selected corrected SARIMA models. |
| `outputs/forecasts/` | Forecast CSV files for tested models. |
| `outputs/model_comparison/` | Model comparison plots and summary files. |
| `outputs/models/` | Saved fitted model objects. |


## Notes for Team Members

- Always run `code/preprocessing.R` before running model scripts.
- Do not manually edit files in `clean_data/`, because they are regenerated by preprocessing.
- Use `processed_data/` for CSV summaries used in the report.
- Use `outputs/model_validation/` for forecast and residual diagnostic plots.
- Keep older exploratory scripts in `code/archive/` unless they are needed for final reproduction.
- Add new documentation into `documentation/` when adding a new model workflow.

## Project Status

This repository supports the final ICT Capstone report and handover. The main final workflow is focused on cleaned data generation, ARIMA and SARIMA model validation, Zodiac-related seasonal analysis, machine learning comparison, and report-ready output files.

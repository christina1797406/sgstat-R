# Singapore Fertility Forecasting Capstone Project

This repository contains the data preprocessing, modelling code, and documentation for our ICT Capstone project. The project focuses on analysing and forecasting Singapore fertility trends using time series methods, with a particular focus on Total Fertility Rate (TFR) and Total Live Births (TLB).

The aim of the project is to clean and prepare the Singapore fertility dataset, test suitable forecasting models, evaluate model performance, and document the modelling workflow clearly enough for team members and stakeholders to reproduce the results.

## Project Overview

The project investigates historical fertility and birth trends in Singapore. The two main variables used in the ARIMA modelling workflow are:

- **TFR:** Total Fertility Rate, which represents the average number of children expected to be born to a woman over her lifetime.
- **TLB:** Total Live Births, which represents the yearly number of live births recorded.

The modelling process includes data cleaning, train and test splitting, stationarity checks, differencing, ARIMA model testing, residual diagnostics, and forecast validation.

## Folder Structure

```text
project-root/
├── code/
│   ├── preprocessing.R
│   ├── tlb_arima_search.R
│   └── tlb_arima_model_validation.R
├── raw_data/
│   └── 1960-2025.csv
├── clean_data/
│   ├── full_clean.csv
│   ├── train.csv
│   ├── test.csv
│   ├── tfr_train.csv
│   ├── tfr_test.csv
│   ├── tlb_train.csv
│   └── tlb_test.csv
├── documentation/
│   └── ARIMA model testing documentation files
├── outputs/
│   └── model results, plots, and validation outputs
├── processed_data/
│   ├── csv results
└── README.md
```

## How to Rebuild and Preprocess the Data

Open the project in RStudio and make sure your working directory is the project root. The root folder should contain folders such as `code`, `raw_data`, `clean_data`, and `documentation`.

Run the preprocessing script from the R Console:

```r
source("code/preprocessing.R")
```

This script:

- imports the raw Singapore fertility dataset from `raw_data/1960-2025.csv`
- reshapes the data from wide format into long format
- extracts the TFR and TLB series
- cleans missing values and numeric formatting
- creates the training and testing datasets
- exports cleaned CSV files into the `clean_data/` folder

## Verify the Cleaned Data

After running the preprocessing script, check that the cleaned files were created correctly:

```r
train <- read.csv("clean_data/train.csv")
test <- read.csv("clean_data/test.csv")

nrow(train)
nrow(test)

head(train)
tail(train)

head(test)
tail(test)
```

Expected split:

```text
Training set: 1960 to 2012
Testing set: 2013 to 2025
```

## How to Test the ARIMA Models

The detailed ARIMA modelling workflow is documented in the `documentation/` folder. Refer to the ARIMA model testing documentation for step-by-step instructions on:

- creating time series objects
- plotting the original TFR and TLB series
- checking ACF and PACF plots
- applying first and second differencing
- fitting ARIMA candidate models
- comparing AIC values
- checking residual ACF and PACF plots
- running Ljung-Box tests
- validating forecasts with RMSE and MAE
- selecting the final model

For TLB-specific testing, run:

```r
source("code/tlb_arima_search.R")
```

This script tests a range of TLB ARIMA models and outputs model comparison results based on AIC, Ljung-Box p-value, RMSE, and MAE.

Then run:

```r
source("code/tlb_arima_model_validation.R")
```

This script validates selected TLB candidate models and generates forecast comparison outputs and residual diagnostic plots.

## Notes for Team Members

Before running model testing scripts, always run the preprocessing script first so that the latest cleaned data is available.

The general workflow is:

```r
source("code/preprocessing.R")
source("code/your_model_search.R")
source("code/your_model_validation.R")
```

For full modelling details, please read the files in the `documentation/` folder before changing model parameters or adding new candidate models.

## Project Status

This project is currently being developed as part of the ICT Capstone prototype and final delivery process. Current work focuses on refining the ARIMA modelling workflow, validating forecasts, comparing candidate models, and preparing clear documentation for the final report and prototype demonstration.

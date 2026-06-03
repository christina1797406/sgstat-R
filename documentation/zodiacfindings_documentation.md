## Overview

This script investigates whether the Chinese Zodiac 12-year cycle has a statistically measurable effect on Singapore's Total Fertility Rate (TFR) and Total Live Births (TLB). It does this in two stages:

1. **Model identification** — fits 31 candidate ARIMA and SARIMA models across three groups and selects the best baseline by test RMSE
2. **Zodiac layering** — re-fits the best baseline three times, each time with a different Zodiac encoding as an external regressor, and compares forecast accuracy against the baseline

The script covers both TFR and TLB in parallel throughout.



## Dependencies

```r
library(ggplot2)   # Plotting
library(dplyr)     # Data manipulation
library(forecast)  # Arima(), forecast(), checkresiduals()
library(tseries)   # adf.test()
```

Install any missing packages with `install.packages("package\_name")` before running.

\---

## Required Input Files

Both files must exist before the script is run. They are produced by `preprocessing.R`.

|File|Path|Contents|
|-|-|-|
|Training data|`clean\_data/train.csv`|Annual TFR and TLB, 1960–2012|
|Test data|`clean\_data/test.csv`|Annual TFR and TLB, 2013–2025|

The script expects at minimum these columns in both files:

* `year` — integer year
* `TFR` — Total Fertility Rate (numeric)
* `TLB` — Total Live Births (integer)

**Always run `preprocessing.R` first.** The script will fail at the `read.csv` step if these files do not exist.

\---

## How to Run

```r
# Step 1 — ensure preprocessing has been run
source("code/preprocessing.R")

# Step 2 — run this script
source("code/zodiacfindings.r")
```

Or open `zodiacfindings.r` in RStudio and use **Run All** (Ctrl+Alt+R / Cmd+Option+R).

The script is designed to run top-to-bottom in a single pass. All objects built in earlier phases are reused in later phases, so partial execution will cause errors.

\---

## Script Structure

The script is divided into seven phases plus a setup block.

\---

### Phase 0 — Load Data

```r
train <- read.csv("clean\_data/train.csv")
test  <- read.csv("clean\_data/test.csv")
```

Loads both datasets and creates four time series objects:

|Object|Contents|
|-|-|
|`TFRa`|TFR training series (raw)|
|`TLBa`|TLB training series (raw)|
|`TFRa\_log`|Log-transformed TFR|
|`TLBa\_log`|Log-transformed TLB|

All four are `ts` objects with `start = 1960, frequency = 1`. The log versions are used in Phase 3 to check whether variance stabilisation is needed.

\---

### Phase 1 — Raw Time Series Plots

Produces two `ggplot2` line charts:

* **TFR plot** — shows the sustained downward trend from \~6.0 (1960) to below 2.0 (2012), with a noted structural break around 1975
* **TLB plot** — shows the downward trend with a visible dip in 1986 and a spike in 1988 (Year of the Dragon)

These plots are for visual diagnosis only. They are not saved to disk automatically — use `ggsave()` if you need to export them.

\---

### Phase 2 — Differencing \& Stationarity Checks

Runs Augmented Dickey-Fuller (ADF) tests on four series:

|Series|Expected outcome|
|-|-|
|Raw TFR|Non-stationary (p > 0.05)|
|Raw TLB|Non-stationary (p > 0.05)|
|TFR d=1|Stationary (p < 0.05)|
|TLB d=1|Stationary (p < 0.05)|

Second-differenced versions (`d=2`) are also tested as a check. For this dataset, both series typically become stationary at `d=1`, meaning `d=1` is used for most models. `d=2` variants are included in Group A to confirm this.

A 2×2 plot of differenced series is produced for visual inspection.

**Interpretation guide:**

* ADF p < 0.05 → series is stationary → differencing is sufficient at this order
* ADF p ≥ 0.05 → series is still non-stationary → difference again

\---

### Phase 3 — ACF / PACF Analysis

Produces 2×2 ACF/PACF plots for:

* `d1\_TFR` and `d1\_TLB` (differenced raw series)
* `diff(TFRa\_log)` and `diff(TLBa\_log)` (differenced log series)

These plots are used to read off candidate AR and MA orders using standard rules:

|Pattern|Implication|
|-|-|
|PACF cuts off at lag p|Suggests AR(p)|
|ACF cuts off at lag q|Suggests MA(q)|
|Both tail off gradually|Suggests ARMA(p, q)|
|Significant spike at lag 12|Suggests seasonal component S=12|
|Many significant lags|Suggests high-order AR (Group B candidates)|

The lag-12 spike in TLB's ACF/PACF is the key diagnostic that motivates the Group C seasonal models and the entire Zodiac investigation.

\---

### Phase 4 — Fit Candidate Models (No Zodiac)

Fits 31 candidate models across three groups for both TFR and TLB.

#### Helper Functions

**`safe\_fit(y, order, seasonal, label)`**
Wraps `Arima()` in a `tryCatch` block. If a model fails to converge or throws a warning, it prints a `\[SKIP]` or `\[WARN]` message and returns `NULL` instead of stopping the script. This prevents a single bad model from breaking the entire grid search.

**`fit\_group(specs, y)`**
Takes a list of model specifications and a time series, calls `safe\_fit` on each, filters out NULLs, and returns a named list of successfully fitted models.

#### Model Groups

**Group A — Compact ARIMA (14 models)**

Low-order ARIMA models with p, q ≤ 3. Covers the most common parsimonious specifications. Includes both `d=1` and `d=2` variants.

```
ARIMA(1,1,0), ARIMA(0,1,1), ARIMA(1,1,1), ARIMA(2,1,0),
ARIMA(0,1,2), ARIMA(2,1,1), ARIMA(1,1,2), ARIMA(2,1,2),
ARIMA(3,1,0), ARIMA(3,1,1), ARIMA(3,1,2),
ARIMA(1,2,1), ARIMA(2,2,1), ARIMA(2,2,2)
```

**Group B — High-Order AR (9 models)**

High AR-order models (p = 10 to 15). A large p can absorb long periodic structure without explicitly modelling it as seasonal. Computationally expensive but sometimes produces the lowest AIC.

```
ARIMA(10,1,0), ARIMA(10,2,0), ARIMA(12,1,0), ARIMA(12,1,1),
ARIMA(12,2,1), ARIMA(13,1,0), ARIMA(13,1,1), ARIMA(15,1,0), ARIMA(15,1,1)
```

**Group C — Seasonal ARIMA, S=12 (9 models)**

Seasonal ARIMA models with a 12-year period, directly modelling the Zodiac cycle as a structural component. Written as `SARIMA(p,d,q)(P,D,Q)\[12]`.

```
SARIMA(1,1,0)(1,0,0)\[12], SARIMA(0,1,1)(0,0,1)\[12],
SARIMA(1,1,1)(1,0,0)\[12], SARIMA(1,1,1)(0,0,1)\[12],
SARIMA(1,1,1)(1,0,1)\[12], SARIMA(2,1,1)(1,0,0)\[12],
SARIMA(2,1,1)(0,0,1)\[12], SARIMA(2,1,2)(1,0,0)\[12],
SARIMA(3,1,1)(1,0,0)\[12]
```

\---

### Phase 5 — Select Best Baseline Model

**`aic\_rmse\_table(fits\_A, fits\_B, fits\_C, test\_actual, series\_name, h)`**

Collates all successfully fitted models into a single comparison table with four columns:

|Column|Description|
|-|-|
|`Group`|A-compact, B-highAR, or C-seasonal|
|`Model`|Model label string|
|`AIC`|In-sample Akaike Information Criterion|
|`RMSE`|Out-of-sample Root Mean Square Error on the test set|

Tables are printed sorted by RMSE (lowest first). The script then automatically selects the best model by RMSE as the baseline for Zodiac layering.

Two separate baselines are selected:

* `best\_TFR` — best RMSE model for TFR
* `best\_TLB` — best RMSE model for TLB

Residual diagnostics (`checkresiduals()` and `Box.test()` with Ljung-Box) are printed for both selected baselines. A well-behaved model should show:

* Residuals resembling white noise (no pattern)
* Ljung-Box p-value > 0.05 (no significant autocorrelation remaining)

> \*\*Note on AIC vs RMSE:\*\* The script selects the best baseline by test RMSE, not AIC. This is intentional — AIC measures in-sample fit; RMSE measures out-of-sample forecast accuracy. For forecasting purposes, RMSE is the more relevant criterion. The best-AIC models are also identified and plotted separately at the end of the script (Phase 7 / final section) for comparison.

\---

### Phase 6 — Zodiac Layers

Builds on the best baseline models by adding Zodiac information as external regressors (`xreg`). Three encodings are tested, labelled Z1–Z3. The unmodified baseline is Z0 for reference.

#### Zodiac Assignment

```r
assign\_zodiac <- function(yrs) { ... }
```

Maps each year to its Chinese Zodiac animal using the reference point of 2020 (Year of the Rat). The 12-animal cycle is: Rat → Ox → Tiger → Rabbit → Dragon → Snake → Horse → Goat → Monkey → Rooster → Dog → Pig.

A `Dragon` binary column is also added to both `train` and `test`.

#### Encoding Methods

**Z1 — Zodiac Dummy Variables (11 binary columns)**

Uses `model.matrix()` to create one binary column per animal, with Rat as the dropped reference category. This adds 11 parameters to the model. A column-alignment step ensures the test matrix has exactly the same columns as the train matrix (important if not all 12 animals appear in the 13-year test window).

**Z2 — Cosine/Sine Cycle (2 columns)**

Encodes the 12-year periodicity as a smooth sinusoidal wave:

```r
cos12 = cos(2 \* pi \* year / 12)
sin12 = sin(2 \* pi \* year / 12)
```

This is a soft, continuous encoding. It uses only 2 parameters instead of Z1's 11, capturing the periodic rhythm without assigning a discrete effect to each animal. Best suited when the underlying effect is gradual rather than animal-specific.

**Z3 — Dragon Dummy Only (1 binary column)**

A single binary flag marking Dragon years only. Tests the hypothesis that only the most auspicious year (Dragon) drives the anomaly, rather than all 12 animals contributing distinct effects.

#### `refit\_with\_xreg()` Function

```r
refit\_with\_xreg(base\_fit, y, xreg\_train, xreg\_test, test\_actual, label, is\_seasonal)
```

Reconstructs the order and seasonal structure from a fitted model object's `arma` slot, then re-fits using the same specification with `xreg` added. Prints AIC and test RMSE for each encoding. Returns a list containing the fitted model, forecast object, RMSE, AIC, and label.

#### What to Look For

|Result|Interpretation|
|-|-|
|Lower AIC than baseline, lower RMSE|Zodiac encoding genuinely improves the model|
|Lower AIC, higher RMSE|Overfitting — model fits training data better but forecasts worse|
|Higher AIC, higher RMSE|Encoding adds noise; discard|

In this dataset, all three Zodiac encodings improve AIC but worsen test RMSE — consistent with overfitting. Z1 (11 dummies) shows the most extreme divergence.

\---

### Phase 7 — Forecast Comparison Plots

#### `plot\_forecast\_comparison()`

Produces a single plot overlaying four forecast lines against actual test values for a given series:

|Line|Colour|Style|
|-|-|-|
|Baseline|Blue (#378ADD)|Solid|
|Z1: Dummies|Orange (#D85A30)|Dashed|
|Z2: cos/sin|Green (#1D9E75)|Dotted|
|Z3: Dragon|Purple (#7F77DD)|Dot-dash|
|Actual|Black|Solid|

Called twice — once for TFR, once for TLB.

#### `plot\_single\_forecast()`

A simpler two-line plot (black = actual, red = forecast) used to visualise the best-AIC and best-RMSE models individually. Called four times at the end of the script:

1. TFR — best AIC model
2. TLB — best AIC model
3. TFR — best RMSE model
4. TLB — best RMSE model

These plots are useful for directly comparing what the AIC-selected and RMSE-selected models actually predict over the test period.

\---

## Output Summary

All outputs are printed to the R console or displayed in the RStudio Plots pane. Nothing is saved to disk automatically.

|Output|Type|Phase|
|-|-|-|
|TFR \& TLB raw time series|Plot|1|
|2×2 differenced series plots|Plot|2|
|ADF test results|Console|2|
|2×2 ACF/PACF plots (raw + log)|Plot|3|
|Per-model AIC values during fitting|Console|4|
|Full AIC/RMSE comparison tables|Console|5|
|Best baseline model names|Console|5|
|Residual diagnostics for best models|Plot + Console|5|
|Zodiac layer AIC \& RMSE comparison|Console|6|
|Forecast comparison plots (TFR \& TLB)|Plot|7|
|Best AIC model forecast plots (×2)|Plot|7|
|Best RMSE model forecast plots (×2)|Plot|7|

To save any plot to disk, add after the relevant plot call:

```r
ggsave("outputs/filename.png", width = 10, height = 6)
```

\---

## Key Variables Reference

|Variable|Type|Description|
|-|-|-|
|`TFRa` / `TLBa`|`ts`|Training time series (raw)|
|`TFRa\_log` / `TLBa\_log`|`ts`|Log-transformed training series|
|`fits\_TFR\_A/B/C`|named list|Fitted models by group, TFR|
|`fits\_TLB\_A/B/C`|named list|Fitted models by group, TLB|
|`tbl\_TFR` / `tbl\_TLB`|`data.frame`|Full AIC/RMSE comparison tables|
|`best\_TFR` / `best\_TLB`|`Arima` object|Best baseline by test RMSE|
|`best\_TFR\_AIC` / `best\_TLB\_AIC`|`Arima` object|Best baseline by AIC|
|`z1\_TFR` … `z3\_TLB`|list|Zodiac-layered fit results|
|`fc\_base\_TFR` / `fc\_base\_TLB`|`forecast`|Baseline forecast objects|

\---

## Known Limitations

* **Structural break post-2021.** TFR and TLB fell to historically unprecedented levels after 2021, driven by COVID and structural social changes. No model trained on 1960–2012 data can anticipate this. All test RMSEs are inflated by this break — this is a data limitation, not a modelling error.
* **No output persistence.** Plots and console output are not automatically saved. 
* **Column alignment for Z1.** The test set spans 2013–2025 (13 years), which covers only a subset of all 12 Zodiac animals. The alignment loop ensures the xreg matrices match, but this means some dummy coefficients are estimated with limited support.
* **Single-run design.** The script is not modular — it must run end-to-end. Rerunning a single phase in isolation will fail if earlier phase objects are not in the environment.

\---

## Reproducing the Main Finding

To reproduce the central result (SARIMA beats non-seasonal ARIMA; Zodiac dummies overfit):

1. Run `preprocessing.R`
2. Run `zodiacfindings.r` end-to-end
3. In the console output, compare the RMSE column in the TLB comparison table — the Group C seasonal models should rank near the top
4. In the Zodiac layer comparison, observe that Z1/Z2/Z3 all show lower AIC but higher RMSE than the baseline
5. The forecast comparison plot for TLB will visually confirm that Zodiac-enhanced lines diverge from actuals more than the baseline after \~2021


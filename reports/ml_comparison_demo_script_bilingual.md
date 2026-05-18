# ML Models and Model Comparison Demo Script

This script is for the prototype demo section covering:

- Machine learning comparison models
- Unified model comparison table
- How the code, outputs, plots, and interpretation connect

Recommended length for your personal part: **3-4 minutes**.

## Files To Prepare Before Recording

Open these files before recording so you can switch quickly:

1. `code/model_ml.R`
2. `outputs/model_comparison_ml.csv`
3. `outputs/plots/tfr_ridge_actual_vs_predicted.png`
4. `outputs/plots/tlb_random_forest_actual_vs_predicted.png`
5. `code/create_comparison_table.R`
6. `outputs/model_comparison_full.csv`

Optional if you want to show the workflow runs:

```bash
Rscript code/model_ml.R
Rscript code/create_comparison_table.R
```

For the demo, it is usually enough to show the code and generated outputs. You do not have to run the full pipeline live unless the group specifically wants code execution evidence.

## Demo Flow

### 0:00-0:20 - Start With Your Contribution

**Open:** no code yet, or show the project folder.

**Chinese**

大家好，我负责的部分主要有两块：第一是 machine learning comparison models，第二是 overall model comparison table。我的目标不是替代 ARIMA 模型，而是提供 ARIMA 和 ETS 之外的预测对比基准，并把所有模型放进一个统一的评估表里。

**English**

My contribution focuses on two parts: the machine learning comparison models and the overall model comparison table. The goal was not to replace the ARIMA models, but to provide additional predictive benchmarks and combine all models into one consistent evaluation table.

## Part 1: ML Models

### 0:20-1:05 - Show ML Feature Engineering

**Open:** `code/model_ml.R`

**Point to this code:**

```r
FEATURE_COLUMNS <- c("year", "lag1", "lag2", "lag3", "rolling_mean")
```

**Chinese**

这里是我定义的机器学习特征。`year` 用来捕捉长期趋势，`lag1`、`lag2` 和 `lag3` 表示过去一到三年的历史值，`rolling_mean` 表示过去三年的平均值。这样模型既可以利用最近几年的变化，也可以考虑长期趋势。

**English**

Here I define the machine learning features. The `year` variable captures the long-term trend, `lag1`, `lag2`, and `lag3` represent the previous one to three years, and `rolling_mean` captures the average of the previous three years. This allows the models to use both recent historical values and the longer-term trend.

### 1:05-1:40 - Show The ML Models

**Stay in:** `code/model_ml.R`

**Point to this code block:**

```r
models <- list(
  "Random Forest" = ...,
  "XGBoost" = ...,
  "Ridge" = ...
)
```

**Chinese**

我训练了三个 ML 模型：Random Forest、XGBoost 和 Ridge Regression。这三个模型都分别用于 TFR 和 TLB。TFR 是总和生育率，TLB 是总活产数。

**English**

I trained three machine learning models: Random Forest, XGBoost, and Ridge Regression. I applied all three models to both TFR and TLB. TFR refers to the total fertility rate, while TLB refers to total live births.

### 1:40-2:15 - Show Recursive Forecasting

**Stay in:** `code/model_ml.R`

**Point to this function:**

```r
predict_recursive <- function(...)
```

**Mention this part conceptually, not line by line:**

- It predicts one future year.
- Then it uses that prediction as the next year's lag input.
- It avoids using future actual test values.

**Chinese**

这里是 recursive forecasting 的部分。它的意思是，模型先预测测试集的第一年，然后把这个预测值作为下一年预测时的 lag 输入。这样做可以避免使用未来真实值作为输入，更接近真实预测场景。

**English**

This function implements recursive forecasting. The model predicts the first test year, then feeds that predicted value forward as a lag input for the next forecast year. This avoids using future actual test values and makes the forecasting setup more realistic.

## Part 2: ML Results

### 2:15-2:50 - Show ML Comparison Table

**Open:** `outputs/model_comparison_ml.csv`

**Point to these result rows:**

- TFR Ridge Regression
- TLB Random Forest

**Chinese**

这个表是 ML 模型的单独结果表。我用 RMSE、MAE 和 MAPE 来评估预测误差。对于 TFR，表现最好的是 Ridge Regression，RMSE 大约是 0.0649，MAPE 大约是 4.53%。对于 TLB，表现最好的是 Random Forest，RMSE 大约是 3971，MAPE 大约是 8.08%。

**English**

This table contains the machine learning model results. I evaluated the models using RMSE, MAE, and MAPE. For TFR, Ridge Regression performed best, with an RMSE of about 0.0649 and a MAPE of about 4.53%. For TLB, Random Forest performed best, with an RMSE of about 3971 and a MAPE of about 8.08%.

### 2:50-3:25 - Show ML Actual vs Predicted Plots

**Open:** `outputs/plots/tfr_ridge_actual_vs_predicted.png`

**Chinese**

这张图展示的是 TFR 的 Ridge Regression actual vs predicted result。蓝线是真实值，红线是预测值。可以看到预测值整体比较接近测试集的真实趋势，所以它在表格里的 RMSE 和 MAPE 比较低。

**English**

This plot shows the actual versus predicted values for TFR using Ridge Regression. The blue line is the actual value and the red line is the predicted value. The prediction follows the test data closely, which explains the low RMSE and MAPE in the results table.

**Open:** `outputs/plots/tlb_random_forest_actual_vs_predicted.png`

**Chinese**

这张图展示的是 TLB 的 Random Forest actual vs predicted result。它不是完全重合，但整体上 Random Forest 是所有 TLB 模型里面预测误差最低的。

**English**

This plot shows the actual versus predicted values for TLB using Random Forest. The lines are not perfectly identical, but overall Random Forest achieved the lowest prediction error among the TLB models.

## Part 3: Full Model Comparison Table

### 3:25-4:05 - Show Comparison Table Code

**Open:** `code/create_comparison_table.R`

**Point to this code:**

```r
calc_metrics <- function(actual, predicted)
```

**Chinese**

这里统一计算 RMSE、MAE 和 MAPE。这样 ARIMA、ETS 和 ML 模型都可以用同一套 forecast accuracy metrics 来比较。

**English**

This function calculates RMSE, MAE, and MAPE. This lets us compare ARIMA, ETS, and ML models using the same forecast accuracy metrics.

**Point to this code:**

```r
diagnose_residuals <- function(fit, strict_lag = 20)
```

**Chinese**

这里是对 ARIMA 和 ETS 这类时间序列模型做 residual diagnostics，包括 Ljung-Box test、ACF spikes 和 PACF spikes。这个部分主要用来判断时间序列模型的 residuals 是否接近 white noise。

**English**

This function performs residual diagnostics for time series models such as ARIMA and ETS. It calculates the Ljung-Box test and counts ACF and PACF spikes. This helps us judge whether the residuals are close to white noise.

**Point to this code:**

```r
make_ml_row <- function(...)
```

**Chinese**

这里是处理 ML 模型在 comparison table 里的行。因为 ML 模型不能像 ARIMA 那样直接使用 AIC，所以我把 AIC 标成 N/A，并把 ML 模型标成 comparison only。

**English**

This part handles the ML rows in the comparison table. Since AIC is not directly applicable to ML models in the same way as ARIMA, I mark AIC as N/A and label ML models as comparison only.

### 4:05-4:50 - Show Final Comparison Table

**Open:** `outputs/model_comparison_full.csv`

**Point to these rows:**

- TFR Ridge Regression
- TLB Random Forest
- ARIMA / ETS rows with `Viable = No`
- ML rows with `Viable = Comparison only`

**Chinese**

这个表是最终的 full comparison table。它把 ARIMA、log-ARIMA、ETS 和 ML 模型放在一起。对于所有模型，我们统一比较 RMSE、MAE 和 MAPE。对于 ARIMA、log-ARIMA 和 ETS，我还额外保留了 AIC、Ljung-Box p-value、ACF/PACF spike count 和 viability status。

从这个表可以看到，TFR 上预测误差最低的是 Ridge Regression；TLB 上预测误差最低的是 Random Forest。但是，ML 模型在这里被标为 comparison only，因为它们不是通过 ARIMA-style residual diagnostics 来验证的。

对于 ARIMA、log-ARIMA 和 ETS，虽然有些模型的 RMSE 还可以，但 residual diagnostics 没有完全通过 strict white-noise check，所以它们目前不能直接写成 final viable model。

**English**

This is the final full comparison table. It combines ARIMA, log-ARIMA, ETS, and ML models. For all models, I compare RMSE, MAE, and MAPE. For ARIMA, log-ARIMA, and ETS, I also include AIC, Ljung-Box p-values, ACF/PACF spike counts, and the viability status.

From this table, Ridge Regression has the lowest prediction error for TFR, while Random Forest has the lowest prediction error for TLB. However, the ML models are marked as comparison only because they are not validated using ARIMA-style residual diagnostics.

For ARIMA, log-ARIMA, and ETS, some models have acceptable forecast accuracy, but the residual diagnostics do not fully pass the strict white-noise check. Therefore, they should not be presented as final viable models at this stage.

## Final Summary

### 4:50-5:20 - Close Your Section

**Chinese**

总结来说，我的贡献有两点。第一，我实现并评估了 TFR 和 TLB 的机器学习对比模型。第二，我整理了统一的模型对比表，把 ARIMA、log-ARIMA、ETS 和 ML 模型放在同一个框架下比较。结果上，TFR 的 Ridge Regression 和 TLB 的 Random Forest 在测试集上表现最好。但我会谨慎解释这些结果，因为 ML 模型主要是 comparison benchmarks，最终时间序列模型仍然需要结合 residual diagnostics 来判断。

**English**

To summarise, my contribution has two parts. First, I implemented and evaluated machine learning comparison models for TFR and TLB. Second, I created a unified model comparison table that compares ARIMA, log-ARIMA, ETS, and ML models in one framework. The results show that Ridge Regression performs best for TFR, while Random Forest performs best for TLB. However, I interpret these results carefully because the ML models are comparison benchmarks, and final time-series model selection should still consider residual diagnostics.

## Very Short Version If You Only Have 1 Minute

**Chinese**

我负责 ML models 和 model comparison table。我训练了 Random Forest、XGBoost 和 Ridge Regression，用来预测 TFR 和 TLB。模型使用的特征包括 `year`、`lag1`、`lag2`、`lag3` 和 `rolling_mean`，并使用 recursive forecasting 来避免用未来真实值作为输入。结果上，TFR 表现最好的是 Ridge Regression，RMSE 大约是 0.0649；TLB 表现最好的是 Random Forest，RMSE 大约是 3971。我还把 ARIMA、log-ARIMA、ETS 和 ML 模型整合到同一个 comparison table 里。ML 模型的 AIC 标为 N/A，ARIMA 和 ETS 的 viability 通过 residual diagnostics 判断。我的结论是，ML 模型是很有价值的 comparison benchmarks，但最终模型选择不能只看 RMSE，还需要结合 residual diagnostics。

**English**

I was responsible for the ML models and the model comparison table. I trained Random Forest, XGBoost, and Ridge Regression for both TFR and TLB, using `year`, `lag1`, `lag2`, `lag3`, and `rolling_mean` as features. I also used recursive forecasting to avoid using future actual values. For TFR, Ridge Regression performed best with an RMSE of about 0.0649. For TLB, Random Forest performed best with an RMSE of about 3971. I also integrated ARIMA, log-ARIMA, ETS, and ML models into one comparison table. AIC is marked as N/A for ML models, while ARIMA and ETS viability is judged using residual diagnostics. My conclusion is that ML models provide useful comparison benchmarks, but final model selection should not rely only on RMSE and should also consider residual diagnostics.

## Possible Questions And Answers

### Q1. Why did you add ML models?

**Answer**

We added ML models as non-ARIMA benchmarks. They help us check whether lag-based and trend-based features can improve forecasting accuracy compared with traditional time-series models.

### Q2. Why is AIC N/A for ML models?

**Answer**

AIC is mainly used for likelihood-based statistical models such as ARIMA. Random Forest, XGBoost, and Ridge Regression are not compared using AIC in the same way, so we evaluate them using out-of-sample RMSE, MAE, and MAPE instead.

### Q3. Is Ridge Regression the final model for TFR?

**Answer**

Not necessarily. Ridge Regression has the lowest TFR error on the test set, but it may be strongly helped by the `year` feature and the long-term trend. I would describe it as a strong comparison benchmark rather than the final model.

### Q4. What is the main conclusion from the full comparison table?

**Answer**

The table shows that ML models provide strong predictive benchmarks, especially Ridge Regression for TFR and Random Forest for TLB. However, ARIMA, log-ARIMA, and ETS do not fully pass strict residual diagnostics, so they should currently be treated as candidate or baseline models rather than final viable models.


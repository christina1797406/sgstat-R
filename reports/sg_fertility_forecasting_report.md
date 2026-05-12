# 新加坡生育率与出生人数预测项目阶段报告

## 1. Project Overview

本项目目前围绕新加坡 fertility / birth time series 做预测模型比较，核心序列包括：

- **TFR**: Total Fertility Rate，总和生育率。
- **TLB**: Total Live-Births，总活产数 / 出生人数。

项目目标不是只找到一个 RMSE 最低的模型，而是比较多种可解释、可复现的模型，并判断它们是否满足时间序列建模中最关键的残差诊断要求。按照 Gerald 的标准，最终 viable time series model 需要有接近 white noise 的残差，因此不能只看 AIC 或预测误差，还需要检查 residual ACF、PACF、Ljung-Box test 和 residual plots。

当前数据处理方式如下：

- 原始数据文件：`data/raw_data/1960-2025.csv`
- 清洗后数据：`data/clean_data/`
- 训练集：1960-2012，共 53 年
- 测试集：2013-2025，共 13 年
- 主要输出目录：`outputs/forecasts/`、`outputs/models/`、`outputs/plots/`

## 2. What Has Been Completed

目前项目已经完成了比较完整的第一轮建模流程：

- 数据预处理已经完成，TFR 和 TLB 都已拆分为 train/test。
- EDA 已经生成趋势图：`outputs/plots/tfr_trend.png` 和 `outputs/plots/tlb_trend.png`。
- 时间序列模型已经有 ARIMA、log-ARIMA 和 ETS 输出。
- Machine Learning comparison models 已经完成 Random Forest、XGBoost、Ridge Regression。
- ML 模型已经输出 forecast CSV、模型 RDS、actual vs predicted plots，以及 `outputs/model_comparison_ml.csv`。
- 统一比较表 `outputs/model_comparison_full.csv` 已更新为从保存的模型和预测结果动态生成，不再手动硬编码 p-value 或 viability。

总体评价：项目不是“还没开始”，而是已经有了可用于报告的主要实验素材；真正需要修正的是模型 viability 的表述、残差诊断解释，以及最终表格的可信度。

## 3. Model Results and Interpretation

### 3.1 TFR results

当前 TFR 测试集预测结果如下，按 RMSE 从低到高排列：

| Series | Model | RMSE | MAE | MAPE |
|---|---|---:|---:|---:|
| TFR | Ridge Regression | 0.065 | 0.046 | 4.53% |
| TFR | ETS | 0.164 | 0.136 | 13.31% |
| TFR | log-ARIMA(1,1,1) | 0.182 | 0.154 | 15.01% |
| TFR | Random Forest | 0.182 | 0.144 | 14.25% |
| TFR | XGBoost | 0.187 | 0.152 | 14.92% |
| TFR | auto.arima | 0.255 | 0.220 | 21.37% |
| TFR | selected ARIMA output | 0.264 | 0.229 | 22.17% |

从纯预测误差看，TFR 当前表现最好的是 Ridge Regression。这个变化来自 ML 脚本更新后真正把 `year` 纳入 predictor，因此 Ridge 可以利用长期线性趋势做外推。它的 RMSE 明显低于 ETS 和 ARIMA-family models，但报告中应说明它是一个带趋势项的线性 ML baseline，不能只凭一个小测试集就过度声称它是最稳健的最终模型。

但是，TFR 最终模型不能只按 RMSE 决定。如果报告采用严格时间序列标准，需要优先解释残差诊断是否合格。Ridge、Random Forest、XGBoost 可以作为 comparison models，但它们不是传统 ARIMA 类模型，因此 AIC 应标为 N/A，残差诊断也应另行说明，而不是直接套用 ARIMA 的 AIC 标准。

### 3.2 TLB results

当前 TLB 测试集预测结果如下，按 RMSE 从低到高排列：

| Series | Model | RMSE | MAE | MAPE |
|---|---|---:|---:|---:|
| TLB | Random Forest | 3,971 | 2,763 | 8.08% |
| TLB | Ridge Regression | 4,594 | 3,423 | 9.94% |
| TLB | XGBoost | 4,628 | 3,380 | 9.84% |
| TLB | log-ARIMA(1,1,1) | 5,612 | 4,356 | 12.55% |
| TLB | ETS | 5,703 | 4,470 | 12.85% |
| TLB | auto.arima | 5,890 | 4,706 | 13.48% |
| TLB | selected ARIMA output | 5,914 | 4,729 | 13.54% |

从预测误差看，TLB 当前最强的是 Random Forest，其次是 Ridge Regression 和 XGBoost。ML 模型对 TLB 的提升很明显，尤其 Random Forest 的 RMSE、MAE 和 MAPE 都优于 ARIMA / log-ARIMA / ETS。

这说明 ML 部分已经可以成为团队报告中的重要 contribution：它不是最终替代时间序列模型，而是一个有解释价值的 comparison block，证明基于 year / lag / rolling-mean features 的模型对出生人数预测有一定帮助。

## 4. Residual Diagnostics and Viability

Gerald 的核心标准是：viable time series models must have white noise residuals。当前 ARIMA / log-ARIMA 的诊断结果是“混合的”，不能简单写成全部通过。

根据当前保存的模型对象重新检查：

| Series | Model | AIC | Ljung-Box lag 10 p | Ljung-Box lag 20 p | ACF spike count | PACF spike count | Suggested viability |
|---|---|---:|---:|---:|---:|---:|---|
| TFR | ARIMA(1,1,1) | -48.896 | 0.452 | 0.057 | 1 | 3 | Candidate, not final |
| TFR | log-ARIMA(1,1,1) | -127.787 | 0.646 | 0.039 | 2 | 3 | Candidate, not final |
| TFR | ETS(A,Ad,N) | 5.118 | 0.381 | 0.038 | 2 | 2 | Candidate, not final |
| TLB | ARIMA(1,1,1) | 978.031 | 0.710 | 0.021 | 3 | 3 | Candidate, not final |
| TLB | log-ARIMA(1,1,1) | -137.305 | 0.675 | 0.030 | 2 | 2 | Candidate, not final |
| TLB | ETS(A,N,N) | 1055.477 | 0.765 | 0.036 | 2 | 2 | Candidate, not final |
| TFR | auto.arima | -49.618 | 0.312 | 0.039 | 1 | 2 | Candidate, not final |
| TLB | auto.arima | 974.053 | 0.702 | 0.020 | 3 | 3 | Candidate, not final |

解释要点：

- lag-10 Ljung-Box p-value 多数大于 0.05，看起来可以接受。
- 但 lag-20 Ljung-Box p-value 多数小于 0.05 或接近 0.05，说明更长滞后下仍可能存在 autocorrelation。
- ACF/PACF 仍有 spike 超出置信区间。按照 Gerald 的严格标准，这会被认为 residuals are not fully white noise。
- 因此，ARIMA(1,1,1) 和 log-ARIMA(1,1,1) 更适合写成 baseline / candidate models，而不是 final viable models。

还需要特别注意：**original-scale ARIMA 的 AIC 不能和 log-scale ARIMA 的 AIC 直接比较**。例如 TFR ARIMA AIC 为 -48.896，而 TFR log-ARIMA AIC 为 -127.787，这两个数字不在同一 response scale 上，不能用来证明 log-ARIMA 一定更好。它们只能在同一数据尺度内比较。

## 5. ML Model Contribution

当前 ML 部分的实现位于 `code/model_ml.R`，模型包括：

- Random Forest
- XGBoost
- Ridge Regression

使用的特征包括：

- `year`
- `lag1`
- `lag2`
- `lag3`
- `rolling_mean`

更新后，训练和递归预测都使用同一组 `FEATURE_COLUMNS <- c("year", "lag1", "lag2", "lag3", "rolling_mean")`。这修复了之前“表格写了 year，但训练时排除了 year”的不一致问题。

脚本里预测采用 recursive forecasting：每一年预测后，将预测值作为后续年份的 lag 输入。这比直接把测试集真实值泄露到 lag features 中更合理。

ML 模型当前贡献可以这样写进报告：

> To provide non-ARIMA comparison models, we trained Random Forest, XGBoost, and Ridge Regression using year, lagged values, and rolling mean features. These models do not provide AIC, so they were compared using out-of-sample RMSE, MAE, and MAPE on the 2013-2025 test period. For TFR, Ridge Regression achieved the best predictive accuracy, likely because the year feature captures the long-term trend. For TLB, Random Forest achieved the best overall predictive accuracy among the compared models.

中文报告口径可以写为：

> 机器学习模型主要作为 comparison models，而不是直接替代 ARIMA 残差诊断框架。它们的优势在于能捕捉 lag features 中的非线性关系，尤其对 TLB 的预测误差改善明显；但由于样本量只有年度数据 66 个点，模型复杂度需要保持克制，因此目前不建议优先加入 LSTM。

## 6. Current Problems / Not Yet Finished

当前已修复的问题和仍需注意的地方如下：

1. **旧版 `outputs/model_comparison_full.csv` 的硬编码问题已经修复。**

   `code/create_comparison_table.R` 现在会读取保存的 RDS 模型和 forecast CSV，动态计算 RMSE、MAE、MAPE、AIC、lag-10 / lag-20 Ljung-Box p-value、ACF/PACF spike count 和 strict viability。ML 模型现在标为 `Comparison only`，不会再被误写成最终 viable time series model。

2. **ARIMA viability 被高估。**

   当前结果中 lag-10 Ljung-Box 可能通过，但 lag-20 和 ACF/PACF 仍显示 autocorrelation risk。因此报告里应避免写 “ARIMA(1,1,1) is viable” 或 “log-ARIMA is final model”。更稳妥的说法是：ARIMA/log-ARIMA are useful baseline/candidate models, but residual diagnostics are not fully satisfactory under the stricter criterion.

3. **`run_scripts.R` 的重复执行问题已经清理。**

   现在 pipeline 顺序是：preprocessing -> ARIMA/log-ARIMA/auto.arima/ETS -> ML -> comparison table。之前在 `create_comparison_table.R` 之后重复 source log-ARIMA 的问题已经去掉。

4. **`notebooks/forecast-modelling.Rmd` 仍是模板。**

   该 Rmd 目前还包含默认 R Markdown 示例内容，并没有真正呈现 forecasting results。如果要交 Rmd/HTML 报告，需要重写该 notebook；如果时间紧，可以直接用本 Markdown 报告作为文字基础。

5. **Chinese zodiac 尚未进入主模型比较。**

   当前仓库里没有发现 zodiac 变量构造、ARIMAX 模型或 zodiac output 文件。因此 zodiac 部分应写为待整合分析。严格来说，它更像 ARIMA with exogenous regressors / ARIMAX，而不是 Seasonal ARIMA，除非模型中明确设置 seasonal order。

## 7. Recommended Final Reporting Position

建议团队当前采用下面这个结论口径：

> We compared classical time-series models and machine-learning comparison models for forecasting Singapore fertility and live births. For TFR, Ridge Regression with year and lag features produced the strongest predictive accuracy on the 2013-2025 test set, while ETS remained the strongest classical time-series result. For TLB, Random Forest gave the best predictive performance. However, ARIMA/log-ARIMA/ETS residual diagnostics remain mixed: while some Ljung-Box tests at shorter lags are acceptable, ACF/PACF plots and longer-lag Ljung-Box tests suggest remaining autocorrelation. Therefore, ARIMA-family and ETS models should currently be reported as candidate or baseline models rather than final viable models under the strict white-noise residual criterion.

中文版本：

> 本项目已经完成了从数据清洗、探索性分析、传统时间序列建模到机器学习对比模型的主要流程。当前预测结果显示，TFR 上 Ridge Regression 加入 year 和 lag features 后表现最好，ETS 是目前最好的传统时间序列预测结果；TLB 上 Random Forest 表现最好。机器学习模型可以作为有价值的 comparison models，尤其在 TFR 和 TLB 的测试集预测误差上都优于 ARIMA-family baseline。然而，ARIMA、log-ARIMA 和 ETS 的残差诊断仍不完全满足严格 white noise 标准，因此目前不应把它们写成最终 viable model，而应写成 baseline / candidate models。最终报告应同时呈现预测误差和残差诊断，并明确说明 AIC 只能在同一数据尺度内比较。

## 8. Suggested Next Steps for the Team

短期最重要的事情：

1. 使用更新后的 `outputs/model_comparison_full.csv` 作为主比较表，不再使用旧版手填 viability 的结果。
2. 在最终表格中把 ARIMA/log-ARIMA/ETS 标为 `Candidate` 或 `No / Not final`，除非后续找到残差诊断更好的模型。
3. 保留 ML 模型作为 comparison section，并重点强调 TFR 上 Ridge Regression、TLB 上 Random Forest 的预测效果。
4. 对 TFR Ridge 的强结果保持谨慎：它可能主要来自 `year` trend extrapolation，建议在报告中写成 strong comparison baseline，而不是无条件 final model。
5. 若时间允许，尝试更多 ARIMA orders 或 ARIMAX，但必须继续以 residual diagnostics 为主要 viability 标准。
6. Zodiac 部分暂时写成 pending integration；后续若加入，应作为 exogenous regressor，而不是直接称为 Seasonal ARIMA。
7. 不建议优先做 LSTM，因为年度样本量太少，复杂神经网络很容易过拟合，且报告中不容易解释。

## 9. Report-Ready Comparison Table

下面这张表是从更新后的 `outputs/model_comparison_full.csv` 精简出来的报告草稿，避免把尚未通过严格残差诊断的模型写成 final viable：

| Series | Model Type | Model | Scale | Features | AIC | Diagnostic status | RMSE | MAE | MAPE | Report status |
|---|---|---|---|---|---:|---|---:|---:|---:|---|
| TFR | ML | Ridge Regression | original | year, lag1, lag2, lag3, rolling mean | N/A | ML comparison model | 0.065 | 0.046 | 4.53% | strongest TFR predictive result so far |
| TFR | Time series | ETS(A,Ad,N) | original | N/A | 5.118 | mixed residual diagnostics | 0.164 | 0.136 | 13.31% | best TFR classical time-series result |
| TFR | ARIMA | log-ARIMA(1,1,1) | log | N/A | do not compare across scale | mixed residual diagnostics | 0.182 | 0.154 | 15.01% | candidate / baseline |
| TFR | ML | Random Forest | original | year, lag1, lag2, lag3, rolling mean | N/A | ML comparison model | 0.182 | 0.144 | 14.25% | comparison |
| TFR | ML | XGBoost | original | year, lag1, lag2, lag3, rolling mean | N/A | ML comparison model | 0.187 | 0.152 | 14.92% | comparison |
| TFR | ARIMA | ARIMA(1,1,1) | original | N/A | -48.896 | mixed residual diagnostics | 0.264 | 0.229 | 22.17% | candidate / baseline |
| TLB | ML | Random Forest | original | year, lag1, lag2, lag3, rolling mean | N/A | ML comparison model | 3,971 | 2,763 | 8.08% | strongest TLB predictive model |
| TLB | ML | Ridge Regression | original | year, lag1, lag2, lag3, rolling mean | N/A | ML comparison model | 4,594 | 3,423 | 9.94% | comparison |
| TLB | ML | XGBoost | original | year, lag1, lag2, lag3, rolling mean | N/A | ML comparison model | 4,628 | 3,380 | 9.84% | comparison |
| TLB | ARIMA | log-ARIMA(1,1,1) | log | N/A | do not compare across scale | mixed residual diagnostics | 5,612 | 4,356 | 12.55% | candidate / baseline |
| TLB | Time series | ETS(A,N,N) | original | N/A | 1055.477 | mixed residual diagnostics | 5,703 | 4,470 | 12.85% | comparison |
| TLB | ARIMA | ARIMA(1,1,1) | original | N/A | 978.031 | mixed residual diagnostics | 5,914 | 4,729 | 13.54% | candidate / baseline |

## 10. Useful Plot References

可在最终报告中引用以下图：

- TFR trend: `outputs/plots/tfr_trend.png`
- TLB trend: `outputs/plots/tlb_trend.png`
- TFR Ridge actual vs predicted: `outputs/plots/tfr_ridge_actual_vs_predicted.png`
- TFR XGBoost actual vs predicted: `outputs/plots/tfr_xgboost_actual_vs_predicted.png`
- TFR Random Forest actual vs predicted: `outputs/plots/tfr_random_forest_actual_vs_predicted.png`
- TLB Random Forest actual vs predicted: `outputs/plots/tlb_random_forest_actual_vs_predicted.png`
- TLB Ridge actual vs predicted: `outputs/plots/tlb_ridge_actual_vs_predicted.png`
- TLB XGBoost actual vs predicted: `outputs/plots/tlb_xgboost_actual_vs_predicted.png`
- TFR ARIMA residual ACF/PACF: `outputs/plots/tfr_residuals_acf.png`, `outputs/plots/tfr_residuals_pacf.png`
- TFR log-ARIMA residual ACF/PACF: `outputs/plots/tfr_log_residuals_acf.png`, `outputs/plots/tfr_log_residuals_pacf.png`
- TLB ARIMA residual ACF/PACF: `outputs/plots/tlb_residuals_acf.png`, `outputs/plots/tlb_residuals_pacf.png`
- TLB log-ARIMA residual ACF/PACF: `outputs/plots/tlb_log_residuals_acf.png`, `outputs/plots/tlb_log_residuals_pacf.png`

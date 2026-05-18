# TLB ARIMA MODEL SEARCH

library(forecast)

# LOAD CLEAN DATA

train <- read.csv("clean_data/train.csv")
test <- read.csv("clean_data/test.csv")

TLBa <- ts(train$TLB, start = 1960, frequency = 1)

dir.create("outputs/ts_plots/tlb", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/models/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("processed_data", recursive = TRUE, showWarnings = FALSE)

# PLOT ORIGINAL SERIES

png("outputs/ts_plots/tlb/tlb_original_series.png", res = 300, width = 2000, height = 1400)
plot(TLBa, main = "Total Live Births Time Series", ylab = "Total Live Births", xlab = "Year")
dev.off()

# FIRST DIFFERENCING

diff_tlb <- diff(TLBa)

png("outputs/ts_plots/tlb/tlb_first_difference.png", res = 300, width = 2000, height = 1400)
plot(diff_tlb, main = "First Differenced Total Live Births", ylab = "Differenced TLB", xlab = "Year")
dev.off()

png("outputs/ts_plots/tlb/tlb_first_difference_acf.png", res = 300, width = 2000, height = 1400)
acf(diff_tlb, lag.max = 40, main = "ACF of First Differenced TLB")
dev.off()

png("outputs/ts_plots/tlb/tlb_first_difference_pacf.png", res = 300, width = 2000, height = 1400)
pacf(diff_tlb, lag.max = 40, main = "PACF of First Differenced TLB")
dev.off()

# SECOND DIFFERENCING

diff2_tlb <- diff(TLBa, differences = 2)

png("outputs/ts_plots/tlb/tlb_second_difference.png", res = 300, width = 2000, height = 1400)
plot(diff2_tlb, main = "Second Differenced Total Live Births", ylab = "Second Differenced TLB", xlab = "Year")
dev.off()

png("outputs/ts_plots/tlb/tlb_second_difference_acf.png", res = 300, width = 2000, height = 1400)
acf(diff2_tlb, lag.max = 40, main = "ACF of Second Differenced TLB")
dev.off()

png("outputs/ts_plots/tlb/tlb_second_difference_pacf.png", res = 300, width = 2000, height = 1400)
pacf(diff2_tlb, lag.max = 40, main = "PACF of Second Differenced TLB")
dev.off()

# TEST ARIMA MODELS

results <- data.frame()

model_counter <- 1

for (d in c(1, 2)) {
  
  for (p in 8:18) {
    
    for (q in 0:5) {
      
      if ((p + q) < 20) {
        
        model_name <- paste0("tlb_m", model_counter, "_ARIMA_", p, "_", d, "_", q)
        
        cat("\nTesting ", model_name, "\n")
        
        warning_messages <- character()
        
        model <- tryCatch(
          withCallingHandlers(
            arima(TLBa, order = c(p, d, q)),
            warning = function(w) {
              warning_messages <<- c(warning_messages, conditionMessage(w))
              invokeRestart("muffleWarning")
            }
          ),
          error = function(e) NULL
        )
        
        if (!is.null(model)) {
          
          aic <- AIC(model)
          
          lb <- Box.test(
            model$residuals,
            lag = 20,
            type = "Ljung-Box",
            fitdf = p + q
          )
          
          pred <- predict(model, n.ahead = nrow(test))
          
          forecast_values <- as.numeric(pred$pred)
          
          rmse <- sqrt(mean((test$TLB - forecast_values)^2))
          mae <- mean(abs(test$TLB - forecast_values))
          
          has_warning <- length(warning_messages) > 0
          
          warning_text <- ifelse(
            has_warning,
            paste(warning_messages, collapse = " | "),
            ""
          )
          
          results <- rbind(
            results,
            data.frame(
              model_name = model_name,
              p = p,
              d = d,
              q = q,
              parameter_count = p + q,
              AIC = aic,
              LjungBox_p = lb$p.value,
              RMSE = rmse,
              MAE = mae,
              has_warning = has_warning,
              warning_text = warning_text
            )
          )
          
          saveRDS(
            model,
            paste0("outputs/models/raw/", model_name, ".rds")
          )
          
          model_counter <- model_counter + 1
        }
      }
    }
  }
}

# SORT RESULTS

results <- results[order(results$RMSE, results$AIC), ]

write.csv(
  results,
  "processed_data/tlb_arima_model_search_results.csv",
  row.names = FALSE
)

# FILTER VALID MODELS

valid_results <- subset(
  results,
  LjungBox_p > 0.05 & has_warning == FALSE
)

valid_results <- valid_results[order(valid_results$RMSE, valid_results$AIC), ]

print(valid_results)

write.csv(
  valid_results,
  "processed_data/tlb_arima_valid_models.csv",
  row.names = FALSE
)

cat("\nTLB ARIMA model search complete.\n")
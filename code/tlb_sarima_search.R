# TLB CORRECTED SARIMA MODEL SEARCH
# Corrected after client feedback: seasonal differencing D = 1

library(forecast)

train <- read.csv("clean_data/train.csv")
test <- read.csv("clean_data/test.csv")

TLBa <- ts(train$TLB, start = min(train$year), frequency = 1)

dir.create("outputs/models/sarima", recursive = TRUE, showWarnings = FALSE)
dir.create("processed_data", recursive = TRUE, showWarnings = FALSE)

results <- data.frame()
model_counter <- 1

for (p in 0:3) {
  for (q in 0:3) {
    for (P in 0:2) {
      for (Q in 0:2) {
        
        d <- 1
        D <- 1
        period <- 12
        
        parameter_count <- p + q + P + Q
        
        if (parameter_count > 0 && parameter_count <= 6) {
          
          model_name <- paste0(
            "tlb_sarima_",
            model_counter,
            "_", p, "_", d, "_", q,
            "_", P, "_", D, "_", Q,
            "_12"
          )
          
          model_label <- paste0(
            "SARIMA(",
            p, ",", d, ",", q,
            ")(",
            P, ",", D, ",", Q,
            ")[12]"
          )
          
          cat("\nTesting ", model_label, "\n")
          
          warning_messages <- character()
          
          model <- tryCatch(
            withCallingHandlers(
              Arima(
                TLBa,
                order = c(p, d, q),
                seasonal = list(order = c(P, D, Q), period = period),
                include.constant = FALSE
              ),
              warning = function(w) {
                warning_messages <<- c(warning_messages, conditionMessage(w))
                invokeRestart("muffleWarning")
              }
            ),
            error = function(e) NULL
          )
          
          if (!is.null(model)) {
            
            forecast_result <- forecast(model, h = nrow(test))
            forecast_values <- as.numeric(forecast_result$mean)
            
            rmse <- sqrt(mean((test$TLB - forecast_values)^2, na.rm = TRUE))
            mae <- mean(abs(test$TLB - forecast_values), na.rm = TRUE)
            
            lb <- Box.test(
              residuals(model),
              lag = 20,
              type = "Ljung-Box",
              fitdf = parameter_count
            )
            
            has_warning <- length(warning_messages) > 0
            
            results <- rbind(
              results,
              data.frame(
                model_name = model_name,
                model = model_label,
                p = p,
                d = d,
                q = q,
                P = P,
                D = D,
                Q = Q,
                period = period,
                parameter_count = parameter_count,
                AIC = AIC(model),
                LjungBox_p = lb$p.value,
                RMSE = rmse,
                MAE = mae,
                has_warning = has_warning,
                warning_text = paste(warning_messages, collapse = " | ")
              )
            )
            
            saveRDS(
              model,
              paste0("outputs/models/sarima/", model_name, ".rds")
            )
            
            model_counter <- model_counter + 1
          }
        }
      }
    }
  }
}

results <- results[order(results$RMSE, results$AIC), ]

write.csv(
  results,
  "processed_data/tlb_sarima_search_results.csv",
  row.names = FALSE
)

valid_results <- subset(
  results,
  LjungBox_p > 0.05 & has_warning == FALSE
)

valid_results <- valid_results[order(valid_results$RMSE, valid_results$AIC), ]

print(valid_results)

write.csv(
  valid_results,
  "processed_data/tlb_sarima_valid_models.csv",
  row.names = FALSE
)

cat("\nTLB SARIMA model search complete.\n")
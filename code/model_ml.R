# Machine Learning Models for TFR and TLB Prediction
# Implements Random Forest, XGBoost, and Ridge Regression as comparison models.

library(tidyverse)
library(caret)
library(xgboost)
library(randomForest)
library(Metrics)  # for RMSE, MAE, MAPE

set.seed(123)

FEATURE_COLUMNS <- c("year", "lag1", "lag2", "lag3", "rolling_mean")

# Function to create features for ML
create_features <- function(data, target_col, lag = 3) {
  data <- data %>% arrange(year)
  for (i in 1:lag) {
    data <- data %>% mutate(!!paste0("lag", i) := lag(!!sym(target_col), i))
  }
  data <- data %>% mutate(rolling_mean = (lag1 + lag2 + lag3) / 3)
  data <- data %>% drop_na()  # remove rows with NA lags
  return(data)
}

# Load data
tfr_train <- read_csv("data/clean_data/tfr_train.csv", show_col_types = FALSE) %>% select(year, TFR)
tfr_test <- read_csv("data/clean_data/tfr_test.csv", show_col_types = FALSE) %>% select(year, TFR)
tlb_train <- read_csv("data/clean_data/tlb_train.csv", show_col_types = FALSE) %>% select(year, TLB)
tlb_test <- read_csv("data/clean_data/tlb_test.csv", show_col_types = FALSE) %>% select(year, TLB)

# Create features for training. Test features are generated recursively below,
# so future actual values are not leaked into lag features.
tfr_train_feat <- create_features(tfr_train, "TFR")
tlb_train_feat <- create_features(tlb_train, "TLB")

model_slug <- function(model_name) {
  slug <- tolower(gsub("[^A-Za-z0-9]+", "_", model_name))
  gsub("^_|_$", "", slug)
}

predict_recursive <- function(model, train_data, test_data, target_col, feature_columns, is_xgb = FALSE) {
  last_train <- tail(train_data, 1)
  predictions <- numeric(nrow(test_data))
  current <- last_train %>% select(all_of(target_col), lag1, lag2, lag3)

  for (i in 1:nrow(test_data)) {
    # Create features for current prediction
    feat <- data.frame(
      year = test_data$year[i],
      lag1 = current[[target_col]],
      lag2 = current$lag1,
      lag3 = current$lag2,
      rolling_mean = (current[[target_col]] + current$lag1 + current$lag2) / 3
    ) %>%
      select(all_of(feature_columns)) %>%
      as.data.frame()

    if (is_xgb) {
      pred <- predict(model, as.matrix(feat))
    } else {
      pred <- predict(model, feat)
    }

    predictions[i] <- as.numeric(pred)[1]

    # Update current for next iteration
    current <- data.frame(predictions[i], current[[target_col]], current$lag1, current$lag2)
    names(current) <- c(target_col, "lag1", "lag2", "lag3")
  }
  return(predictions)
}

# Function to train and evaluate models
train_and_evaluate <- function(train_feat, test_data, target_col, series_name, feature_columns = FEATURE_COLUMNS) {
  # Prepare training data
  X_train <- train_feat %>%
    select(all_of(feature_columns)) %>%
    as.data.frame()
  y_train <- train_feat[[target_col]]
  xgb_train <- xgb.DMatrix(data = as.matrix(X_train), label = y_train)

  # Models
  models <- list(
    "Random Forest" = randomForest(x = X_train, y = y_train, ntree = 500, importance = TRUE),
    "XGBoost" = xgb.train(
      params = list(
        objective = "reg:squarederror",
        max_depth = 2,
        learning_rate = 0.05,
        subsample = 1,
        colsample_bytree = 1
      ),
      data = xgb_train,
      nrounds = 100,
      verbose = 0
    ),
    "Ridge" = train(
      X_train,
      y_train,
      method = "glmnet",
      tuneGrid = expand.grid(alpha = 0, lambda = seq(0.001, 1, length = 10)),
      trControl = trainControl(method = "LOOCV")
    )
  )

  results <- list()
  metric_rows <- list()

  for (model_name in names(models)) {
    model <- models[[model_name]]

    # Predict on test
    if (model_name == "XGBoost") {
      predictions <- predict_recursive(model, train_feat, test_data, target_col, feature_columns, is_xgb = TRUE)
    } else {
      predictions <- predict_recursive(model, train_feat, test_data, target_col, feature_columns, is_xgb = FALSE)
    }

    # Calculate metrics
    actual <- test_data[[target_col]]
    rmse <- rmse(actual, predictions)
    mae <- mae(actual, predictions)
    mape <- mape(actual, predictions) * 100  # percentage

    results[[model_name]] <- list(
      predictions = predictions,
      rmse = rmse,
      mae = mae,
      mape = mape
    )

    metric_rows[[model_name]] <- tibble(
      Series = series_name,
      Model_Type = "ML",
      Model = if_else(model_name == "Ridge", "Ridge Regression", model_name),
      Features = paste(feature_columns, collapse = ", "),
      RMSE = rmse,
      MAE = mae,
      MAPE = mape
    )

    saveRDS(model, paste0("outputs/models/", tolower(series_name), "_", model_slug(model_name), ".rds"))

    # Save predictions
    pred_df <- data.frame(
      year = test_data$year,
      actual = actual,
      predicted = predictions
    )
    write_csv(pred_df, paste0("outputs/forecasts/", tolower(series_name), "_", model_slug(model_name), ".csv"))

    # Plot actual vs predicted
    png(
      paste0("outputs/plots/", tolower(series_name), "_", model_slug(model_name), "_actual_vs_predicted.png"),
      width = 900,
      height = 600
    )
    plot(test_data$year, actual, type = "l", col = "blue", xlab = "Year", ylab = target_col, main = paste(series_name, model_name, "Actual vs Predicted"))
    lines(test_data$year, predictions, col = "red")
    legend("topright", legend = c("Actual", "Predicted"), col = c("blue", "red"), lty = 1)
    dev.off()
  }

  return(list(results = results, metrics = bind_rows(metric_rows)))
}

# Run for TFR
tfr_results <- train_and_evaluate(tfr_train_feat, tfr_test, "TFR", "TFR")

# Run for TLB
tlb_results <- train_and_evaluate(tlb_train_feat, tlb_test, "TLB", "TLB")

ml_metrics <- bind_rows(tfr_results$metrics, tlb_results$metrics)
write_csv(ml_metrics, "outputs/model_comparison_ml.csv")

# Print results
cat("TFR Results:\n")
for (model in names(tfr_results$results)) {
  cat(model, ": RMSE =", tfr_results$results[[model]]$rmse, ", MAE =", tfr_results$results[[model]]$mae, ", MAPE =", tfr_results$results[[model]]$mape, "%\n")
}

cat("\nTLB Results:\n")
for (model in names(tlb_results$results)) {
  cat(model, ": RMSE =", tlb_results$results[[model]]$rmse, ", MAE =", tlb_results$results[[model]]$mae, ", MAPE =", tlb_results$results[[model]]$mape, "%\n")
}

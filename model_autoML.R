# #### config #####
# load("data/feature_engg_output.RData")
#
h2o.init()
# 
# #### train #####
# train_h2o <- as.h2o(train_data)
# test_h2o  <- as.h2o(test_data)
# 
# date_var <- "date"
# y <- "ride_count"
# x <- setdiff(names(train_h2o), c(y, date_var))
# 
# automl_models_h2o <- h2o.automl(
#   x = x, 
#   y = y, 
#   training_frame = train_h2o, 
#   max_runtime_secs = 0,
#   exclude_algos = c("DeepLearning", "StackedEnsemble"),
#   seed = 123)
# 
# save(automl_models_h2o, train_h2o, test_h2o,  file="models/h2o_model.RData")

##### predict #####
load("models/h2o_model.RData")

automl_leader <- automl_models_h2o@leader

train_pred_h2o <- h2o.predict(automl_leader, newdata = train_h2o)

train_pred_df_h2o <- train_data %>%
  add_column(ride_count_pred = train_pred_h2o %>% as_tibble() %>% pull(predict)) %>%
  mutate(ride_count_pred = ifelse(ride_count_pred<0, 0, ride_count_pred)) %>% 
  rename(ride_count_actual = ride_count)

test_pred_h2o <- h2o.predict(automl_leader, newdata = test_h2o)

test_pred_df_h2o <- test_data %>%
  add_column(ride_count_pred = test_pred_h2o %>% as_tibble() %>% pull(predict)) %>%
  mutate(ride_count_pred = ifelse(ride_count_pred<0, 0, ride_count_pred)) %>% 
  rename(ride_count_actual = ride_count)

save(automl_models_h2o, train_h2o, test_h2o, train_pred_df_h2o, test_pred_df_h2o, file="models/h2o_all.RData")

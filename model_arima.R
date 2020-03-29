# ##### train #####
# load("data/rides_cont.RData")
# 
# get_arima_model <- function(x) {
#   z <- fourier(x, K=c(2,5))
#   fit <- auto.arima(x, xreg=z, seasonal=FALSE)
# }
# 
# ls_arima_model <- mclapply(ls_cont_train_msts, get_arima_model)
# 
# save(ls_arima_model, rides_cont_train, ls_cont_train_msts, rides_cont_test, ls_cont_test_msts, file="models/arima_model.RData")

##### predict #####
load("models/arima_model.RData")

get_arima_predictions <- function(i) {
  y = ls_cont_train_msts[[i]]
  y_test = ls_cont_test_msts[[i]]
  zf <- fourier(y, K=c(2,5), h=length(y_test))
  fc <- forecast(ls_arima_model[[i]], xreg=zf, h=length(y_test))
  return(fc)
}

ls_train_pred_arima <- mclapply(ls_arima_model, function(x) as.numeric(x$fitted))

ls_test_pred_obj_arima <- mclapply(1:length(ls_arima_model), get_arima_predictions)
ls_test_pred_arima <- mclapply(ls_test_pred_obj_arima, function(x) as.numeric(x$mean))
names(ls_test_pred_arima) = names(ls_arima_model)


##### prep. predictions #####
get_pred_df <- function(i, pred_list, base_df) {
  pred = pred_list[[i]]
  base_df %>% 
    dplyr::filter(WARD_NAME == names(pred_list)[i]) %>% 
    mutate(ride_count_pred = ifelse(pred< 0, 0, pred)) %>% 
    rename(ride_count_actual = ride_count)
}

train_pred_df_arima <- bind_rows(lapply(1:length(ls_train_pred_arima), function(x) get_pred_df(x, ls_train_pred_arima, rides_cont_train)))

test_pred_df_arima <- bind_rows(lapply(1:length(ls_test_pred_arima), function(x) get_pred_df(x, ls_test_pred_arima, rides_cont_test)))

save(ls_arima_model, train_pred_df_arima, test_pred_df_arima, file="models/arima_all.RData")



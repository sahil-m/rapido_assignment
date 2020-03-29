load("data/rides_cont.RData")

central_measure_models <- rides_cont_train %>% 
  group_by(WARD_NAME) %>% 
  summarise(ride_count_mean = mean(ride_count),
            ride_count_median = median(ride_count)) %>% 
  ungroup()

naive_seasonal_model <- rides_cont_all %>% 
  group_by(WARD_NAME) %>% 
  mutate(day_of_week = as.character(wday(date, label = TRUE, abbr = TRUE))) %>% 
  mutate(ride_count_day_lag = dplyr::lag(ride_count, 24),
         ride_count_week_lag = dplyr::lag(ride_count, 24*7),
         ride_count_smart_lag = ifelse(day_of_week %in% c("Sat", "Sun", "Mon"), ride_count_week_lag, ride_count_day_lag)) %>% 
  ungroup()


all_pred_df_baseline <- naive_seasonal_model %>% 
  left_join(central_measure_models, by = "WARD_NAME")


test_start_date <- ymd("2019-04-01")

train_pred_df_baseline <- all_pred_df_baseline %>% 
  filter(date < test_start_date)

test_pred_df_baseline <- all_pred_df_baseline %>% 
  filter(date >= test_start_date)


save(all_pred_df_baseline, train_pred_df_baseline, test_pred_df_baseline, file = "models/baseline_all.RData")

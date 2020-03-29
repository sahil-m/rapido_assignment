get_prophet_model <- function(df, holidays_df=holidays_2019) {
  formatted_data <- df %>% 
    rename('ds' = date_time,  'y'=ride_count)
  
  national_holidays <- data_frame(
    holiday = 'national_holidays',
    ds = holidays_df$date
  )
  
  m <- prophet(yearly.seasonality = FALSE, weekly.seasonality = FALSE, daily.seasonality = FALSE, holidays.prior.scale = 1, changepoint.prior.scale = 0.07, growth = "linear", holidays = national_holidays) %>%
    add_seasonality(name = "daily", period = 1, fourier.order = 20, prior.scale = 25) %>%
    add_seasonality(name = "weekly", period = 7, fourier.order = 10, prior.scale = 10) %>%
    add_regressor("AREA_SQ_KM") %>% 
    add_regressor("POP_TOTAL") %>% 
    add_regressor("pop_density") %>% 
    fit.prophet(formatted_data)
  
  return(m)
}




data_for_prophet <- rides_for_model %>% 
  mutate(date_time = ymd_hms(paste(date, " ", hour_of_day, ":00:00")))

train_data_prophet <- data_for_prophet %>% 
  filter(date < test_start_date)

test_data_prophet <- data_for_prophet %>% 
  filter(date >= test_start_date)

ls_data_for_prophet <- group_split(data_for_prophet, WARD_NAME)

ls_train_for_prophet <- group_split(train_data_prophet, WARD_NAME)

ls_test_for_prophet <- group_split(test_data_prophet, WARD_NAME)

holidays_2019 <- read_csv("data/nationalholidaysindia/2019.csv") %>% 
  mutate(is_holiday_but_not_weekend = ifelse(day %in% c("Saturday", "Sunday"), FALSE, TRUE)) %>% 
  dplyr::select(date, is_holiday_but_not_weekend)

# mclapply(ls_train_for_prophet, get_prophet_model)

m = get_prophet_model(ls_train_for_prophet[[1]])
train_pred = predict(m)
plot(m, train_pred)

future_data_formatted <- ls_test_for_prophet[[1]] %>% 
  rename('ds' = date_time)

future <- make_future_dataframe(m, periods = nrow(future_data_formatted), freq = 60 * 60, include_history = FALSE) %>%
  left_join(future_data_formatted, by="ds")

fcst <- predict(m, future)

##########
test_prediction <- ls_test_for_prophet[[1]] %>% 
  mutate(ride_count_pred = ifelse(fcst$yhat < 0, 0, fcst$yhat)) %>% 
  rename(ride_count_actual = ride_count) 

test_prediction_long <- test_prediction %>% 
  pivot_longer(c("ride_count_actual", "ride_count_pred"), names_prefix = "ride_count_", names_to = "value_type", values_to = "ride_count")


ggplotly(
  ggplot(test_prediction_long, aes(x = date_time, y = ride_count, group = value_type, color = value_type)) +
    geom_line()
)

test_evaluation <- test_prediction %>% 
  mutate(ride_count_actual_new = ifelse(ride_count_actual == 0, 1, ride_count_actual),
         errors_abs = abs(ride_count_actual - ride_count_pred),
         errors_percent = round(errors_abs/ride_count_actual_new*100, 2)) %>% 
  group_by(WARD_NAME) %>% 
  summarise(MAE = mean(errors_abs),
            median_APE = median(errors_percent),
            MAPE = mean(errors_percent),
            sd_actual = sd(ride_count_actual)) %>% 
  ungroup() %>% 
  mutate(SDMAE = round(MAE/sd_actual, 2))

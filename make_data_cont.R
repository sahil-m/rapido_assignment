################# Make data continuous #############
rides_cont_all <- rides_latest %>% 
  dplyr::select(date, hour_of_day, WARD_NAME, ride_count) %>% 
  group_by(WARD_NAME) %>% 
  complete(date = seq.Date(min(date), max(date), by="day"), hour_of_day = 0:23, fill = list(ride_count = 0)) %>% 
  ungroup()

check_if_date_is_continuous(rides_cont_all, WARD_NAME, date)

################## split ##################
test_start_date <- ymd("2019-04-01")

rides_cont_train <- rides_cont_all %>% 
  filter(date < test_start_date)

rides_cont_test <- rides_cont_all %>% 
  filter(date >= test_start_date)

################## convert to msts ################## 
##### train
ls_cont_train_msts <- rides_cont_train %>% 
  group_by(WARD_NAME) %>% 
  arrange(date, hour_of_day) %>% 
  group_map(~msts(.x$ride_count, seasonal.periods = c(24, 24*7)))

ward_names_train <- rides_cont_train %>% 
  group_by(WARD_NAME) %>% 
  summarise() %>% 
  ungroup()

names(ls_cont_train_msts) = ward_names_train$WARD_NAME

##### test
ls_cont_test_msts <- rides_cont_test %>% 
  group_by(WARD_NAME) %>% 
  arrange(date, hour_of_day) %>% 
  group_map(~msts(.x$ride_count, seasonal.periods = c(24, 24*7)))

ward_names_test <- rides_cont_test%>% 
  group_by(WARD_NAME) %>% 
  summarise() %>% 
  ungroup()

names(ls_cont_test_msts) = ward_names_test$WARD_NAME

##### all
ls_cont_all_msts <- rides_cont_all %>% 
  group_by(WARD_NAME) %>% 
  arrange(date, hour_of_day) %>% 
  group_map(~msts(.x$ride_count, seasonal.periods = c(24, 24*7)))

ward_names_all <- rides_cont_all %>% 
  group_by(WARD_NAME) %>% 
  summarise() %>% 
  ungroup()

names(ls_cont_all_msts) = ward_names_all$WARD_NAME

save(rides_cont_all, rides_cont_train, rides_cont_test, ls_cont_all_msts, ls_cont_train_msts, ls_cont_test_msts, file = "data/rides_cont.RData")
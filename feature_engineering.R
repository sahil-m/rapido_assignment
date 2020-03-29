################## reads, imports, and helper functions ##################
first_day_of_month_wday <- function(date) {
  lubridate::day(date) <- 1
  lubridate::wday(date)
}

week_of_month <- function(date) {
  ceiling((lubridate::day(date) + first_day_of_month_wday(date) - 1) / 7)
}

add_date_based_features <- function(df, date_variable) {
  return(
    df %>% 
      mutate(
        day_of_week = as.character(wday({{date_variable}}, label = TRUE, abbr = TRUE)),
        day_of_week_bucket = ifelse(day_of_week %in% c("Mon", "Tue", "Wed", "Thu", "Fri"), "weekday", day_of_week),
        month = lubridate::month({{date_variable}}),
        day_of_month = mday({{date_variable}}),
        day_of_year = yday({{date_variable}}),
        week_of_month = week_of_month({{date_variable}}),
        week_of_month_plain = ceiling(day_of_month/7),
        label = paste({{date_variable}}, 'week', week_of_month, day_of_week, sep = '_')
      )
  )
}
  
################## create ts features, using STR ################## 
##### Data. prep. for STR training
ls_cont_forTrain_msts <- lapply(1:length(ls_cont_all_msts), function(i) {
  test_length <- length(ls_cont_test_msts[[i]])
  forTrain_msts = ls_cont_all_msts[[i]]
  forTrain_msts[(length(forTrain_msts)-test_length+1):length(forTrain_msts)] <- NA
  return(forTrain_msts)
})

names(ls_cont_forTrain_msts) = names(ls_cont_all_msts)

##### build STR model
ls_STR_model <- lapply(ls_cont_forTrain_msts, AutoSTR, robust = TRUE)

# all(sapply(ls_STR_model, function(x) sum(is.na(x$output$predictors[[3]]$data))) == 0)

##### extract STR components
extract_str_features <- function(i) {
  str_components = ls_STR_model[[i]]$output$predictors
  
  WARD_NAME <- names(ls_cont_forTrain_msts)[i]
  
  rides_cont_all[rides_cont_all$WARD_NAME == WARD_NAME, c("date", "hour_of_day")] %>% 
    mutate(WARD_NAME = WARD_NAME,
           trend = str_components[[1]]$data,
           season_1 = str_components[[2]]$data,
           season_2 = str_components[[3]]$data)
  
}

ls_STR_components <- map(1:length(ls_STR_model), extract_str_features)

STR_features <- bind_rows(ls_STR_components)

##### add extracted STR components as features
rides_withSTRFeatures_all <- rides_cont_all %>% 
  left_join(STR_features, by = c("date", "hour_of_day", "WARD_NAME"))

save(ls_cont_forTrain_msts, ls_STR_model, rides_withSTRFeatures_all, file = "data/STR.RData")

################## create date level features ################## 
rides_withFeatures_all <- add_date_based_features(rides_withSTRFeatures_all, date)

nrow(rides_withFeatures_all) == nrow(rides_cont_all)


################## region specific features ################## 
bbmp_wards_sel_clustered_df <- dplyr::select(bbmp_wards_sel_clustered, WARD_NAME, POP_TOTAL, AREA_SQ_KM)
st_geometry(bbmp_wards_sel_clustered_df) <- NULL

rides_withFeatures_all <- rides_withFeatures_all %>% 
  left_join(bbmp_wards_sel_clustered_df, by = "WARD_NAME")

nrow(rides_withFeatures_all) == nrow(rides_cont_all)

################## holidays ################## 
holidays_2019 <- read_csv("data/nationalholidaysindia/2019.csv") %>% 
  mutate(is_holiday_but_not_weekend = ifelse(day %in% c("Saturday", "Sunday"), FALSE, TRUE)) %>% 
  dplyr::select(date, is_holiday_but_not_weekend)

rides_withFeatures_all <- rides_withFeatures_all %>% 
  left_join(holidays_2019, by = "date") %>% 
  mutate(is_holiday_but_not_weekend = ifelse(is.na(is_holiday_but_not_weekend), FALSE, is_holiday_but_not_weekend))

nrow(rides_withFeatures_all) == nrow(rides_cont_all)

################## misc. feature engg. ##################
rides_for_model <- rides_withFeatures_all %>% 
  mutate(pop_density = POP_TOTAL/AREA_SQ_KM) %>% 
  dplyr::select(-contains("week_of_month"), -label)

count_nas(rides_for_model)

train_data <- rides_for_model %>% 
  filter(date < test_start_date)

test_data <- rides_for_model %>% 
  filter(date >= test_start_date)


################## save ##################
save(rides_for_model, train_data, test_data,  file="data/feature_engg_output.RData")

  
  
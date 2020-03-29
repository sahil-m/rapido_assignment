count_nas <- function(df) {
  data.frame(NA_count = sapply(df, function(x) sum(is.na(x))))
}

check_if_date_is_continuous <- function(df, group_var, date_var) {
  df_check <- df %>% 
    group_by({{group_var}}) %>% 
    summarise(min_date = min({{date_var}}),
              max_date = max({{date_var}}),
              unique_dates_in_data = n_distinct({{date_var}}),
              span = as.numeric(max_date - min_date) + 1,
              is_cont = (span == unique_dates_in_data)) %>% 
    ungroup()
  
  return(all(df_check$is_cont))
}



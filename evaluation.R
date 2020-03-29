get_eval_metric_by_region_for_baseline <- function(test_pred_df, actual_var, pred_var, suffix) {
  test_pred_df %>% 
    mutate(ride_count_actual_new = ifelse({{actual_var}} == 0, 1, {{actual_var}}),
           errors_abs = abs({{actual_var}} - {{pred_var}}),
           errors_percent = round(errors_abs/ride_count_actual_new*100, 2)) %>% 
    group_by(WARD_NAME) %>% 
    summarise("MAE_{suffix}" := mean(errors_abs),
              "median_APE_{suffix}" := median(errors_percent),
              "MAPE_{suffix}" := mean(errors_percent),
              "SDMAE_{suffix}" := round(mean(errors_abs)/sd({{actual_var}}), 2)) %>% 
    ungroup() 
}


get_eval_metric_by_region_for_nonBaseline <- function(test_pred_df, actual_var, pred_var, baseline_pred_df, pred_var_baseline) {
  test_pred_df %>% 
    mutate(ride_count_actual_new = ifelse({{actual_var}} == 0, 1, {{actual_var}}),
           errors_abs = abs({{actual_var}} - {{pred_var}}),
           errors_percent = round(errors_abs/ride_count_actual_new*100, 2)) %>% 
    group_by(WARD_NAME) %>% 
    summarise(MAE = mean(errors_abs),
              median_APE = median(errors_percent),
              MAPE = mean(errors_percent),
              SDMAE := round(mean(errors_abs)/sd({{actual_var}}), 2)) %>% 
    ungroup() %>% 
    left_join(baseline_pred_df, by = "WARD_NAME") %>% 
    mutate(MAE_r2 = round((1 - MAE/{{pred_var_baseline}}), 2))
  
}


# compare_predictions <- function(pred1_df, pred2_df, pred_level_var="WARD_NAME", model_names = c("m1", "m2"), prediction_var = "prediction") {
#   model_suffix = paste("_", model_names, sep="")
#   pred_df <- inner_join(pred1_df, pred2_df, by=pred_level_var, suffix = model_suffix)
#   
#   prediction_cols = paste(prediction_var, model_suffix, sep="")
#   pred_df$pred_diff = pred_df[[prediction_cols[1]]] - pred_df[[prediction_cols[2]]]
#   
#   p = ggplotly(
#     ggplot(pred_df, aes(x = pred_diff)) +
#       geom_density(fill = "gray52", alpha = .5) +
#       geom_vline(xintercept = mean(pred_df$pred_diff, na.rm=TRUE), linetype = "dashed")
#   )
#   
#   return(list(p = p, diff_summary = summary(pred_df$pred_diff)))
# }




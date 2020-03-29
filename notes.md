# to-do
- download bangalore shape file
- shape file to -> sf multipoygon using st_read

# Future Changes
- round trip hypothesis
- clustering lat-longs
- removing data before 2019
- outliers in ride count - handle in a better way
- feature engineering

# Data Flow
## Blueprint
- Name of the section
- pre-requisite data
- data generated
  - action_1: not required further, and not time consuming to generate - remove
  - action_2: not required further, but time consuming to generate - save and remove - can be loaded before the section is executed again, and the respective generation code can be commented 
  - action_3: required further - save, don't remove
- saving_required->removing_all->loading_required (-all + req) vs saving_required->removing_non_required (-(all - req))

## Pipeline 
read_data (output) -> 
basic_cleaning (output) -> 
basic_analysis (no output) -> 
reduce_granularity_or_add_region (output) (have source) ->
region_grouping (output) (have source) ->
temporal_grouping (no output) ->    
feature_engineering (output) (source) -> 
models
    autoML (output) (source) ->
    Prophet (output) (source) ->
results (output) (source) ->

## basic cleaning
rides_data, rides_data_dedup, rides_data_orot

```{r}
# removing unnecessary data
rm(rides_data, rides_data_dedup)
save(rides_data_orot, file="data/rides_data_orot.RData")
```
## time analysis
rides_per_day, rides_by_time_recent, rides_per_day_long
 
```{r}
# removing unnecessary data
save(rides_per_day, rides_by_time_recent, rides_per_day_long, file="data/rides_by_time.RData")
rm(rides_per_day, rides_by_time_recent, rides_per_day_long)
```
## customer analysis
rides_by_customer, rides_by_customer_sample
    action_1: 
    action_2: rides_by_customer, rides_by_customer_sample
    action_3: 
```{r}
# removing unnecessary data
save(rides_by_customer, rides_by_customer_sample, file="rides_by_customer.RData")
rm(rides_by_customer, rides_by_customer_sample)
```
## geo analysis
rides_data_long, by_pick_or_drop
    action_1: 
    action_2: rides_data_long, by_pick_or_drop
    action_3: 
```{r}
# removing unnecessary data
save(rides_data_long, by_pick_or_drop, file="data/ride_by_geo.RData")
rm(rides_data_long, by_pick_or_drop)
```

## reduce granularity
rides_roundCoord_dateHour, rides_by_latLong,
bbmp_muncipal_wards, bbmp_muncipal_wards_xy,
rides_roundCoord_dateHour -> rides_point_latLong, point_geo, point_geo_xy,
point_geo_within_xy, point_geo_within, point_geo_within_coord,
rides_roundCoord_dateHour, point_geo_within_coord -> rides_outside, rides_Bangalore, rides_Bangalore_byHourRegion, rides_Bangalore_byRegion,
bbmp_muncipal_wards, rides_Bangalore_byRegion -> bbmp_muncipal_wards_sel
functions: sfc_as_cols

```{r}
# removing unnecessary data
save(bbmp_muncipal_wards_sel, rides_Bangalore_byHourRegion, file="data/regions.RData")
rm(rides_roundCoord_dateHour, rides_by_latLong,
bbmp_muncipal_wards, bbmp_muncipal_wards_xy,
rides_point_latLong, point_geo, point_geo_xy,
point_geo_within_xy, point_geo_within, point_geo_within_coord,  
rides_outside, rides_Bangalore, rides_Bangalore_byRegion)
```

## combine regions
ride_count_threshold, bbmp_muncipal_wards_sel_xy, bbmp_sel_ward_geo, bbmp_sel_ward_names, bbmp_sel_ward_names_comb, bbmp_sel_ward_names_comb_1, bbmp_sel_ward_names_comb_2, bbmp_sel_ward_1, bbmp_sel_ward_2, bbmp_wards_for_matching, edge_df, network, network_components, ward_clusters, bbmp_muncipal_wards_sel_withClusters, bbmp_wards_sel_clustered, cluster_lon, cluster_lat, rides_Bangalore_byHourRegion_new, rides_Bangalore_byRegion_new, rides_Bangalore_byDateRegion_new


```{r}
# removing unnecessary data
save(rides_Bangalore_byHourRegion_new, bbmp_wards_sel_clustered, file = "data/combine_regions.RData")
rm(ride_count_threshold, bbmp_muncipal_wards_sel_xy, bbmp_sel_ward_geo, bbmp_sel_ward_names, bbmp_sel_ward_names_comb, bbmp_sel_ward_names_comb_1, bbmp_sel_ward_names_comb_2, bbmp_sel_ward_1, bbmp_sel_ward_2, bbmp_wards_for_matching, edge_df, network, network_components, ward_clusters, bbmp_muncipal_wards_sel_withClusters, cluster_lon, cluster_lat, rides_Bangalore_byRegion_new, rides_Bangalore_byDateRegion_new)
```
## temporal grouping
rides_latest, rides_latest_byHour, rides_latest_collapsed_on_date

action_1: rides_latest, rides_latest_byHour, rides_latest_collapsed_on_date
action_2: 
action_3: 

```{r}
# removing unnecessary data
rm(rides_per_day, rides_by_time_recent, rides_per_day_long)
```

# feature engg. + split
rides_latest
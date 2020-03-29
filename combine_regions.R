# get clusters
ride_count_threshold <- quantile(1:quantile(bbmp_muncipal_wards_sel$ride_count, .9), .05)

bbmp_muncipal_wards_sel_xy <- st_transform(bbmp_muncipal_wards_sel, crs = 7780)

bbmp_sel_ward_geo <- dplyr::select(bbmp_muncipal_wards_sel_xy, WARD_NAME, geometry, POP_TOTAL, AREA_SQ_KM, ride_count)

bbmp_sel_ward_names <- as.character(bbmp_muncipal_wards_sel_xy$WARD_NAME)
bbmp_sel_ward_names_comb <- combn(bbmp_sel_ward_names, 2)

bbmp_sel_ward_names_comb_1 <- bbmp_sel_ward_names_comb[1,]
bbmp_sel_ward_1 <- left_join(data.frame(WARD_NAME = bbmp_sel_ward_names_comb_1), bbmp_sel_ward_geo)

bbmp_sel_ward_names_comb_2 <- bbmp_sel_ward_names_comb[2,]
bbmp_sel_ward_2 <- left_join(data.frame(WARD_NAME = bbmp_sel_ward_names_comb_2), bbmp_sel_ward_geo)

bbmp_wards_for_matching <- bind_cols(bbmp_sel_ward_1, bbmp_sel_ward_2)

bbmp_wards_for_matching$does_boundary_touch_vector = unlist(map2(bbmp_sel_ward_1$geometry, bbmp_sel_ward_2$geometry, ~as.logical(st_touches(.x, .y, sparse = FALSE))))

bbmp_wards_for_matching$does_low_ride_count = unlist(map2(bbmp_sel_ward_1$ride_count, bbmp_sel_ward_2$ride_count, ~as.logical((.x < ride_count_threshold) & (.y < ride_count_threshold))))

bbmp_wards_for_matching$should_cluster = bbmp_wards_for_matching$does_boundary_touch_vector & bbmp_wards_for_matching$does_low_ride_count

edge_df = bbmp_wards_for_matching %>% 
  dplyr::filter(should_cluster) %>% 
  dplyr::select(WARD_NAME, WARD_NAME1)

network <- graph_from_data_frame(edge_df, directed = FALSE)

network_components = components(network)

ward_clusters <- data.frame(WARD_NAME = names(network_components$membership), cluster = unname(network_components$membership))

# join cluster data with region data
bbmp_muncipal_wards_sel_withClusters <- left_join(bbmp_muncipal_wards_sel, ward_clusters, by = "WARD_NAME")
bbmp_muncipal_wards_sel_withClusters$cluster = ifelse(is.na(bbmp_muncipal_wards_sel_withClusters$cluster), 0, bbmp_muncipal_wards_sel_withClusters$cluster)

bbmp_muncipal_wards_sel_withClusters <- bbmp_muncipal_wards_sel_withClusters %>% 
  group_by(cluster) %>% 
  mutate(WARD_NAME_OLD = WARD_NAME,
         WARD_NAME = ifelse(cluster == 0, WARD_NAME_OLD, paste0("cluster_", cluster))) %>% 
  ungroup()

# aggregate at clusterv level
bbmp_wards_sel_clustered <- bbmp_muncipal_wards_sel_withClusters %>% 
  group_by(WARD_NAME) %>% 
  summarise(POP_TOTAL = sum(POP_TOTAL),
            AREA_SQ_KM = sum(AREA_SQ_KM),
            ride_count = sum(ride_count),
            cluster = dplyr::first(cluster),
            LAT = median(LAT),
            LON = median(LON)) %>% 
  ungroup() %>% 
  mutate(is_clustered = as.factor(ifelse(cluster == 0, "No", "Yes")))

cluster_lon = bbmp_wards_sel_clustered$LON[bbmp_wards_sel_clustered$cluster != 0]
cluster_lat = bbmp_wards_sel_clustered$LAT[bbmp_wards_sel_clustered$cluster != 0]

rides_Bangalore_byHourRegion_new <- rides_Bangalore_byHourRegion %>% 
  dplyr::select(date, hour_of_day, WARD_NAME, ride_count) %>% 
  rename(WARD_NAME_OLD = WARD_NAME) %>% 
  left_join(dplyr::select(bbmp_muncipal_wards_sel_withClusters, -contains("ride_")), by = "WARD_NAME_OLD") %>%
  group_by(date, hour_of_day, WARD_NAME) %>% 
  summarise(ride_count = sum(ride_count)) %>% 
  ungroup()

rides_Bangalore_byRegion_new <- rides_Bangalore_byHourRegion_new %>% 
  group_by(WARD_NAME) %>% 
  summarise(ride_count = sum(ride_count)) %>% 
  ungroup() %>% 
  mutate(ride_count_percent = round(ride_count/sum(ride_count)*100, 2)) %>% 
  arrange(desc(ride_count)) %>% 
  mutate(ride_count_cumulative_percent = cumsum(ride_count_percent),
         id = row_number())

rides_Bangalore_byDateRegion_new <- rides_Bangalore_byHourRegion_new %>% 
  group_by(date, WARD_NAME) %>% 
  summarise(ride_count = sum(ride_count)) %>% 
  ungroup()
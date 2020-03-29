# read shape file
bbmp_muncipal_wards <- st_read("data/Municipal_Spatial_Data-master/Bangalore/BBMP.GeoJSON")

# getting unique 
rides_point_latLong <- rides_roundCoord_dateHour %>% 
  distinct(pick_lat, pick_lng, .keep_all = FALSE)

rides_point_latLong$lat_lng_id = 1:nrow(rides_point_latLong)


# converting to sf object
point_geo <- st_as_sf(rides_point_latLong, 
                      coords = c(x = "pick_lng", y = "pick_lat"), 
                      crs = 4326)


# coverting to x-y coordinated, for proper withinn operation
point_geo_xy <- st_transform(point_geo, crs = 7780) %>% 
  dplyr::filter(!st_is_empty(geometry))

bbmp_muncipal_wards_xy <- st_transform(bbmp_muncipal_wards, crs = 7780) %>% 
  dplyr::filter(!st_is_empty(geometry))


# joining
point_geo_within_xy <- st_join(point_geo_xy, bbmp_muncipal_wards_xy, join = st_is_within_distance, dist = 1000, left = FALSE)



# coverting back to lat-longs
point_geo_within <- st_transform(point_geo_within_xy, crs = 4326) %>% 
  dplyr::filter(!st_is_empty(geometry))

nrow(point_geo_within) == n_distinct(point_geo_within$geometry)

# joing to main data
sfc_as_cols <- function(x, names = c("x","y")) {
  stopifnot(inherits(x,"sf") && inherits(sf::st_geometry(x),"sfc_POINT"))
  ret <- do.call(rbind,sf::st_geometry(x))
  ret <- tibble::as_tibble(ret)
  stopifnot(length(names) == ncol(ret))
  ret <- setNames(ret,names)
  dplyr::bind_cols(x,ret)
}

point_geo_within_coord <- sfc_as_cols(point_geo_within, c("pick_lng", "pick_lat"))

nrow_before = nrow(rides_roundCoord_dateHour)
rides_roundCoord_dateHour <- left_join(rides_roundCoord_dateHour, rides_point_latLong, by=c("pick_lng", "pick_lat"))
nrow_after = nrow(rides_roundCoord_dateHour)
nrow_before == nrow_after

rides_outside <- anti_join(rides_roundCoord_dateHour, point_geo_within_coord, by="lat_lng_id")

rides_Bangalore <- rides_roundCoord_dateHour %>% 
  inner_join(dplyr::select(point_geo_within_coord, lat_lng_id, WARD_NAME), by="lat_lng_id")

rides_Bangalore_byHourRegion <- rides_Bangalore %>%
  group_by(date, hour_of_day, WARD_NAME) %>% 
  summarise(ride_count = sum(ride_count),
            day_of_week = dplyr::first(day_of_week),
            day_of_week_bucket = dplyr::first(day_of_week_bucket)) %>% 
  ungroup() %>% 
  left_join(dplyr::select(bbmp_muncipal_wards, WARD_NAME, POP_TOTAL, AREA_SQ_KM, pick_region_center_lat=LAT, pick_region_center_lng=LON), by="WARD_NAME")

rides_Bangalore_byRegion <- rides_Bangalore_byHourRegion %>% 
  group_by(WARD_NAME) %>% 
  summarise(ride_count = sum(ride_count)) %>% 
  ungroup() %>% 
  mutate(ride_count_percent = round(ride_count/sum(ride_count)*100, 2)) %>% 
  arrange(desc(ride_count)) %>% 
  mutate(ride_count_cumulative_percent = cumsum(ride_count_percent),
         id = row_number())

bbmp_muncipal_wards_sel <- right_join(bbmp_muncipal_wards, rides_Bangalore_byRegion, by = "WARD_NAME")


save(bbmp_muncipal_wards, rides_point_latLong, point_geo_within_coord, rides_outside, rides_Bangalore, rides_Bangalore_byHourRegion, rides_Bangalore_byRegion, bbmp_muncipal_wards_sel, file="data/get_municipal_region.RData")

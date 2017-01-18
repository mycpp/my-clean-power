install.packages("geojsonio")
library(geojsonio)

dir <- tempdir()
unzip("data/us-data/cb_2015_us_county_500k.zip", exdir = dir)
shpfile <- list.files(dir, pattern = ".shp$", full.names = TRUE)
sp_list <- geojson_read(shpfile[2], what = "sp")
json_list <- geojson_list(input = as(sp_list, "SpatialPolygonsDataFrame"))
geojson_write(json_list, file="us.geojson")

plot(sp_list)
head(json_list)

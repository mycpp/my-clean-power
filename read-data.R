library(checkpoint)
checkpoint::checkpoint("2016-11-15")
install.packages("tibble")
install.packages("readr")
library(tibble)
library(readr)
raw_plant_data <- read.csv("data/raw-2015-plant-data.csv", stringsAsFactors = FALSE, skip = 5) #strings are collection of chrs, we don't want them read as levels, but rather just as chr values. 

plant_data_cleaned <- data_frame( #renamed variable =  #named variable from spreadsheet
                          Plant.Id = raw_plant_data$Plant.Id, 
                          Plant.Name = raw_plant_data$Plant.Name,
                          State = raw_plant_data$Plant.State,
                          Net.Gen = as.numeric(gsub(",", "", raw_plant_data$Net.Generation..Megawatthours.)), #fix commas in numerical data issue http://stackoverflow.com/a/1523177
                          Physical_Unit = raw_plant_data$Physical.Unit.Label,
                          Total_Fuel_Consumption = raw_plant_data$Total.Fuel.Consumption.Quantity)
## Examples:
sum(plant_data_cleaned$Net.Gen[which(plant_data_cleaned$State=="TN")]) #sum of net gen from all plants in TN

raw_plant_geo_data <- read.csv("data/plantgeodata.csv", stringsAsFactors = FALSE)

plant_geo_data_cleaned <- data_frame(
                            Plant.Id = raw_plant_geo_data$ORIS.Code,
                            Plant.Name = raw_plant_geo_data$Name,
                            FuelType = raw_plant_geo_data$Fuel,
                            FuelType.Simplified = raw_plant_geo_data$FuelSimplified,
                            State = raw_plant_geo_data$State,
                            Lat = raw_plant_geo_data$Lat,
                            Lon = raw_plant_geo_data$Lon
)

combined_plant_geo_data <- data_frame(
                            Plant.Id = plant_data_cleaned$Plant.Id, 
                            Plant.Name = plant_data_cleaned$Plant.Name,
                            State = plant_data_cleaned$State,
                            Net.Gen = plant_data_cleaned$Net.Gen, #fix commas in numerical data issue http://stackoverflow.com/a/1523177
                            Physical_Unit = plant_data_cleaned$Physical_Unit,
                            Total_Fuel_Consumption = plant_data_cleaned$Total_Fuel_Consumption,
                            FuelType = NA,
                            Lat = NA,
                            Lon = NA
)
write.csv(combined_plant_geo_data, file = "data/combined-plant-geo-data.csv")

# combined_plant_geo_data$Lat <- plant_geo_data_cleaned$Lat[which(plant_geo_data_cleaned$Plant.Id == combined_plant_geo_data$Plant.Id)]

for (i in 1:length(combined_plant_geo_data$Plant.Id)) # we can't do this in one line with the above method because we need to do replacements for each unique plant ID. for loop from 1 to the number of plants listed (note that in plant_data_cleaned some plants are listed more than 1 because of different generator sources.)
{
  if (length(which(plant_geo_data_cleaned$Plant.Id == combined_plant_geo_data$Plant.Id[i])) < 1) # account for new plants since the geo data was collected (in this case 2012)
  {
    combined_plant_geo_data$Lat[i] = NA # we don't have the lat lon, so just keep it NA
    combined_plant_geo_data$Lon[i] = NA #in if statements, you don't include comma separation...
    combined_plant_geo_data$FuelType[i] = NA
  }
  else{
  combined_plant_geo_data$Lat[i] = plant_geo_data_cleaned$Lat[which(plant_geo_data_cleaned$Plant.Id == combined_plant_geo_data$Plant.Id[i])][1]
  combined_plant_geo_data$Lon[i] = as.numeric(plant_geo_data_cleaned$Lon[which(plant_geo_data_cleaned$Plant.Id == combined_plant_geo_data$Plant.Id[i])][1])
  combined_plant_geo_data$FuelType[i] = plant_geo_data_cleaned$FuelType[which(plant_geo_data_cleaned$Plant.Id == combined_plant_geo_data$Plant.Id[i])][1]
  } # assign the lat value to the combined table based on the lat info from the geo data where the plant id matches. it seems that there are a few plants in geo data with multiple lat/lon per plant ID, so let's just return the 1st one for now... [need to fix that issue]
}

which(1:4 > 2)
factor(plant_geo_data_cleaned$Plant.Id)
which(plant_geo_data_cleaned$Plant.Id == 2727)
combined_plant_geo_data$Lon <- as.numeric(combined_plant_geo_data$Lon)

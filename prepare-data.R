geodata <- read_csv("data/combined-plant-geo-data.csv") #variable associated with spreadsheet

geodata_ <- geodata %>%
  filter(Net.Gen > 100)
name_list <- unique(geodata_$FuelType)
write_csv(data_frame(Fuel.Type=name_list), path = 'data/fueltypes.csv')

fueltypes <- read_csv('data/fueltypes.csv')
geodata <- geodata %>%
  left_join(fueltypes, by = c('FuelType' = 'Fuel.Type')) %>%
  select(-X1)

geodata2 <- geodata %>%
  filter(Net.Gen > 100) %>%
  group_by(Plant.Id, State, Fuel.Simplified) %>%
  summarise(Net.Gen = sum(Net.Gen), Lat = mean(Lat), Lon = mean(Lon), FuelType = FuelType[1], Plant.Name = Plant.Name[1]) %>%
  filter(Fuel.Simplified != 'N/A')

write_csv(geodata2, path='data/plant-geo-data-filtered.csv')

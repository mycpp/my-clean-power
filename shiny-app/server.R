#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#
# checkpoint::checkpoint("2016-11-15") setwd("~/GitHub/my-clean-power/shiny/my-clean-power-app")
library(shiny)
library(leaflet)
library(maps)
library(dplyr)

## Generation Data ----
### denotes functions used to call data from csv files
generationData = read.csv("data/statedata.csv", #"https://docs.google.com/spreadsheets/d/1ZbDI31sSKatBoEVKo70TV_A4VwCBHK4pIoCWXB7yfx0/pub?gid=192701245&single=true&output=csv", 
                          header = TRUE, stringsAsFactors = FALSE)  #variable associated with spreadsheet

statenames = read.csv("data/StateNames.csv",
                        header = TRUE, stringsAsFactors = FALSE)  #variable associated with spreadsheet

### Plant Location Data
geodata <- read.csv("data/combined-plant-geo-data.csv", stringsAsFactors = FALSE) #variable associated with spreadsheet


shinyServer(function(input, output, session) {
  updateSelectizeInput(session,
                       'fuelTypeInput',
                       choices = filter(geodata, Net.Gen > 100)$FuelType, #must be a character vector!!! http://shiny.rstudio.com/articles/selectize.html
                       selected = "BIT",
                       server = TRUE)

  # Leaflet Map -----------------------------------------------------------------------------------------------------------

  ## set the color palette which is by Fuel Type https://rstudio.github.io/leaflet/colors.html
   pal <- colorFactor( # palette = color of fuel type.
     palette(),  #default range of color palette (continuous)
     domain = filter(geodata, Net.Gen > 100)$FuelType #
   ) #limits num of colors in palette to num of variables in Fuel Type  (discrete)
  output$map <- renderLeaflet({
    leaflet() %>% #blank leaflet container, but I want to add stuff with '%>%'
      addTiles( urlTemplate = "https://stamen-tiles.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.png") %>%
      #addProviderTiles("Stamen.TonerLite") %>% #calling upon underlying map tiles with name Stamen.TonerLite
      setView(-93.65, 42.0285, zoom = 4) %>% #default map view (zoom of 4 gives decent view of lower 48 states)
      addLayersControl( #layers "IN" our map
        baseGroups = c("Generation", "CO2"), #baseGroup
        options = layersControlOptions(collapsed = FALSE)
      )
      })

  observe({
    fuel.Type <- input$fuelTypeInput
    print(fuel.Type) #for troubleshooting
    geodata.fuelType = filter(geodata, Net.Gen > 100, FuelType %in% fuel.Type) #%in% looking for matches between the column in geodata with what the user selects
    leafletProxy("map", data = geodata.fuelType) %>% #map is calling upon output$map because the leaflet object has already been defined.
      clearShapes() %>% #no crap left over from the previous inputs user put in. could be performance constraint if there's a lot of data needed.
      addCircles(lng= ~Lon, lat = ~Lat, color=~pal(FuelType), stroke=FALSE, # this is where the magic happens.
                 group = "Generation",                                      # "~" = geodata.fuelType$, which means the character seq. following is a column name of the data set I defined as "data"
                 popup=~paste(sep = "<br/>",  #br is line break             # second magic happens.
                             paste0("<i>",Plant.Name,"</i>"), #paste0 = no separator. 
                             paste0("<b>",FuelType,"</b>")),  # i = italic, b = bold in display
                             #paste0(format(Net.Gen/1e6, scientific = FALSE, digits = 2, nsmall = 2)," MW")), #geodata.fuelType$
                 fillOpacity=0.8, #make slightly (20%) transparent circle
                 radius=~sqrt(abs((Net.Gen*500)/3.14159))) #circle size, multiply/divide arbitrary atm. abs() to control for negatives that shouldn't be there anyway
  })
  
  observe({
    proxy <- leafletProxy("map", data = filter(geodata, Net.Gen > 100))
    proxy %>% clearControls() %>%    
      addLegend("bottomleft",       # add Legend
                pal = pal,
                values = ~FuelType,
                title = "Plant Type",
                opacity = 0.90)
  })
})
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
library(plotly)
library(leaflet)
library(maps)
library(dplyr)

## Generation Data ----
### denotes functions used to call data from csv files
generationData = read.csv("data/statedata.csv", #"https://docs.google.com/spreadsheets/d/1ZbDI31sSKatBoEVKo70TV_A4VwCBHK4pIoCWXB7yfx0/pub?gid=192701245&single=true&output=csv", 
                          header = TRUE, stringsAsFactors = FALSE) #read csv file

statenames = read.csv("data/StateNames.csv",
                        header = TRUE, stringsAsFactors = FALSE)

### Plant Location Data
geodata <- read.csv("data/combined-plant-geo-data.csv", stringsAsFactors = FALSE)


shinyServer(function(input, output, session) {
  updateSelectizeInput(session,
                       'fuelTypeInput',
                       choices = filter(geodata, Net.Gen > 100)$FuelType, #must be a character vector!!! http://shiny.rstudio.com/articles/selectize.html
                       selected = "BIT",
                       server = TRUE)

  # Leaflet Map -----------------------------------------------------------------------------------------------------------

  ## set the color palette which is by Fuel Type https://rstudio.github.io/leaflet/colors.html
   pal <- colorFactor(
     palette(), 
     domain = filter(geodata, Net.Gen > 100)$FuelType
   )
  output$map <- renderLeaflet({
    leaflet(data = filter(geodata, Net.Gen > 100)) %>%
      addProviderTiles("Stamen.TonerLite") %>%
      setView(-93.65, 42.0285, zoom = 4)
  })

  observe({
    fuel.Type <- input$fuelTypeInput
    print(fuel.Type)
    geodata.fuelType = filter(geodata, Net.Gen > 100, FuelType %in% fuel.Type)
    leafletProxy("map", data = geodata.fuelType) %>%
      clearShapes() %>%
      addCircles(lng= ~Lon, lat = ~Lat, color=~pal(FuelType), stroke=FALSE, 
                 group = "Generation",
                 popup=~paste(sep = "<br/>",
                             paste0("<i>",Plant.Name,"</i>"),
                             paste0("<b>",FuelType,"</b>")),
                             #paste0(format(Net.Gen/1e6, scientific = FALSE, digits = 2, nsmall = 2)," MW")), #geodata.fuelType$
                 fillOpacity=0.8, 
                 radius=~sqrt(abs((Net.Gen*500)/3.14159)))%>%
      addLayersControl(
        baseGroups = c("Generation", "CO2"),
        options = layersControlOptions(collapsed = FALSE)
      )
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
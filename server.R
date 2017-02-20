#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#
# checkpoint::checkpoint("2016-11-15") setwd("~/GitHub/my-clean-power/shiny/my-clean-power-app")
library(packrat)
library(shiny)
library(tidyverse)
library(leaflet)
library(maps)
library(dplyr)

## Generation Data ----
### denotes functions used to call data from csv files
generationData = read_csv("data/statedata.csv") #"https://docs.google.com/spreadsheets/d/1ZbDI31sSKatBoEVKo70TV_A4VwCBHK4pIoCWXB7yfx0/pub?gid=192701245&single=true&output=csv", 
                            #variable associated with spreadsheet

statenames = read_csv("data/StateNames.csv")
                        #variable associated with spreadsheet

### Plant Location Data
geodata = read_csv('data/plant-geo-data-filtered.csv')

shinyServer(function(input, output, session) {
  updateSelectizeInput(session,
                       'fuelTypeInput',
                       choices = geodata$Fuel.Simplified, #must be a character vector!!! http://shiny.rstudio.com/articles/selectize.html
                       selected = "Coal",
                       server = TRUE)

  # Leaflet Map -----------------------------------------------------------------------------------------------------------

  ## set the color palette which is by Fuel Type https://rstudio.github.io/leaflet/colors.html
   pal <- colorFactor( # palette = color of fuel type.
     palette(),  #default range of color palette (continuous)
     domain = geodata$Fuel.Simplified #
   ) #limits num of colors in palette to num of variables in Fuel Type  (discrete)
  output$map <- renderLeaflet({
    leaflet() %>% #blank leaflet container, but I want to add stuff with '%>%'
      addTiles( urlTemplate = "https://stamen-tiles.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.png") %>%
      #addProviderTiles("Stamen.TonerLite") %>% #calling upon underlying map tiles with name Stamen.TonerLite
      setView(-93.65, 42.0285, zoom = 4) %>% #default map view (zoom of 4 gives decent view of lower 48 states)
      addLayersControl( #layers "IN" our map
        baseGroups = c("Generation", "CO2"), #baseGroup
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      addLegend("bottomleft",       # add Legend
                pal = pal,
                values = geodata$Fuel.Simplified,
                title = "Plant Type",
                opacity = 0.90)
      })

  observe({
    fuel.Type <- input$fuelTypeInput
    print(fuel.Type) #for troubleshooting
    geodata.fuelType = filter(geodata, Fuel.Simplified %in% fuel.Type) #%in% looking for matches between the column in geodata with what the user selects
    leafletProxy("map", data = geodata.fuelType) %>% #map is calling upon output$map because the leaflet object has already been defined.
      clearShapes() %>% #no crap left over from the previous inputs user put in. could be performance constraint if there's a lot of data needed.
      addCircles(lng= ~Lon, lat = ~Lat, color=~pal(Fuel.Simplified), stroke=FALSE, # this is where the magic happens.
                 group = "Generation",                                      # "~" = geodata.fuelType$, which means the character seq. following is a column name of the data set I defined as "data"
                 label = ~stringr::str_c(
                   Plant.Name, ': ',
                   formatC(Net.Gen/1e6, big.mark = ',', format='fg', digits = 2), ' MW'),
                 labelOptions=~labelOptions(direction = 'auto', textOnly = FALSE,
                                            style = list(
                                              'color' = pal(Fuel.Simplified),
                                              'font-size' = '12px',
                                              'font-family' = 'sans-serif',
                                              'border-color' = pal(Fuel.Simplified),
                                              'opacity' = 0.9
                                            )),
                                            #weight=1,color=pal(FuelType), opacity=1),
                 # popup=~paste(sep = "<br/>",  #br is line break             # second magic happens.
                 #             paste0("<i>",Plant.Name,"</i>"), #paste0 = no separator. 
                 #             paste0("<b>",FuelType,"</b>")),  # i = italic, b = bold in display
                             #paste0(format(Net.Gen/1e6, scientific = FALSE, digits = 2, nsmall = 2)," MW")), #geodata.fuelType$
                 fillOpacity=0.9, #make slightly (10%) transparent circle
                 radius=~sqrt(abs((Net.Gen*500)/pi))) #circle size, multiply/divide arbitrary atm. abs() to control for negatives that shouldn't be there anyway
  })
  # can set up if statements for a custom layer for each group https://github.com/rstudio/leaflet/issues/215
  addLegendCustom <- function(map, lat, zoom, colors, labels, sizes, opacity = 0.5){
    m_per_pix <- 40075016.686 * abs(cos(lat / 180 * pi)) / #http://stackoverflow.com/questions/22443350/leaflet-pixel-size-depending-on-zoom-level, http://wiki.openstreetmap.org/wiki/Zoom_levels
      2^(zoom+8) #https://rstudio.github.io/leaflet/shiny.html
    sizes <- 2*sqrt(abs((sizes*500)/pi))/m_per_pix
    colorAdditions <- paste0(colors, "; width:", sizes, "px; height:", sizes, "px")
    labelAdditions <- paste0("<div style='display: inline-block;height: ", sizes, "px;margin-top: 4px;line-height: ", sizes, "px;'>", labels, "</div>")
    
    return(addLegend(map, colors = colorAdditions, labels = labelAdditions, opacity = opacity, title = 'Energy Generation'))
  }
  
  observeEvent(input$map_bounds, {
    bounds <- as_data_frame(input$map_bounds)
    bounds.lat <- mean(c(bounds$north, bounds$south))
    leafletProxy("map") %>% 
      clearControls() %>%   
      addLegend("bottomleft",       # add Legend
                pal = pal,
                values = geodata$Fuel.Simplified,
                title = "Plant Type",
                opacity = 0.90) %>%
      addLegendCustom(lat = bounds.lat, zoom = input$map_zoom, colors = c("blue", "blue", "blue"), labels = c("0.1 MW", "1 MW", "10 MW"), sizes = c(0.1e6, 1e6, 10e6))
  })

})
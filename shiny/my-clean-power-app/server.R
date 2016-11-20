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
                       'stateInput',
                       choices = statenames$State, #must be a character vector!!! http://shiny.rstudio.com/articles/selectize.html
                       selected = "Alabama",
                       server = TRUE)
   state <- reactive({
     state.inp = input$stateInput
     if(state.inp=="") {
       state.inp <- "Alabama"
     }
     state.inp
   })

  # Leaflet Maps -----------------------------------------------------------------------------------------------------------
  ## read https://rstudio.github.io/leaflet/ for syntax details
  ## Handle Hawaii and Alaska abstraction ----
  ### probably not really important, http://www.r-bloggers.com/mapping-capabilities-in-r/
  ### in Maps these states were named differently, added code to handle correctly with our designations
  ## 48 States and DC for a list: map('state', names = TRUE, plot = FALSE)

  ## set the color palette which is by Fuel Type https://rstudio.github.io/leaflet/colors.html
   pal <- colorFactor(
     palette(), 
     domain = geodata$FuelType
   )
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles("Stamen.TonerLite") %>%
      setView(-93.65, 42.0285, zoom = 4)
  })


  observe({
    print(state())
    state.Code = statenames$State.Postal_Code[which(statenames$State == state())]
    geodata.state = geodata[which(geodata$State==state.Code),][which(geodata$Net.Gen > 100),]

        if (state() == "Hawaii") {
          mapStates <- map('world', region = c("USA:Hawaii"))
        } else if(state() == "Alaska") {
          mapStates <- map('world', region = c("USA:Alaska"))
        } else                      {
          mapStates <- map('state', region = c(state()))		#see above comment for translation
                                  }
    leafletProxy("map", data = geodata.state) %>%
      # clearShapes() %>%
      addPolylines(data=mapStates, fill=FALSE, smoothFactor=FALSE, color="#000", weight = 3, opacity = 0.9, group = "Generation") %>%
      addCircles(data = geodata.state,lng= ~Lon, lat = ~Lat, color=~pal(FuelType), stroke=FALSE, 
                 group = "Generation",
                 popup=paste(sep = "<br/>",
                             paste0("<i>",geodata.state$Plant.Name,"</i>"),
                             paste0("<b>",geodata.state$FuelType,"</b>")),
                 fillOpacity=0.8, 
                 radius=~sqrt(abs((Net.Gen*500)/3.14159)))%>%
      addLayersControl(
        baseGroups = c("Generation", "CO2"),
        options = layersControlOptions(collapsed = FALSE)
      )
  })
  
  observe({
    proxy <- leafletProxy("map", data = geodata)
    proxy %>% clearControls() %>%    
      addLegend("bottomleft",       # add Legend
                            pal = pal,
                            values = ~FuelType,
                            title = "Plant Type",
                            opacity = 0.90)
  })
})
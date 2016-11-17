#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)
library(maps)

## Generation Data ----
### denotes functions used to call data from csv files
generationData = read.csv("data/statedata.csv", #"https://docs.google.com/spreadsheets/d/1ZbDI31sSKatBoEVKo70TV_A4VwCBHK4pIoCWXB7yfx0/pub?gid=192701245&single=true&output=csv", 
                          header = TRUE, stringsAsFactors = FALSE) #read csv file
generationDataCleaned = generationData[!(is.null(generationData$Name) | generationData$Name==""), ]

statenames = read.csv("data/StateNames.csv",
                        header = TRUE, stringsAsFactors = FALSE)

### convert generation data to vectors with charcters for manipulation
row.names(generationDataCleaned) = as.character(generationDataCleaned$Name)

### Plant Location Data
geodata <- read.csv("data/combined-plant-geo-data.csv", stringsAsFactors = FALSE)


# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
  updateSelectizeInput(session,
                       'stateInput',
                       choices = statenames$State, #must be a character vector!!! http://shiny.rstudio.com/articles/selectize.html
                       selected = "Alabama",
                       server = TRUE)
  result <- reactive({
    state = input$stateInput
    if(state == "") {
      state = "Alabama"
    } 
  # Leaflet Maps -----------------------------------------------------------------------------------------------------------
  ## read https://rstudio.github.io/leaflet/ for syntax details
  ## Handle Hawaii and Alaska abstraction ----
  ### probably not really important, http://www.r-bloggers.com/mapping-capabilities-in-r/
  ### in Maps these states were named differently, added code to handle correctly with our designations
  ## 48 States and DC for a list: map('state', names = TRUE, plot = FALSE)
  if (state == "Hawaii") {
    mapStates <- map('world', region = c("USA:Hawaii"))
  } else if(state == "Alaska") {
    mapStates <- map('world', region = c("USA:Alaska"))
  } else                      {
    mapStates <- map('state', region = c(state))		#see above comment for translation
  }
  stateCode <- statenames$State.Postal_Code[which(statenames$State == state)]		# using this to point to the state code
  
  
  ## set the color palette which is by Fuel Type https://rstudio.github.io/leaflet/colors.html
  pal <- colorFactor(
    palette(), 
    domain = geodata$FuelType
  )
  
  print(mapStates)
  your.map1 <- leaflet(data = mapStates) %>%  #Generation Data Map
    addProviderTiles("Stamen.TonerLite") %>% #map tile that we have chosen to use. this tile deemphasizes clutter in the background and is mostly light gray, good contrast for variety of colors of energy types
    addPolylines(data=mapStates, fill=FALSE, smoothFactor=FALSE, color="#000", weight = 3, opacity = 0.9) %>% #state boundary
    
    addCircles(data=geodata[which(geodata$State==stateCode),], lng= ~Lon, lat = ~Lat, color=~pal(FuelType), stroke=FALSE, 
               popup=paste(sep = "<br/>",
                           paste0("<i>",geodata[which(geodata$State==stateCode),]$Plant.Name,"</i>"),
                           paste0("<b>",geodata[which(geodata$State==stateCode),]$FuelType,"</b>")), 
               fillOpacity=0.8, radius=~sqrt((Generation*500)/3.14159)) %>% #place circles with a radius based on the generation data (sized so that area is the unit, not radius. radius can be misleading with circle graphs)
    addLegend("bottomright",       # add Legend
              pal = pal,
              values = geodata$FuelType,
              title = "Plant Type",
              opacity = 0.90) #%>%
  #clearBounds()
  #setView(mean(mapStates$range[1:2]), mean(mapStates$range[3:4]), zoom = 6)
  
  output$Genmap <- renderLeaflet(your.map1) #this actually sends the Generation map to the UI
  
  
  # CO2 map --------------------------------------------------------------------------------------------------------------------------
  
  your.map2 <- leaflet(data = mapStates) %>% # CO2 map
    addProviderTiles("Stamen.TonerLite") %>%
    addPolylines(data=mapStates, fill=FALSE, smoothFactor=FALSE, color="#000", weight = 3, opacity = 0.9) %>%
    
    addCircles(data=geodata[which(geodata$State==stateCode),], lng= ~Lon, lat = ~Lat, color=~pal(FuelType), stroke=FALSE, 
               popup=paste(sep = "<br/>",
                           paste0("<i>",geodata[which(geodata$State==stateCode),]$Plant.Name,"</i>"),
                           paste0("<b>",geodata[which(geodata$State==stateCode),]$FuelType,"</b>")), 
               fillOpacity=0.8, radius=~sqrt((CarbonDioxide*500)/3.14159)) %>% #same sizing as was done for generation. 
    addLegend("bottomright",             # add Legend
              pal = pal,
              values = geodata$FuelType,
              title = "Plant Type",
              opacity = 0.90)
  output$Carbonmap <- renderLeaflet(your.map2)
  
  
})
})

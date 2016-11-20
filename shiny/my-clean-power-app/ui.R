#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(plotly)
library(leaflet)
library(maps)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("My Clean Power"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
        selectizeInput("stateInput", #inputID
                       label = "State", #label
                       choices = NULL,
                       selected = "Alabama",
                       multiple = FALSE,
                       options = list(placeholder = 'select a state name'))
      ),
    
    # Show a plot of the generated distribution
    mainPanel(
      leafletOutput("map")
      )
    )
))

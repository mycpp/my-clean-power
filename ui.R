#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#
library(packrat)
library(shiny)
library(leaflet)
library(maps)
library(dplyr)


#checkpoint::checkpoint("2016-12-10")
# Define UI for application that draws a histogram
shinyUI(bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}",
             ".leaflet .legend i{
             border-radius: 50%;
             width: 10px;
             height: 10px;
             margin-top: 4px;
             }
             "),

  # Application title
  titlePanel("My Clean Power"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
              selectizeInput("fuelTypeInput", #inputID
                             label = "Power Type", #label
                             choices = c("Coal"), #weird issue with jquery with shiny where it seems like this can't be null.
                             selected = "Coal", #this is also weirdly needed.
                             multiple = TRUE,
                             options = list(placeholder = 'select a power type'))
    ),
    # Show a plot of the generated distribution
    mainPanel(
      leafletOutput("map")
    )
  )
))
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
library(dplyr)

checkpoint::checkpoint("2016-12-01")
# Define UI for application that draws a histogram
shinyUI(fluidPage(

  # Application title
  titlePanel("My Clean Power"),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
              selectizeInput("fuelTypeInput", #inputID
                             label = "Power Type", #label
                             choices = c("BIT"), #weird issue with jquery with shiny where it seems like this can't be null.
                             selected = "BIT", #this is also weirdly needed.
                             multiple = TRUE,
                             options = list(placeholder = 'select a power type'))
    ),
    # Show a plot of the generated distribution
    mainPanel(
      leafletOutput("map")
    )
  )
))
# # Define UI for application that draws a histogram
# shinyUI(navbarPage("My Clean Power", id="nav",
# 
#   # Application title
#   tabPanel("My Clean Power Map",
#    div(class="outer",
#        tags$head(
#          includeCSS("styles.css")
#        ),
#     # Show a plot of the generated distribution
#     leafletOutput("map", width = "100%", height = "100%"),
# 
#     absolutePanel(id="controls", fixed = TRUE, draggable = TRUE, top = 60, left="auto", right = 20,
#                   bottom = "auto", width = 330, height = "auto",
#         selectizeInput("fuelTypeInput", #inputID
#                        label = "Power Type", #label
#                        choices = NULL,
#                        selected = "BIT",
#                        multiple = TRUE,
#                        options = list(placeholder = 'select a power type')
#                        )
#                   )
#       )
#     )
# ))
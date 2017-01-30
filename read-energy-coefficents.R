library(tidyjson)
library(tidyverse)
library(stringr)
source('apikeys.R')

state.emissions.list <- read_json(paste0('http://api.eia.gov/category/?api_key=',
                                  eiakey,'&category_id=',
                                  '2251670'), 
                                  format = 'jsonl'
                          ) %>%
                            enter_object("category") %>% #gather_keys() %>%
                            enter_object("childcategories") %>% gather_array() %>%
                            spread_values(
                              Category.id = jnumber("category_id"),
                              State = jstring("name")
                            ) %>%
                            select(Category.id, State) %>%
                            arrange(State)

get_emissions_coeff <- function(state.name){
  state.id <- state.emissions.list$Category.id[match(state.name, state.emissions.list$State)]
  emission.coeff.df <- read_json(paste0('http://api.eia.gov/category/?api_key=',
                   eiakey,'&category_id=',
                   state.id), 
            format = 'jsonl' # read special url (for json file) we are looking fo'.
  ) %>%
    enter_object("category") %>% #getting inside the trees! aka Keebler elves. (aka getting inside the data storage that is JSON)
    enter_object("childseries") %>% gather_array() %>% #entering the arrayyy!
    spread_values( #Gather values we care about. in this case series_id and what that means (name)
      Series.id = jstring("series_id"), 
      Name = jstring("name")
    ) %>%
    
    # filtering to set up the forthcoming data based on series that matter to us.
    filter(str_detect(Name, 'electric power')) %>%
    select(Series.id, Name) %>% # normally, read_json() gives us two columns that we don't care about.
    arrange(Name) %>% #probably not needed, but just because.
    
    # ----- set of extractions to get the fuel type out of the name
    extract(Name,'fuelType','\\Qemissions,\\E\\s([^\\,]*)\\,',
            remove = TRUE) 
  
  emission.coeff.df <- emission.coeff.df %>%
    extract(fuelType, 'fuelType.short', '(.+)\\s\\(',
            remove = FALSE)
  emission.coeff.df$Fuel.Type[!is.na(emission.coeff.df$fuelType.short)] <- emission.coeff.df$fuelType.short[!is.na(emission.coeff.df$fuelType.short)]
  emission.coeff.df$Fuel.Type[is.na(emission.coeff.df$fuelType.short)] <- emission.coeff.df$fuelType[is.na(emission.coeff.df$fuelType.short)]
   # ----- end extractions
  
  
  emission.coeff.df <- emission.coeff.df %>%
    add_column(State = rep(state.name, length(emission.coeff.df$Fuel.Type))) %>% # later on we are going to stack all of these to ensure that each state has the same coeffcients
    select(Series.id, Fuel.Type, State) #make sure I just have these 3 columns and nothing else extraneous when I was filtering.
  
  get_coeff <- function(Series.id){ # get the coefficient values for each fuel type
    emission.fuelType <- emission.coeff.df$Fuel.Type[match(Series.id,emission.coeff.df$Series.id)]
    emission.state <- emission.coeff.df$State[match(Series.id,emission.coeff.df$Series.id)]
    emission.coeff <- read_json(paste0('http://api.eia.gov/series/?api_key=',
                                          eiakey,'&series_id=',
                                          Series.id
                                       ), 
                                   format = 'jsonl'
    ) %>%
      enter_object("series") %>% gather_array() %>%
      enter_object("data") %>% gather_array()
    # because data elements are unnamed in this json array >:( we have to unlist and then force into a matrix. it's ugly, but works.
    emission.coeff <- as_tibble(matrix(unlist(attr(emission.coeff, "JSON")), ncol = 2, byrow = TRUE))
    # tibble -- pretty data frame
    # matrix -- force structure into a data frame, this allows us to force columns on the unlisted data
    # unlist -- attributes (attr) are acquired when read_json reads in the data file and assembled into a nested list. we need to unnest it to get the data we are looking for.
    colnames(emission.coeff) <- c("Date", "Coefficient") # naming columns
    
    emission.coeff <- emission.coeff[which(emission.coeff$Date == '2012'),] #coefficients shouldn't change (they haven't since time of interest), we arbitrarily chose 2012.
     
     # so far when we unlisted, every variable is assumed as the type: character. We need to change types: Date + Numeric for Date and Coefficient, respectively.
     emission.coeff$Date <- as.Date(paste(emission.coeff$Date,1,1), format = "%Y %m %d") #Just forcing this Date of just "Year" to first day of that year for consistency
     emission.coeff$Coefficient <- as.numeric( emission.coeff$Coefficient) # make numeric
     emission.coeff$Type <- emission.fuelType #pass along the fuelType
     emission.coeff$State <- emission.state #pass along the State

  emission.coeff #return the coefficients.
  }
  
  # now, let's make the table of coefficients for this state.
  emission.coeff.table <- bind_rows(map(emission.coeff.df$Series.id, get_coeff)) #stack for each type. a faster way over a standard for-loop in R.
  emission.coeff.table #return the table. we're done!
}

states.list <- bind_rows(map(state.emissions.list$State[c(-9,-45)], get_emissions_coeff)) #dropping D.C. and U.S. which for some reason aren't included.

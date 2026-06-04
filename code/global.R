# global.R


# ============================================================================
# LIBRARY LOADING
# ============================================================================

# Core Shiny and UI
library(shiny)           
library(shinyWidgets)    
library(shinythemes)
library(shinycssloaders)
library(shinyjs)         
library(bslib)           
library(DT)              
library(fontawesome)     

# Data manipulation
library(dplyr)           
library(tidyr)           

# Plotting and visualisation
library(ggplot2)        
library(plotly)          
library(GGally)          
library(corrplot)        
library(corrgram)        

# Specialised statistical graphics
library(vcd)
library(summarytools)

# Note: Tabplot package requires installation from GitHub
# Uncomment and run once to install:
library(devtools)
install_github("edwindj/ffbase", subdir = "pkg")
install_github("mtennekes/tabplot")
install.packages("rsconnect")
install.packages("promises")
library(promises)

library(ffbase)
library(tabplot)         


# ============================================================================
# DATASET LOADING AND PREPROCESSING
# ============================================================================


# Load the dataframe (stringsAsFactors = TRUE)
df <- read.csv("Ass1Data.csv", header = TRUE, stringsAsFactors = TRUE)

# Convert Date column into date type
df$Date <- as.Date(as.character(df$Date))

# Set ordered factors
df$Priority <- factor(df$Priority, levels = c("Low", "Medium", "High"), ordered = TRUE)
df$Duration <- factor(df$Duration, levels = c("Short", "Long", "Very Long"), ordered = TRUE)
df$Temp <- factor(df$Temp, levels = c("Cold", "Warm", "Hot"), ordered = TRUE)
df$Price <- factor(df$Price, levels = c("Cheap", "Fair", "Expensive"), ordered = TRUE)
df$Speed <- factor(df$Speed, levels = c("Slow", "Medium", "Fast"), ordered = TRUE)

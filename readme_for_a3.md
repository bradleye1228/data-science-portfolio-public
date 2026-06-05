===========================================================================================================================================
README FILE | Semester 1, 2025, COSC480 A3 Project | Intereactive Crash Data Dashboard (NZ) 
===========================================================================================================================================

Author: Eduard Bradley, 13241805
Date: 01/06/2025

# Project Overview: 

The aim of this project for A3 was to develop an interactive dashboard that analysing of road crash data in New Zealand. The dataset that was sourced from Waka Kotahi (NZ Transport Agency) and contains reported crashes from 2000 to 2024 in its current form.  

The dashboard was created using Streamlit as the primary framework due to its flexibility in developing web-based data applications and supporting interactive user input. Users can filter the dataset using sliders, sliders, dropdown menus, and checkboxes to explore trends and patterns. One of Streamlit’s key benefits is the ability to export filtered data directly as a downloadable CSV file alongside the visualisations that are generated. 

The application supports several visualisations to enhance understanding:

•	A regional heatmap (choropleth map) showing crash density by area.
•	A bar chart comparing total crashes per region.
•	A time-series line graph showing yearly trends.

The dashboard dynamically reads the CSV crash dataset and supports future updates (provided the column structure remains the same). Filtering options include crash year, severity, speed limits, and region. All of these aspects help users to carry out meaningful and insightful analysis of road safety. 



# Initial vs Current Programme Behaviour: 

The original version of the programme (from A1 and A2) provided basic static reports of crash data. Users could select a specific year and speed limit to generate a summary crash severity table. A time-series graph allowed to select a year range and severity type as well. However, both these features required restarting the script to change filters each time. There was no geographic filtering or real-time interactivity. 

The current web-based dashboard has significantly improved on its functionality. Users can now:
•	Filter crashes by year range, road speed limit, and severity type. 
•	Visualise crash distributions through a labelled choropleth map with each region. 
•	Compare regional crash totals using bar charts and sortable table.
•	Analyse trends over time using a dynamic line graph. 
•   Ability to download all visualisations as PNGs with filtered criteria. 
•	Export filtered datasets as a CSV file. 

Example: A user may filter for “Fatal Crashes between 2015 and 2020 on roads with 50-90 km/h speed limits” and immediately see a heat map of high-risk regions. The bar chart and line graph can then be used to focus on those specific regions and observe total and trends over time. That user can make a report from this analysis with exported PNG's of the visualisation and a exported CSV of the filtered dataset as needed. 



# Dependencies and Data Sources:

Python Libraries:

•	Streamlit (v1.32+) – used for creating the web application interface.
•	Pandas (v2.0+) – for structured data manipulation.
•	Geopandas (v0.14+) – for reading and working with shapefiles.
•	Matplotlib (v3.8+) – for generating graphs and plots.


Data sources:
•	Crash data: Waka Kotahi Open Data Portal – Crash Analysis System (CAS) 
•	Regional boundaries: Stats NZ – Regional Council 2025 Shapefile



# How to Use:

This application is designed to run through the terminal in Visual Studio Code (VS Code). Please follow these steps to launch the interactive dashboard:

1. Open the project folder in VS Code.

2. Install the following dependencies by opening the terminal and entering:

pip install streamlit pandas geopandas matplotlib  

 3. Press Run Python File on “streamlit_crash_data_map.py” to initialise any setup or review output messages. At this stage, there will be warning messages appearing in the terminal (as they are not being directly run on Streamlit’s application). These are expected and can be ignored unless they indicate missing packages or critical errors. 

4. Wait for the terminal to come with the working directory path. From there, please enter the following into the terminal:

streamlit run a3_project_streamlit.py

The above text that needs to be entered can also be found at the bottom of the application with a hashtag that has to be removed before entering. 

5. A new browser tab will open automatically showing the dashboard. If it doesn’t open, copy the local URL printed in the terminal and paste it into your browser. If all else fails, can use the following link:

http://localhost:8501/



# Key Achievements:

1.	Interactive Mapping:
Created a choropleth map by merging crash data with regional shapefiles. This visualisation uses colour gradients (from pale yellow to deep red) to represent crash density. Regions like Auckland, Waikato, and Canterbury often show higher crash counts under various filters.

2.	User-Driven Filtering:
Enabled filtering by crash year, speed range, and severity type. Users can tailor their analysis to specific scenarios in real time. 

3.	Performance Optimisation:
Used Streamlit’s caching decorators (@st.cache_data and @st.cache_resource) to optimise data loading and responsiveness. Pandas was also used extensively for efficient filtering and sorting. 

4.	Accessible Visuals:
Designed clear, uncluttered charts. Region labels on maps are well positioned and tables are formatted for readability. 



# Student-Led Innovations:

•	Geospatial Integration:
Merged CSV crash data with regional shapefiles using GeoPandas and resoved discrepancies in region names (e.g., mapping “Auckland Region” to “Auckland”) and excluded “Other Region Areas” from the visualisation. 

•	Custom Visual Design (Choropleth Maps):
Developed a consistent and informative visual theme using Matplotlib and GeoPandas. The use of the choropleth maps was inspired by examples from Towards Data Science and Analytics Vidhya, which demonstrated techniques for colouring geographical areas based on real data. This approach was adapted for this project to show crash densities across New Zealand regions using the “YlOrRd” colour palette and labelled region annotations for clarity.

•	Dynamic User Interface:
Employed Streamlit’s expanders to simplify the layout and reduce visual clutter (e.g., collapsible time-series graph) for better user-friendliness.



# Citations:
__________

•  Waka Kotahi. (2024). Crash Analysis System (CAS) data. Licensed under CC BY 4.0. https://opendata-nzta.opendata.arcgis.com/datasets/8d684f1841fa4dbea6afaefc8a1ba0fc_0/explore

•  Streamlit Community. (2024). Streamlit Documentation. https://docs.streamlit.io

•  Geopandas Development Team. (2023). Geospatial Data in Python Made Easy. https://geopandas.org

•  Misra, S. (2020, April 2). Making colored country maps with real data using matplotlib and geopandas. Medium – Analytics Vidhya. https://medium.com/analytics-vidhya/making-colored-country-maps-with-real-data-using-matplotlib-and-geopandas-2d10687ca7ac

•  Yang, W. (2021, May 10). Plot choropleth maps with shapefiles using GeoPandas. Towards Data Science. https://towardsdatascience.com/plot-choropleth-maps-with-shapefiles-using-geopandas-a6bf6ade0a49
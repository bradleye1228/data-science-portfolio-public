# NZ Crash Data Dashboard — Application Walkthrough

**Author:** Eduard Bradley, 13241805

This document provides a visual walkthrough of the **NZ Crash Data Dashboard**, an interactive web application developed for **COSC 480: Introduction to Python, Assignment 3** at the **University of Canterbury**.

The application uses crash data sourced from the New Zealand Transport Agency (Waka Kotahi) Crash Analysis System (CAS), allowing users to explore road safety trends across New Zealand through interactive filtering, mapping, and visualisation tools.

**Live App:** [NZ Crash Data Dashboard](https://nz-crash-clean-bradley.streamlit.app/)

---

# Main Dashboard Interface

The default dashboard view displays the complete crash dataset with no filters applied. All visualisations update automatically in response to user selections, allowing rapid exploration of crash patterns and trends.

![Main Dashboard](images/main_dashboard.png)

*Visualisation 01: Default dashboard view showing the full crash dataset with interactive filter controls, crash summary statistics, regional crash totals, and time-series visualisations. No filters are applied.*

Users can filter crash records by year range, crash severity, road speed limits, and region. Filtered datasets and generated charts can be exported as CSV and PNG files respectively.

---

# Expanded Visualisation View

The dashboard includes expandable analysis sections to reduce clutter while retaining full analytical capability.

![Expanded Visualisations](images/expanded_visualisations.png)

*Visualisation 02: Expanded panel view showing the regional crash comparison bar chart, interactive time-series line graph, and data exploration table. Visualisations reflect the currently applied filter selections.*

### Regional Crash Comparison

The regional bar chart compares total crash counts between regions, helping identify areas with consistently higher crash frequencies across different filtering scenarios.

### Time-Series Analysis

The interactive line graph displays crash trends over time, supporting comparison of multiple regions simultaneously and investigation of long-term road safety patterns.

### Data Exploration Table

The interactive data table provides direct access to the filtered crash records with sorting, searching, filtering, and export functionality, allowing users to inspect the observations underlying each visualisation.

---

# Example Analysis Using Filters

The example below demonstrates scenario-based filtering using the following criteria:

- **Years:** 2020–2024
- **Speed limits:** 100–110 km/h
- **Crash severity:** Fatal
- **Regions:** Northland, Waikato, Manawatū-Whanganui

![Filtered Analysis Example](images/filtered_analysis.png)

*Visualisation 03: Filtered dashboard view showing fatal crash records on high-speed roads between 2020 and 2024 for three selected regions. The regional comparison and time-series panels update automatically to reflect the applied filters.*

This targeted view allows users to compare fatal crash frequencies between regions, examine year-on-year trends under specific conditions, and export both the filtered dataset and visualisations for reporting purposes.

---

# Technologies Used

- Python
- Streamlit
- Pandas
- GeoPandas
- Matplotlib

---

## Project Context

This application was developed for **COSC 480 – Introduction to Python** at the **University of Canterbury**. The dataset is sourced from the New Zealand Transport Agency (Waka Kotahi) Crash Analysis System (CAS) and covers road crash records from across New Zealand.

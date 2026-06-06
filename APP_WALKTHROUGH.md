# Manufacturing Dashboard — Application Walkthrough

**Author:** Eduard Bradley, 13241805

This document provides a visual walkthrough of the **Manufacturing Dashboard**, an interactive R Shiny application developed for **DATA 423: Data Science in Industry** at the **University of Canterbury**.

The dashboard was built to support exploratory data analysis (EDA) of a manufacturing monitoring dataset containing sensor measurements, operational variables, and categorical descriptors collected between January 2018 and November 2024.

**Live App:** [Manufacturing Dashboard](https://bradley1228.shinyapps.io/assignment_01_v3/)

---

## Table of Contents

- [Welcome Page](#welcome-page)
- [Main Dashboard](#main-dashboard)
- [Dataset Overview](#dataset-overview)
- [Numeric Variable Summary Table](#numeric-variable-summary-table)
- [Boxplot Analysis](#boxplot-analysis)
- [Correlation Matrix](#correlation-matrix)
- [Missing Values Analysis](#missing-values-analysis)
- [Rising-Order Charts](#rising-order-charts)
- [Time Series Analysis](#time-series-analysis)
- [Tabplot](#tabplot)
- [Mosaic Plot](#mosaic-plot)
- [GGally Pairwise Analysis](#ggally-pairwise-analysis)
- [Interactive Data Table](#interactive-data-table)
- [Summary](#summary)

---

# Welcome Page

The welcome page introduces the project, explains the purpose of the dashboard, and provides guidance for navigating the available analyses.

![Welcome Page](screenshots/welcome_page.png)

*Visualisation 01: Welcome page providing an overview of the dashboard objectives, dataset context, and navigation instructions for users.*

### Purpose

- Introduce the manufacturing dataset
- Explain dashboard objectives
- Provide user instructions
- Outline available visualisations

---

# Main Dashboard

The main dashboard serves as the central navigation point for all analysis modules.

![Main Dashboard](screenshots/main_dashboard.png)

*Visualisation 02: Main dashboard interface showing the central navigation panel and layout for accessing all analytical components.*

### Features

- Dashboard navigation controls
- Interactive visualisation selection
- Access to all analytical components
- User-friendly layout for exploratory analysis

---

# Dataset Overview

This section provides a summary of the dataset structure and data quality.

![Dataset Overview](screenshots/dataset_overview.png)

*Visualisation 03: Dataset overview page displaying key structural characteristics including observation count, variable count, completeness percentage, and variable type breakdown.*

### Dataset Characteristics

- 360 observations
- 44 variables
- Approximately 96% complete
- Numeric and categorical variables
- Weekly observations spanning six years

### Insights

Users can quickly assess dataset size, completeness, and overall structure before conducting detailed analyses.

---

# Numeric Variable Summary Table

The numeric variable summary provides descriptive statistics for all sensor variables and the response variable.

![Numeric Variable Summary](screenshots/numeric_summary.png)

*Visualisation 04: Numeric variable summary table presenting descriptive statistics for all sensor and response variables, including mean, median, standard deviation, quartiles, and missing value counts.*

### Statistics Available

- Mean
- Median
- Standard deviation
- Minimum and maximum values
- Quartiles
- Missing value counts

### Purpose

This table enables rapid assessment of variable distributions and identification of unusual measurements across the sensor network.

---

# Boxplot Analysis

Boxplots are used to investigate distributions, variability, and outlier behaviour across sensor variables.

![Boxplot Analysis](screenshots/boxplot.png)

*Visualisation 05: Centred and scaled boxplots for all sensor variables with an adjustable IQR multiplier. Substantial outlier behaviour is visible within Group A sensors, with extreme values largely associated with the TX operator period.*

### Features

- Adjustable IQR multiplier
- Outlier identification
- Standardised and raw-scale views
- Group-specific visualisation options

### Key Findings

Analysis revealed substantial outlier behaviour within Group A sensors, with extreme values largely associated with observations recorded during the TX operator period.

---

# Correlation Matrix

Correlation matrices are used to explore linear and rank-based relationships between sensor variables.

![Correlation Matrix](screenshots/correlation_matrix.png)

*Visualisation 06: Pearson and Spearman correlation heatmap for all numeric variables, ordered by eigenvector decomposition. Four distinct sensor groups with strong within-group correlations are clearly visible.*

### Features

- Pearson correlation coefficients
- Spearman correlation coefficients
- Eigenvector variable ordering
- Interactive exploration

### Key Findings

Correlation analysis identified four distinct sensor groups that exhibited strong within-group relationships and differing behavioural patterns across the dataset.

---

# Missing Values Analysis

Missingness plots provide insight into data completeness and potential missing-data mechanisms.

![Missing Values Plot](screenshots/missing_values.png)

*Visualisation 07: Dataset-wide missingness heatmap with observations ordered chronologically. sensor6 contains substantially more missing values than any other variable, with missingness concentrated across specific time periods.*

### Features

- Dataset-wide missingness visualisation
- Individual variable inspection
- Chronological observation ordering

### Key Findings

The analysis highlighted that sensor6 contains substantially more missing values than any other variable in the dataset, suggesting a potential systematic recording issue during certain operating periods.

---

# Rising-Order Charts

Rising-order charts sort observations from smallest to largest, making distributional structures and groupings easier to identify.

![Rising Order Chart](screenshots/rising_order.png)

*Visualisation 08: Rising-order chart displaying sensor measurements sorted from smallest to largest, with optional standardisation to Z-scores. The distinct behavioural break corresponding to the TX operator period is clearly visible.*

### Features

- Raw-scale visualisation
- Standardised Z-score visualisation
- Group-specific exploration
- Comparative analysis across sensors

### Key Findings

These plots were instrumental in identifying sensor groupings and revealing the distinct behaviour associated with the TX operator period, which appears as a clear step change in the sorted distributions.

---

# Time Series Analysis

Time series plots allow users to investigate how sensor measurements change over time.

![Time Series Plot](screenshots/time_series.png)

*Visualisation 09: Time series plot showing sensor measurements over the full observation window from January 2018 to November 2024. A distinct operating regime is visible between March 2018 and June 2019, corresponding to the TX operator period.*

### Features

- Individual sensor analysis
- Sensor group visualisation
- TX operator period highlighting
- Longitudinal trend exploration

### Key Findings

Time series analysis revealed a distinct operating regime between March 2018 and June 2019 that corresponded to observations associated with the TX operator, characterised by markedly different sensor behaviour relative to the rest of the dataset.

---

# Tabplot

The tabplot combines categorical and numeric variables into a single compact visualisation ordered chronologically.

![Tabplot](screenshots/tabplot.png)

*Visualisation 10: Tabplot displaying all dataset variables simultaneously in chronological order. The TX operator period is clearly distinguishable, and the four sensor groups are visible as distinct blocks of correlated behaviour.*

### Features

- Simultaneous display of multiple variables
- Temporal ordering of observations
- Pattern recognition across variable types
- Compact dataset overview

### Purpose

The tabplot provides a high-level summary of the entire dataset and supports the discovery of relationships that may not be apparent in isolated variable-by-variable visualisations.

---

# Mosaic Plot

Mosaic plots are used to investigate associations between categorical variables.

![Mosaic Plot](screenshots/mosaic_plot.png)

*Visualisation 11: Mosaic plot showing the joint distribution of categorical variables, coloured by Pearson residuals to highlight statistically significant associations. A meaningful relationship between Location, Price, and Operator is evident.*

### Features

- Frequency visualisation
- Pearson residual colouring
- Multi-way categorical analysis
- Statistical relationship assessment

### Key Findings

The mosaic analysis identified a statistically significant relationship between Location, Price, and Operator, highlighting systematic patterns within the manufacturing operations.

---

# GGally Pairwise Analysis

Pairwise scatterplot matrices provide detailed investigation of relationships between selected variables.

![GGPairs Plot](screenshots/ggpairs.png)

*Visualisation 12: GGPairs pairwise scatterplot matrix showing bivariate relationships, correlation coefficients, and variable distributions for selected sensors, coloured by operator category. The four sensor group structures identified in the correlation matrix are confirmed here.*

### Features

- Pairwise scatterplots
- Correlation coefficients
- Variable distributions
- Colouring by operator category

### Purpose

These plots support deeper investigation of sensor relationships and provide visual confirmation of the group structures identified through correlation analysis.

---

# Interactive Data Table

The dashboard includes a fully interactive data table for detailed inspection of individual observations.

![Interactive Data Table](screenshots/data_table.png)

*Visualisation 13: Interactive data table providing full access to the raw dataset with search, sort, and filter functionality for inspection of individual observations and anomalies.*

### Features

- Search functionality
- Column sorting
- Data filtering
- Full dataset exploration

### Purpose

The table allows users to validate observations, investigate anomalies, and inspect the records underlying patterns identified in the visualisations.

---

# Summary

The Manufacturing Dashboard integrates a range of exploratory data analysis techniques into a single interactive application. Through visual and statistical analysis, the dashboard enables users to:

- Explore dataset structure and quality
- Investigate missing values and data completeness
- Examine sensor distributions and variability
- Identify outliers and unusual observations
- Discover correlation structures and sensor groupings
- Analyse temporal patterns and operating regimes
- Explore categorical relationships
- Inspect individual observations

The dashboard successfully revealed four distinct sensor groups, identified the influence of the TX operator period, characterised missing-data patterns, and highlighted key relationships within the manufacturing process.

---

## Technologies Used

- R
- Shiny
- Plotly
- GGally
- corrplot
- corrgram
- visdat
- vcd
- tabplot
- DT

---

## Project Context

This application was developed for **DATA 423 – Data Science in Industry** at the **University of Canterbury**. The dataset is an artificially generated manufacturing monitoring dataset designed to simulate real-world industrial process data and support exploratory data analysis techniques commonly used in industry.

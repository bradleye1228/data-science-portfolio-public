# Portfolio Structure Overview

This repository serves as the central hub for my data science project portfolio. Each project lives on its own branch and contains all relevant code, data, and documentation.

**Location:** `data-science-portfolio-public/`

---

## Overall Structure

```
data-science-portfolio-public/
│
├── 01-manufacturing-dashboard/
├── 02-patient-health-analytics/
├── 03-nz-road-crash-dashboard/
│
├── README.md
└── Portfolio Structure Overview.md

```

---

## Project Directories

### 01-manufacturing-dashboard
**Branch:** [`01-manufacturing-dashboard-v2`](../../tree/01-manufacturing-dashboard-v2)

- **Purpose:** Exploratory data analysis of a manufacturing sensor dataset (360 observations, 30 sensors, 6 years of weekly recordings). Identifies sensor groupings, operator-driven anomalies, missingness patterns, and categorical associations.
- **Tech:** R, Shiny
- **Live App:** [Manufacturing Dashboard](https://bradley1228.shinyapps.io/assignment_01_v3/)

```
01-manufacturing-dashboard/
├── code/
│   ├── global.R
│   ├── server.R
│   └── ui.R
├── data/
│   └── Ass1Data.csv
├── docs/
│   ├── DATA423-26S1-Assignment-1.pdf
│   └── DATA423_Assignment_01_Eduard_Bradley_13241805.pdf
├── screenshots/
│   ├── boxplot.png
│   ├── correlation_matrix.png
│   ├── data_table.png
│   ├── dataset_overview.png
│   ├── ggpairs.png
│   ├── main_dashboard.png
│   ├── missing_values.png
│   ├── mosaic_plot.png
│   ├── numeric_summary.png
│   ├── rising_order.png
│   ├── tabplot.png
│   ├── time_series.png
│   └── welcome_page.png
├── APP_WALKTHROUGH.md
└── README.md

```

---

### 02-patient-health-analytics
**Branch:** [`02-patient-health-analytics-v2`](../../tree/02-patient-health-analytics-v2)

- **Purpose:** Exploratory analysis and predictive modelling on a simulated patient health dataset. Evaluates 27 regression methods and selects a best-performing model (BRNN, test R² = 0.99) alongside a transparent alternative (glmnet with interactions, test R² = 0.98).
- **Tech:** R, Shiny, caret
- **Live App:** [Patient Health Analytics Dashboard](https://bradley1228.shinyapps.io/data423_assignment_03/)

```
02-patient-health-analytics/
├── code/
│   ├── global.R
│   ├── server.R
│   └── ui.R
├── data/
│   └── Ass3Data.csv
├── saved_models/          (directory with many model files)
├── docs/
│   ├── DATA423 Assignment 03 Submission.pdf
│   └── DATA423-26S1-Assignment-3-Specification.pdf
├── screenshots/
│   ├── best_model/        (folder containing files)
│   ├── candidate_models/  (folder containing files)
│   ├── eda/               (folder containing files)
│   ├── model_optimisation/(folder containing files)
│   ├── preprocessing/     (folder containing files)
│   └── transparent_model/ (folder containing files)
├── APP_WALKTHROUGH.md
└── README.md

```

---

### 03-nz-road-crash-dashboard
**Branch:** [`03-nz-road-crash-dashboard-clean`](../../tree/03-nz-road-crash-dashboard-clean)

- **Purpose:** Interactive analysis of New Zealand road crash data (2000–2024) sourced from Waka Kotahi. Explores crash trends over time, regional patterns, and contributing risk factors.
- **Tech:** Python, Streamlit, GeoPandas, Matplotlib
- **Live App:** [NZ Road Crash Interactive Dashboard](https://nz-crash-clean-bradley.streamlit.app/)

```
03-nz-road-crash-dashboard/
├── data/
│   ├── cas_filtered.csv.gz
│   ├── regional-council-2025.cpg
│   ├── regional-council-2025.dbf
│   ├── regional-council-2025.prj
│   ├── regional-council-2025.shp
│   ├── regional-council-2025.shx
│   └── regional-council-2025.txt
├── images/
│   ├── dashboard_overview.png
│   ├── expanded_visualisations.png
│   ├── filtered_analysis.png
│   ├── filtered_fatal_crashes.png
│   └── main_dashboard.png
├── a3_project_streamlit.py
├── requirements.txt
├── APP_WALKTHROUGH.md
└── README.md

```

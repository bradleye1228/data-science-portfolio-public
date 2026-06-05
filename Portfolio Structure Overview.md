# Portfolio Structure Overview

This repository serves as the central hub for my data science project portfolio. Each project lives on its own branch and contains all relevant code, data, and documentation.

**Location:** `data-science-portfolio-public/`

---

## Overall Structure

```
data-science-portfolio-public/
│
├── 01-manufacturing-dashboard/
│ ├── code/
│ ├── data/
│ ├── screenshots/
│ ├── docs/
│ └── README.md
│
├── 02-patient-health-analytics/
│ ├── code/
│ ├── data/
│ ├── models/
│ ├── screenshots/
│ ├── docs/
│ └── README.md
│
├── 03-nz-road-crash-dashboard/
│ ├── code/
│ ├── data/
│ ├── screenshots/
│ ├── docs/
│ └── README.md
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

```
code/
data/
screenshots/
docs/
README.md
```

---

### 02-patient-health-analytics
**Branch:** [`02-patient-health-analytics-v2`](../../tree/02-patient-health-analytics-v2)

- **Purpose:** Exploratory analysis and predictive modelling on a simulated patient health dataset. Evaluates 27 regression methods and selects a best-performing model (BRNN, test R² = 0.99) alongside a transparent alternative (glmnet with interactions, test R² = 0.98).
- **Tech:** R, Shiny, caret

```
code/
data/
models/
screenshots/
docs/
README.md
```

---

### 03-nz-road-crash-dashboard
**Branch:** [`03-nz-road-crash-dashboard-clean`](../../tree/03-nz-road-crash-dashboard-clean)

- **Purpose:** Interactive analysis of New Zealand road crash data (2000–2024) sourced from Waka Kotahi. Explores crash trends over time, regional patterns, and contributing risk factors.
- **Tech:** Python, Streamlit, GeoPandas, Matplotlib
- **Live App:** [NZ Road Crash Interactive Dashboard](https://nz-crash-clean-bradley.streamlit.app/)

```
code/
data/
screenshots/
docs/
README.md
```

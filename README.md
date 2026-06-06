# README for: 01-manufacturing-dashboard

An interactive R Shiny application developed as part of DATA 423 at the University of Canterbury. The application performs exploratory data analysis (EDA) on a structured manufacturing dataset (`Ass1Data.csv`) containing weekly sensor readings, operational conditions, and categorical descriptors recorded between January 2018 and November 2024.

**Live App:** [Manufacturing Dashboard](https://bradley1228.shinyapps.io/assignment_01_v3/)

---

## Dataset

- **360 observations × 44 variables** (15,840 total cells; ~96% complete)
- **30 numeric sensor variables** (`sensor1`–`sensor30`) plus a continuous response variable `Y`
- **12 categorical variables**, including 5 ordered factors (`Priority`, `Duration`, `Temp`, `Price`, `Speed`) and 7 unordered factors (`Operator`, `Location`, `Class`, `Surface`, `State`, `Agreed`, `ID`)
- Observations recorded weekly on Thursdays or Fridays across a 6-year period
- Notable missingness: `sensor6` contains 28.9% missing values — roughly six times higher than any other variable

---

## Key Findings Surfaced by the Dashboard

**Sensor groupings** — Four structurally distinct sensor groups were identified through rising-order charts, correlation matrices, and time series plots:

| Group | Sensors |
|-------|---------|
| A | sensor4, sensor8, sensor11, sensor16, sensor22, sensor24, sensor28 |
| B | sensor21, sensor23, sensor25, sensor26, sensor27, sensor29, sensor30 |
| C | sensor12, sensor13, sensor14, sensor15, sensor17, sensor18, sensor19, sensor20 |
| D | sensor1, sensor2, sensor3, sensor5, sensor6, sensor7, sensor9, sensor10 |

**TX Operator effect** — Group A sensors produced extreme values (300–400 units) exclusively during the period 31 March 2018 to 20 June 2019. All TX operator observations and D-prefixed IDs fall within this window. Removing TX observations eliminates these extreme values entirely, revealing three cleaner distributional groupings consistent with Spearman correlation structure.

**Missingness pattern** — `sensor6` missingness appears scattered with no clear temporal or variable-based clustering. The period 31 March 2018 to 20 June 2019 shows near-complete data across all variables except `sensor6`, which is coincident with the TX operator period.

**Outlier structure** — Using the standard 1.5×IQR rule, 440 outliers were detected across Group A sensors. These absorb progressively at IQR multipliers of ~2.8× (sensor22, 24, 28), ~5.9× (sensor11, 16), and ~12.1× (sensor4, 8), suggesting they represent a second measurement regime rather than isolated anomalies.

**Categorical association** — A statistically significant three-way relationship was identified between `Location`, `Price`, and `Operator` (χ² p = 0.037). TX is over-represented in Expensive + Control Room combinations and under-represented in Cheap + Storage Tank combinations.

**Response variable Y** — Most strongly correlated with Group D sensors (Pearson r = 0.387–0.456). Displays one outlier at –5.71 units under the standard IQR rule.

---

## Dashboard Features

- **Missingness plot** — Full dataset and per-variable views; chronologically ordered rows
- **Time series plots** — All sensors, grouped sensors, and sensor6 individually; TX-filtered view
- **Rising-order charts** — Raw and Z-score standardised; per-group breakdowns
- **Correlation matrices** — Pearson and Spearman with eigenvector-ordered variables
- **Boxplots** — Adjustable IQR multiplier; raw and centred/scaled views; TX-excluded view
- **ggPairs plots** — Pairwise scatterplots with correlation coefficients; coloured by `Operator`
- **Tabplot** — Chronological view of categorical and numeric variables simultaneously
- **Mosaic chart** — Multi-variable categorical frequency and Pearson residual visualisation
- **Interactive data table** — Full dataset inspection with filtering

---

## Tools & Technologies

- **R / Shiny** — Application framework
- **Plotly** — Interactive charting
- **GGally** — ggPairs pairwise plots
- **corrgram / corrplot** — Correlation matrices
- **visdat** — Missingness visualisation
- **vcd** — Mosaic plots
- **tabplot** — Tabplot visualisation
- **DT** — Interactive data tables

---

## Context

This project was completed as Assignment 01 for DATA 423 (Data Science in Industry) at the University of Canterbury. The dataset (`Ass1Data.csv`) is an artificially generated dataset simulating a real-world manufacturing monitoring scenario.

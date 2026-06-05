# README for: 02-patient-health-analytics

An R Shiny application developed as part of DATA 423 at the University of Canterbury. The application combines exploratory data analysis with a full predictive modelling workflow applied to a simulated patient health dataset (`Ass3Data.csv`), spanning observations recorded between September 2013 and September 2021.

**Live App:** [Patient Health Analytics Dashboard](https://bradley1228.shinyapps.io/data423_assignment_03/)

---

## Dataset

- **969 observations × 21 variables** (20,349 total cells; ~97.2% complete)
- **Response variable**: `Response` — a continuous biomarker outcome (range: −375 to 6,250; mean ≈ 3,000)
- **Lifestyle predictors**: `Alcohol`, `Coffee`, `Exercise`, `ChemoTreatments` — all complete, no missing values
- **Reagent variables**: `ReagentA`–`ReagentN` (14 variables) — missingness ranges from 3.4% (`ReagentH`) to 5.4% (`ReagentN`)
- **Categorical**: `BloodType` (A, B, AB, O — roughly equal distribution) and `ObservationDate`
- **Missingness structure**: 193 specific patients each have exactly 3 missing reagent values; the remaining 776 patients have complete data — identified as Missing Not at Random (MNAR) via decision tree analysis

---

## Key Analytical Findings

**Correlations with Response**
- `Exercise` shows the strongest linear relationship with Response (Pearson r = −0.57)
- `Alcohol` (r = 0.38) and `Coffee` (r = 0.29) show weak positive associations
- `ChemoTreatments` has virtually no linear association (r ≈ 0.00)
- Reagent variables show strong multicollinearity with each other (many pairs r ≈ 1.00) but weak individual associations with Response

**Missingness**
- A decision tree predicting missingness per observation split exclusively on `Patient` (variable importance = 1,391 vs next highest = 7.2), confirming the MNAR pattern
- Listwise deletion was rejected in favour of k-NN imputation (k = 5) to avoid bias

**Outliers**
- All outliers detected under the standard 1.5×IQR rule disappeared when the multiplier was increased to 2.3×, indicating natural distributional tails rather than true anomalies

---

## Modelling Workflow

### Preprocessing Recipe (applied consistently across all models)
1. k-NN imputation (k = 5), later upgraded to bagged imputation (25 trees) during optimisation
2. Day-of-week extraction from `ObservationDate`
3. Dummy encoding for `BloodType` and day-of-week
4. Zero-variance and near-zero-variance filter
5. Centring and scaling

### Candidate Models
27 regression methods were evaluated within a `caret` framework, covering linear, regularised, tree-based, ensemble, kernel, neural network, Bayesian, and instance-based families. Models were compared using 25 bootstrap resamples with fixed seeds for reproducibility (partition seed: 199; resample seed: 673).

| Rank | Method | RMSE | R² |
|------|--------|------|----|
| 1 | brnn (Bayesian Regularised Neural Network) | 132.9 | 0.979 |
| 2 | gaussprPoly (Gaussian Process, Polynomial) | 164.0 | 0.969 |
| 3 | svmPoly (SVM, Polynomial Kernel) | 167.6 | 0.968 |
| 4 | svmRadial (SVM, Radial Kernel) | 249.5 | 0.931 |
| — | Null baseline | 923.1 | — |

Linear methods (lm, glmnet, pls, pcr, rlm) converged at RMSE ≈ 449–457 and R² ≈ 0.76, reflecting a shared performance ceiling due to the nonlinear structure of the data.

### Optimised Models (expanded grid search + bagged imputation)

| Model | Bootstrap RMSE | Test RMSE | Test R² | RMSE Change |
|-------|---------------|-----------|---------|-------------|
| brnn_optim | 110.5 (±9.5) | 79.7 | 0.9916 | +8.0% |
| gaussprPoly_optim | 154.8 (±13.4) | 106.8 | 0.9850 | +71.1% |
| svmPoly_optim | 152.4 (±12.9) | 116.4 | 0.9822 | +57.2% |
| svmRadial_optim | 166.4 (±15.7) | 127.4 | 0.9786 | +50.6% |

**Best model: `brnn_optim`** — smallest gap between training and testing RMSE (8.0%), indicating strong generalisation with minimal overfitting.

### Transparent Model
A `glmnet` model with pairwise interaction terms (`glmnet_interact`) was developed as an interpretable alternative:

- Bootstrap RMSE: 154.2 (±9.6), R² = 0.97
- Test RMSE: 133.4, Test R² = 0.977
- 154 non-zero coefficients retained after L1 regularisation
- Largest effects: `Exercise` (−543.19), `Alcohol` (+352.24), `ReagentF × BloodType_B` (−315.73), `Coffee` (+311.53)
- Full coefficient table available in the application

---

## Dashboard Features

- **EDA panel** — Boxplots with adjustable IQR multiplier, Pearson correlation heatmap, missingness heatmap and decision tree
- **Model comparison** — Cross-validated RMSE/MAE/R² distributions across all 27 candidate models
- **Optimised model assessment** — Predicted vs actual plots, residual scatterplots and boxplots for train/test sets
- **Transparent model panel** — glmnet_interact coefficient table, performance comparison, residual analysis
- **Interactive filtering** — Patient-level inspection and subset exploration

---

## Tools & Technologies

- **R / Shiny** — Application framework
- **caret** — Unified model training, tuning, and resampling
- **glmnet** — Elastic net and interaction-expanded transparent model
- **brnn** — Bayesian regularised neural network
- **Plotly / ggplot2** — Interactive and static visualisations
- **GGally** — Correlation heatmaps
- **visdat** — Missingness visualisation
- **DT** — Interactive data tables
- **rpart** — Decision tree for missingness analysis

---

## Context

This project was completed as Assignment 03 for DATA 423 (Data Science in Industry) at the University of Canterbury. The dataset (`Ass3Data.csv`) is an artificially generated simulation of patient health records from a clinical trial context.

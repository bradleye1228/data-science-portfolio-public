# Patient Health Analytics Dashboard - Application Walkthrough

![Patient Health Analytics Dashboard](intro.png)

This document provides a visual walkthrough of the Patient Health Analytics Dashboard developed as part of **DATA 423: Data Science in Industry** at the **University of Canterbury**.

The application combines exploratory data analysis, missing data investigation, machine learning model development, model comparison, hyperparameter optimisation, and transparent predictive modelling within a single interactive R Shiny dashboard.

---

# Dashboard Overview

The Patient Health Analytics Dashboard was designed to support the complete data science workflow from raw data exploration through to predictive modelling and model interpretation.

The application allows users to:

* Explore dataset structure and quality
* Investigate missing values
* Analyse variable relationships
* Compare machine learning models
* Assess model performance
* Evaluate optimised models
* Interpret transparent predictive models

---

# Introduction Page

The dashboard opens with an introduction describing the project objectives, dataset characteristics, analytical workflow, and key findings.

![Introduction Page](intro.png)

### Purpose

* Introduce the dataset
* Explain the dashboard structure
* Summarise analytical objectives
* Provide navigation guidance

---

# Dataset Overview

The dataset overview provides a summary of variables, data types, and observation structure.

![Dataset Overview](dataset.png)

### Dataset Characteristics

* 969 patient observations
* 21 variables
* Approximately 97.2% complete
* Continuous biomarker response variable
* Lifestyle predictors
* Laboratory reagent measurements
* Blood type information
* Observation dates

This section allows users to quickly understand the structure of the data before beginning analysis.

---

# Observation Timeline

The dashboard includes a visualisation showing the distribution of observations through time.

![Observation Timespan](timespan.png)

### Purpose

* Understand temporal coverage
* Identify potential clustering of observations
* Assess data collection consistency

The dataset spans observations collected between September 2013 and September 2021.

---

# Exploratory Data Analysis

The EDA section provides several visualisations for understanding variable distributions and relationships.

## Variable Distributions

![Distribution Analysis](distribution.png)

Distribution plots allow users to assess:

* Central tendency
* Spread
* Skewness
* Potential outliers

---

## Scatterplot Analysis

![Scatterplot Analysis](scatterplot.png)

Scatterplots provide insight into relationships between predictors and the response variable.

Key observations include:

* Exercise exhibits a strong negative relationship with Response.
* Alcohol and Coffee show weaker positive associations.
* Several predictors demonstrate nonlinear behaviour.

---

## Correlation Analysis

![Correlation Matrix](correlation.png)

The correlation heatmap summarises relationships among all numeric variables.

### Key Findings

* Exercise has the strongest correlation with Response.
* Reagent variables exhibit substantial multicollinearity.
* Many reagent pairs approach perfect correlation.

---

## Pairwise Variable Exploration

![GGPairs Analysis](ggpairs.png)

The GGPairs visualisation provides:

* Pairwise scatterplots
* Correlation coefficients
* Variable distributions
* Relationship exploration

This allows detailed investigation of patterns identified in the correlation analysis.

---

## Boxplot Analysis

![Boxplot Analysis](boxplot.png)

Interactive boxplots support investigation of variable distributions and potential outliers.

### Key Finding

Outliers detected under the standard 1.5×IQR rule disappear when the multiplier is increased to approximately 2.3×, suggesting naturally occurring distribution tails rather than true anomalies.

---

# Missing Data Investigation

Understanding missing-data behaviour was a critical component of this project.

## Missingness Visualisation

![Missingness Plot](missingplot.png)

The missingness heatmap highlights patterns of incomplete observations across reagent variables.

### Key Findings

* Missing values occur exclusively within reagent variables.
* 193 patients contain missing observations.
* Remaining patients are fully complete.

This pattern suggests a structured missing-data mechanism rather than random omission.

---

# Model Development Workflow

The dashboard documents each stage of the predictive modelling process.

## Train-Test Split

![Train Test Split](train_test_split.png)

A dedicated train-test partition was used to ensure unbiased model evaluation.

### Purpose

* Prevent data leakage
* Support reproducible analysis
* Provide independent model assessment

---

## Available Regression Models

![Regression Methods](caret_regression_methods.png)

Twenty-seven regression algorithms were evaluated using the caret framework.

Model families include:

* Linear models
* Penalised regression
* Support vector machines
* Neural networks
* Bayesian methods
* Gaussian processes
* Tree-based models

---

## Model Selection Interface

![Model Selection](select_model.png)

Users can explore candidate models and compare performance across multiple evaluation metrics.

---

## Null Model Baseline

![Null Model](null_model.png)

The null model provides a benchmark against which all predictive models are compared.

This establishes the minimum level of performance expected from a useful predictive model.

---

## Candidate Model Comparison

![Model Comparison](model_compare.png)

Models are compared using:

* RMSE
* MAE
* R²

### Key Finding

Bayesian Regularised Neural Networks consistently achieved the strongest predictive performance across resamples.

---

# Resampling Assessment

Model stability and generalisation were assessed using bootstrap resampling.

## Resampling Statistics

![Resampling Statistics](resampled_stat_1.png)

![Additional Resampling Statistics](resampled_stat_2.png)

These summaries provide insight into model consistency and predictive robustness.

---

## Resampling Visualisation

![Resampling Visualisation](resampled_vis.png)

Visual comparisons allow users to evaluate:

* Model stability
* Variability between resamples
* Generalisation potential

---

## BRNN Resampling Information

![BRNN Resampling Information](brnn_resampled_info.png)

Detailed resampling diagnostics are provided for the highest-performing model.

---

# Optimised Model Performance

Following initial model comparison, the strongest models underwent additional optimisation.

## Optimised Model Summary

![Optimal Models](optimal models.png)

The optimisation process incorporated:

* Expanded tuning grids
* Enhanced preprocessing
* Bagged imputation
* Additional hyperparameter tuning

---

## Performance vs Computational Cost

![Model Runtime Comparison](optimal_model_time.png)

This visualisation demonstrates the trade-off between model performance and training time.

Users can evaluate whether performance gains justify additional computational expense.

---

# Best Model: Bayesian Regularised Neural Network

The optimised BRNN achieved the strongest overall predictive performance.

## Training Performance

![BRNN Training Results](brnn train.png)

The training results demonstrate the model's ability to capture complex nonlinear relationships within the data.

---

## Testing Performance

![BRNN Testing Results](brnn test.png)

### Performance Summary

* Test RMSE: 79.7
* Test R²: 0.9916

The small difference between training and testing performance indicates excellent generalisation and minimal overfitting.

---

# Transparent Predictive Model

While BRNN provided the strongest predictive performance, a transparent alternative was developed to improve interpretability.

## glmnet Model Overview

![glmnet Overview](glmnet_info.png)

The transparent model uses:

* L1 regularisation
* Automatic variable selection
* Pairwise interaction terms
* Coefficient shrinkage

This provides substantially greater interpretability while maintaining strong predictive performance.

---

## glmnet Training Performance

![glmnet Training Results](glment int train.png)

Training results demonstrate the effectiveness of the interaction-expanded glmnet model.

---

## glmnet Testing Performance

![glmnet Testing Results](glmnetinter test.png)

### Performance Summary

* Test RMSE: 133.4
* Test R²: 0.977

Although slightly less accurate than BRNN, the model remains highly competitive while providing full coefficient-level interpretability.

---

# Project Summary

The Patient Health Analytics Dashboard demonstrates the complete data science workflow within a single interactive application.

The project combines:

* Exploratory data analysis
* Missing-data investigation
* Feature engineering
* Machine learning model selection
* Hyperparameter optimisation
* Model evaluation
* Explainable predictive modelling

The final BRNN model achieved exceptional predictive performance while the transparent glmnet model provided a practical and interpretable alternative for clinical decision support.

---

# Technologies Used

* R
* Shiny
* caret
* brnn
* glmnet
* GGally
* ggplot2
* Plotly
* visdat
* DT
* rpart

---

# Project Context

This project was completed as Assignment 03 for DATA 423 (Data Science in Industry) at the University of Canterbury.

The dataset is a simulated patient health dataset designed to emulate a clinical trial environment and provide opportunities for advanced predictive modelling, data exploration, and machine learning evaluation.

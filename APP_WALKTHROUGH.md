# Patient Health Analytics Dashboard - Application Walkthrough

This document provides a visual walkthrough of the Patient Health Analytics Dashboard developed as part of **DATA 423: Data Science in Industry** at the **University of Canterbury**.

The application combines exploratory data analysis, missing-data investigation, machine learning model selection, model optimisation, and transparent predictive modelling within a single interactive R Shiny dashboard.

The project uses a simulated patient health dataset containing lifestyle variables, laboratory reagent measurements, blood type information, and a continuous biomarker response variable.

---

# Application Overview

The dashboard was designed to support the complete data science workflow from initial exploration through to predictive model deployment and interpretation.

Users can:

* Explore dataset structure and quality
* Investigate missing-data mechanisms
* Examine variable relationships
* Compare machine learning models
* Evaluate optimised models
* Interpret transparent predictive models
* Inspect model performance metrics

---

# Welcome Page

The dashboard opens with an introduction describing the project objectives, dataset characteristics, and analytical workflow.

![Introduction Page](images/intro.png)

### Purpose

* Introduce the dataset
* Explain dashboard functionality
* Provide project context
* Guide users through the available analyses

---

# Dataset Overview

The dataset overview provides a summary of variables, data types, and overall dataset structure.

![Dataset Overview](images/dataset.png)

### Dataset Characteristics

* 969 patient observations
* 21 variables
* Approximately 97.2% complete
* Continuous response variable
* Lifestyle predictors
* Reagent measurements
* Blood type information
* Observation dates

### Purpose

This section provides users with a foundation for understanding the data before beginning analysis.

---

# Exploratory Data Analysis

The dashboard includes multiple visualisations for understanding distributions, relationships, and variable behaviour.

## Distribution Analysis

![Distribution Analysis](images/distribution.png)

Distribution plots allow users to assess skewness, spread, and overall variable behaviour.

---

## Scatterplot Analysis

![Scatterplot Analysis](images/scatterplot.png)

Scatterplots help identify relationships between predictors and the response variable.

Key relationships include:

* Strong negative association between Exercise and Response
* Positive associations involving Alcohol and Coffee

---

## Correlation Analysis

![Correlation Heatmap](images/correlation.png)

The correlation matrix highlights relationships among predictors and reveals substantial multicollinearity among reagent variables.

Key finding:

Many reagent variables exhibit near-perfect pairwise correlations despite having relatively weak direct relationships with the response variable.

---

## Pairwise Variable Exploration

![GGPairs Analysis](images/ggpairs.png)

The GGally pairwise plots provide a detailed view of:

* Variable distributions
* Correlation coefficients
* Predictor relationships
* Potential nonlinear patterns

---

## Boxplot Analysis

![Boxplot Analysis](images/boxplot.png)

Interactive boxplots allow investigation of outliers using adjustable IQR multipliers.

Key finding:

Outliers identified under the standard 1.5×IQR rule disappear at approximately 2.3×IQR, suggesting natural distributional tails rather than true anomalies.

---

# Data Quality Assessment

Understanding missing-data behaviour was a critical component of the analysis.

## Missingness Visualisation

![Missing Data Plot](images/missingplot.png)

The missingness heatmap highlights patterns of incomplete observations across reagent variables.

Key finding:

193 patients contain missing values while the remaining 776 patients are fully complete.

---

## Missingness Decision Tree

![Missingness Decision Tree](images/brnn_resampled_info.png)

Decision tree analysis was used to investigate the missing-data mechanism.

Key finding:

Patient identity overwhelmingly predicts missingness, supporting a Missing Not at Random (MNAR) interpretation.

This finding motivated the use of imputation rather than listwise deletion.

---

# Train-Test Partitioning

The dashboard documents the modelling workflow beginning with train-test separation.

![Train Test Split](images/train_test_split.png)

### Purpose

* Prevent data leakage
* Support independent model evaluation
* Establish reproducible modelling procedures

---

# Candidate Model Selection

A large-scale model comparison framework was implemented using the caret ecosystem.

## Available Regression Models

![Candidate Models](images\caret_regression_methods.png)

Twenty-seven regression algorithms were evaluated, including:

* Linear models
* Regularised regression
* Support vector machines
* Neural networks
* Tree-based methods
* Gaussian process models
* Bayesian approaches

---

## Model Selection Interface

![Model Selection](images/select_model.png)

Users can inspect individual model performance and compare results across candidate algorithms.

---

## Null Model Benchmark

![Null Model](images/null_model.png)

The null model establishes a baseline against which all predictive models are compared.

---

## Model Performance Comparison

![Model Comparison](images/model_compare.png)

Performance metrics include:

* RMSE
* MAE
* R²

Key finding:

Bayesian Regularised Neural Networks (BRNN) consistently achieved the strongest predictive performance.

---

# Resampling Performance Assessment

The dashboard provides detailed evaluation of cross-validation and bootstrap performance.

## Resampling Statistics

![Resampling Statistics 1](images/resampled_stat_1.png)

![Resampling Statistics 2](images/resampled_stat_2.png)

---

## Resampling Visualisation

![Resampling Visualisation](images/resampled_vis.png)

These views allow users to assess:

* Stability
* Variability
* Model robustness
* Generalisation potential

---

# Optimised Model Evaluation

The top-performing models underwent expanded hyperparameter tuning and enhanced preprocessing.

## Optimised Model Summary

![Optimal Models](images/optimal models.png)

The optimisation process included:

* Bagged imputation
* Expanded tuning grids
* Bootstrap resampling
* Hyperparameter optimisation

---

## Performance versus Training Time

![Model Runtime Comparison](images/optimal_model_time.png)

This visualisation demonstrates the trade-off between predictive performance and computational cost.

---

# Best Model: Bayesian Regularised Neural Network

The optimised BRNN achieved the strongest overall performance.

## Training Predictions

![BRNN Training Results](images/brnn train.png)

---

## Test Predictions

![BRNN Test Results](images/brnn test.png)

### Performance

* Test RMSE: 79.7
* Test R²: 0.9916

The small difference between training and testing performance indicates strong generalisation and minimal overfitting.

---

# Transparent Predictive Model

To complement the black-box neural network, an interpretable glmnet model with interaction terms was developed.

## glmnet Model Overview

![glmnet Information](images/glmnet_info.png)

The model incorporates:

* L1 regularisation
* Interaction terms
* Feature selection
* Coefficient shrinkage

---

## Training Performance

![glmnet Training Performance](images/glment int train.png)

---

## Test Performance

![glmnet Test Performance](images/glmnetinter test.png)

### Key Findings

The transparent model achieved:

* Test RMSE: 133.4
* Test R²: 0.977

While slightly less accurate than BRNN, it provides substantially greater interpretability.

---

# Dashboard Summary

The Patient Health Analytics Dashboard integrates the complete data science workflow into a single interactive application.

The dashboard enables users to:

* Explore patient health data
* Investigate missing-data mechanisms
* Assess variable relationships
* Compare machine learning models
* Optimise predictive performance
* Evaluate model robustness
* Interpret transparent predictive models

The project demonstrates advanced skills in exploratory data analysis, machine learning, model tuning, predictive modelling, explainable AI, and interactive dashboard development.

---

# Technologies Used

* R
* Shiny
* caret
* glmnet
* brnn
* ggplot2
* Plotly
* GGally
* visdat
* DT
* rpart

---

# Project Context

This project was completed as Assignment 03 for DATA 423 (Data Science in Industry) at the University of Canterbury.

The dataset is a simulated patient health dataset designed to emulate clinical trial data and provide opportunities for advanced predictive modelling and analytical workflows.

# DATA 423 Assignment 03: Patient Health Analytics Dashboard

**Author:** Eduard Bradley, 13241805

![Introduction](screenshots/intro.png)

This document provides a visual walkthrough of the **Patient Health Analytics Dashboard**, an interactive R Shiny application developed for **DATA 423: Data Science in Industry** at the **University of Canterbury**.

The dashboard combines exploratory data analysis, missing data investigation, machine learning model comparison, model optimisation, and interpretable predictive modelling within a single application.

---

## Table of Contents

- [Part A: Data Description and EDA](#part-a-data-description-and-eda)
- [Part B: Strategies](#part-b-strategies)
- [Part C: Methods](#part-c-methods)
- [Part D: Best Model](#part-d-best-model)
- [Part E: Transparent Model](#part-e-transparent-model)
- [Part F: Conclusion](#part-f-conclusion)
- [Part G: References](#part-g-references)
- [Part H: AI Declaration](#part-h-ai-declaration)

---

# Part A: Data Description and EDA

## 1). Introduce Data

The dataset used in this data analysis is named `Ass3Data.csv`, which is an artificially generated dataset designed to simulate recorded health data of a particular response variable named **Response**. The dataset has a file size of approximately 323 KB and contains **969 rows** of observations and **21 columns** of variables, giving a total of 20,349 cells.

- **Overall data completeness:** Approximately 97.2%
- **Fully complete observations:** 776 (80.1%)
- **Observations with missing values:** 193 (19.9%)

The **Patient** column acts as a unique identifier for each individual in the study. The other categorical variable is **BloodType**, which has a cardinality of four representing the ABO blood groups: A, B, AB and O. The blood groups are relatively equally distributed.

The **ObservationDate** specifies when the results were collected, spanning from **13th September 2013 to 21st September 2021** (8.0 years total).

![Observation Timeline](screenshots/timespan.png)

*Visualisation 01: Bar graph showing the monthly distribution of recorded observations between 13th September 2013 and 21st September 2021. The distribution of entries is relatively consistent across the 8-year period, with an average of approximately 10 observations recorded per month.*

### Dataset Overview

![Dataset Overview](screenshots/dataset.png)

**Key Information:**
- 969 observations, 21 variables
- Approximately 97.2% complete
- Continuous response variable
- Lifestyle predictors (Alcohol, Coffee, Exercise, ChemoTreatments)
- Reagent measurements (ReagentA through ReagentN)
- Blood type categories

### Numeric Variable Distribution Summary

| Variable | Min | Q1 | Median | Mean | Q3 | Max | SD | Missing % |
|----------|-----|----|--------|------|----|-----|----|-----------|
| Alcohol | 0 | 1.01 | 1.97 | 2.01 | 3.06 | 4 | 1.16 | 0% |
| Coffee | 0 | 1.8 | 3.55 | 3.52 | 5.26 | 7 | 2 | 0% |
| Exercise | 0 | 2.9 | 6.17 | 6.06 | 9.15 | 11.99 | 3.52 | 0% |
| ChemoTreatments | 0 | 1.31 | 2.44 | 2.48 | 3.69 | 4.99 | 1.41 | 0% |
| Response | -375.28 | 2,366.64 | 2,948.10 | 2,999.96 | 3,565.00 | 6,250.15 | 916.58 | 0% |

*Table 01: Summary statistics for all numeric variables. Missing values are present only within the reagent variables.*

## 2). Boxplot Analysis

Boxplots were constructed for all numeric variables using the standard 1.5 IQR rule to identify potential outliers. No outliers were detected for the lifestyle variables. When the IQR multiplier was increased from 1.5 to **2.3**, all detected outliers disappeared across every variable.

![Boxplot Analysis](screenshots/boxplot.png)

*Visualisation 02: Centred and scaled boxplots of all numeric variables using an IQR multiplier of 2.3. The lifestyle variables display comparatively low variability, while the reagent variables and Response exhibit greater spread.*

## 3). Correlation Analysis

The Pearson correlation heatmap shows the linear relationships between all numeric variables. **Exercise** shows the strongest relationship with Response, with a moderate negative correlation of **r = −0.57**. Alcohol and Coffee both show weak positive correlations with Response (r = 0.38 and r = 0.29, respectively).

The reagent variables display several very strong positive correlations with one another, with many pairs approaching **r = 1.00**, indicating substantial multicollinearity.

![Correlation Matrix](screenshots/correlation.png)

*Visualisation 03: Pearson correlation heatmap for all numeric variables. Several reagent variables exhibit extremely strong positive correlations, suggesting that some reagents may represent closely related biological measurements.*

## 4). Pairwise Variable Relationships

![GGPairs Analysis](screenshots/ggpairs.png)

*The GGPairs visualisation provides pairwise scatterplots, correlation coefficients, and variable distributions for detailed relationship exploration.*

## 5). Missingness Heatmap and Tree

Missing values are limited to the reagent measurements only, ranging from 3.4% (ReagentH) to 5.3% (ReagentN) of observations. However, further investigation reveals that missingness is **not random** but systematically concentrated within a specific subset of 193 patients, each having exactly three missing reagent values.

![Missingness Plot](screenshots/missingplot.png)

*Visualisation 04: Missingness heatmap showing the distribution of NULL values across the reagent variables.*

A decision tree analysis predicting the number of missing values per observation shows that missingness is almost entirely explained by the Patient variable, providing strong evidence that the missing data mechanism is **Missing Not at Random (MNAR)**.

---

# Part B: Strategies

## 1). Missing Data

Given the structured missingness pattern, deletion-based approaches were considered inappropriate. **k-Nearest Neighbours (k-NN) imputation with k=5** was selected as the most appropriate preprocessing strategy.

## 2). Outliers

When the IQR multiplier was increased to 2.3, all detected outliers disappeared. No observations were removed from the dataset, and no specialised robust outlier treatment methods were considered necessary.

## 3). Feature Engineering

Several preprocessing and feature engineering steps were incorporated into a common modelling recipe:

- k-NN imputation (k=5)
- Date decomposition into day-of-week
- Dummy encoding for categorical variables (BloodType, day-of-week)
- Zero variance (ZV) and near-zero-variance (NZV) removal
- Centring and scaling

## 4). Recipe

The chosen recipe applied to all candidate methods followed:
1. `impute_knn (k = 5)`
2. `step_date (dow)`
3. `step_dummy`
4. `step_zv`
5. `step_nzv`
6. `step_center`
7. `step_scale`

## 5). Tuning and Assessing

A static test set consisting of **20% of observations** was reserved for final model assessment. Hyperparameter optimisation was conducted using **25 bootstrap resamples** of the training data. Fixed random seeds were applied throughout (seed 199 for partition, seed 673 for resampling).

![Train Test Split](screenshots/train_test_split.png)

---

# Part C: Methods

## 1). Candidate Methods

Candidate methods were selected to ensure broad coverage across distinct regression modelling families, including linear, nonlinear, parametric, nonparametric, Bayesian, kernel-based, ensemble, and instance-based methods.

![Regression Methods](screenshots/caret_regression_methods.png)

*Visualisation 06: Two-dimensional MDS plot of regression method similarity. Working models retained for analysis are highlighted in blue, while models that failed are highlighted in red.*

## 2). Candidate Models

Twenty-seven regression algorithms were evaluated using the caret framework. The **Bayesian Regularised Neural Network (brnn)** achieved the strongest predictive performance by a considerable margin, returning an RMSE of **132.9**, MAE of **93.3**, and an **R² of 0.979**.

![Model Selection](screenshots/select_model.png)

![Null Model](screenshots/null_model.png)

![Model Comparison](screenshots/model_compare.png)

*Table 03: Cross-validated performance metrics for 27 candidate models. The best performing candidate model was brnn with RMSE 133.*

### Candidate Model Performance Summary

| Method | RMSE | R² | Train Time |
|--------|------|-----|-------------|
| **brnn** | **132.88** | **0.979** | 1m 0.7s |
| gaussprPoly | 163.99 | 0.969 | 2m 16s |
| svmPoly | 167.62 | 0.968 | 2m 9s |
| svmRadial | 249.55 | 0.931 | 48.2s |
| earth | 266.57 | 0.917 | 50.3s |
| null | 923.14 | N/A | 1.1s |

![Resampling Statistics](screenshots/resampled_stat_1.png)

![Additional Resampling Statistics](screenshots/resampled_stat_2.png)

![Resampling Visualisation](screenshots/resampled_vis.png)

*Visualisation 07: Candidate model performance across resampled trials, scaled relative to the null model baseline.*

## 3). Model Optimisation

Following initial candidate evaluation, the four best performing methods (brnn, gaussprPoly, svmPoly, svmRadial) were selected for further refinement. The imputation strategy was revised to **bagging imputation (25 trees)**.

### Optimised Model Results

| Model | RMSE | R² | Train Time |
|-------|------|-----|-------------|
| **brnn_optim** | **110.50** | **0.986** | 8m 47s |
| svmPoly_optim | 152.39 | 0.973 | 81m 29s |
| gaussprPoly_optim | 154.84 | 0.973 | 14m 53s |
| svmRadial_optim | 166.43 | 0.968 | 28m 35s |

![Optimised Models](screenshots/optimal%20models.png)

![Performance versus Runtime](screenshots/optimal_model_time.png)

*Visualisation 10: Bar chart of training time for each optimised method. brnn_optim required only 9 minutes, while svmPoly_optim required over 81 minutes.*

![BRNN Resampling Information](screenshots/brnn_resampled_info.png)

---

# Part D: Best Model

## 1). Optimised Models' Performance on Unseen Data

**brnn_optim** demonstrated the strongest and most stable generalisation performance:

| Model | Training RMSE | Testing RMSE | RMSE Change | Testing R² |
|-------|---------------|--------------|-------------|-------------|
| **brnn_optim** | **73.79** | **79.72** | **+8.03%** | **0.9916** |
| gaussprPoly_optim | 62.46 | 106.84 | +71.05% | 0.9850 |
| svmPoly_optim | 74.03 | 116.37 | +57.18% | 0.9822 |
| svmRadial_optim | 84.60 | 127.42 | +50.62% | 0.9786 |

![BRNN Training Results](screenshots/brnn%20train.png)

*Visualisation 11: Predicted-versus-actual plot for the training dataset of the final brnn_optim model.*

![BRNN Testing Results](screenshots/brnn%20test.png)

*Visualisation 12: Predicted-versus-actual plot for the testing dataset. Testing RMSE: 79.7, Testing R²: 0.9916.*

## 2). Best Model Theory Explanation

The BRNN extends the standard neural network by introducing a probabilistic regularisation approach to prevent overfitting. The model minimises a total objective function:

F = β * E_D + α * E_W


where:
- **E_D** is the sum of squares error (data fit)
- **E_W** is the sum of squared network weights (model complexity)
- **β** and **α** control the trade-off between data fit and complexity

Both parameters are estimated during training using Bayesian evidence procedures. The relatively small gap between training RMSE (73.8) and testing RMSE (79.7) suggests the regularisation was functioning as intended.

---

# Part E: Transparent Model

## 1). Transparent Model Development

Although brnn_optim achieved the strongest predictive performance, its neural network structure provides limited interpretability. A transparent modelling approach was explored by extending a **glmnet framework to include interaction terms**.

| Model | Bootstrap RMSE | R² | Train Time |
|-------|----------------|-----|-------------|
| GLMNET (no interactions) | 449.31 | 0.76 | 37.6s |
| **GLMNET (with interactions)** | **154.24** | **0.97** | **8m 47s** |
| Null model | 923.14 | N/A | 1.1s |

![glmnet Overview](screenshots/glmnet_info.png)

![glmnet Training Results](screenshots/glment%20int%20train.png)

![glmnet Testing Results](screenshots/glmnetinter%20test.png)

## 2). Transparent Model Performance

When evaluated on unseen testing data, the `glmnet_interact` model achieved:

- **Testing RMSE: 133.41**
- **Testing MAE: 89.51**
- **Testing R²: 0.977**

## 3). Transparent Model Theory Explanation

The glmnet algorithm combines both L1 (lasso) and L2 (ridge) regularisation penalties. The L1 component is particularly important for interpretability, as it shrinks some coefficients to exactly zero, allowing for the removal of irrelevant predictors.

The prediction equation remains fully interpretable:

ŷ = β₀ + Σ βⱼ xⱼ



where β₀ = 3089.82 (intercept) and each βⱼ coefficient quantifies the contribution of predictor xⱼ.

**Key coefficients from the final model:**
- **Exercise: −543.19** (highest negative influence)
- **Alcohol: +352.24** (strong positive contribution)
- **Coffee: +311.53** (strong positive contribution)
- **ReagentF × BloodType_B: −315.73** (interaction effect)

---

# Part F: Conclusion

This project demonstrated the value of systematic model comparison within a predictive modelling framework. Through this process, it became evident that no single modelling approach is universally optimal; instead, model performance depends on the balance between flexibility, generalisation, and interpretability.

- **Best predictive performance:** `brnn_optim` (RMSE = 79.7, R² = 0.9916)
- **Best transparent model:** `glmnet_interact` (RMSE = 133.4, R² = 0.977)

The analysis highlighted the importance of considering both performance and explainability when selecting models for applied problems, particularly in healthcare contexts where model transparency is critical.

---

# Part G: References

- Perez-Rodriguez, Paulino, and Daniel Gianola. *brnn: Bayesian Regularization for Feed-Forward Neural Networks*. R package version 0.9.4, CRAN, 2025.
- Foresee, F. Darrell, and Martin T. Hagan. "Gauss-Newton Approximation to Bayesian Learning." *Proceedings of the International Conference on Neural Networks*, IEEE, 1997.
- MacKay, David J. C. "A Practical Bayesian Framework for Backpropagation Networks." *Neural Computation*, vol. 4, no. 3, 1992.
- Rudin, Cynthia. "Stop Explaining Black Box Machine Learning Models for High-Stakes Decisions and Use Interpretable Models Instead." *Nature Machine Intelligence*, vol. 1, no. 5, 2019.
- Zou, Hui, and Trevor Hastie. "Regularization and Variable Selection via the Elastic Net." *Journal of the Royal Statistical Society: Series B*, vol. 67, no. 2, 2005.
- Friedman, Jerome, Trevor Hastie, and Robert Tibshirani. "Regularization Paths for Generalized Linear Models via Coordinate Descent." *Journal of Statistical Software*, vol. 33, no. 1, 2010.
- Tibshirani, Robert. "Regression Shrinkage and Selection via the Lasso." *Journal of the Royal Statistical Society: Series B*, vol. 58, no. 1, 1996.

---

# Part H: Artificial Intelligence Declaration

During the preparation of this report, DeepSeek, Claude and ChatGPT were employed to support code development, identify and resolve coding errors, and refine the written expression of the technical content. These tools were used solely for debugging assistance and stylistic improvements. The underlying data analysis, interpretation of results, and all substantive conclusions are entirely my own.

---

# Technologies Used

- R
- Shiny
- caret
- brnn
- glmnet
- GGally
- ggplot2
- Plotly
- visdat
- DT
- rpart

---

# Academic Context

This project was completed as **Assignment 03 for DATA 423 (Data Science in Industry)** at the **University of Canterbury**.

The dataset is a simulated patient health dataset designed to emulate a clinical trial environment and provide opportunities for advanced predictive modelling and machine learning evaluation.

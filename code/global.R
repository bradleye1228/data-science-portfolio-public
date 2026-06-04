# ========================================================================
# GLOBAL.R - DATA423 ASSIGNMENT 3
# ========================================================================
# Author: Eduard Bradley
# ========================================================================


# ========================================================================
# SECTIONS:
#   1.  Library Loading
#   2.  Global Options
#   3.  Default Preprocessing Vectors
#   4.  Preprocessing Choices
#   5.  Parallel Processing Utilities  (startMode / stopMode)
#   6.  Recipe Builder                 (dynamicSteps)
#   7.  Model Descriptions             (description)
#   8.  Model Persistence              (saveToRds / loadRds / deleteRds)
#   9.  Data Validation                (checkDataAvailability)
# ========================================================================


# ========================================================================
# SECTION 1: LIBRARY LOADING
# ========================================================================

required_packages <- c(
  # Core Shiny and UI
  "shiny", "shinythemes", "shinyjs", "shinycssloaders", "shinyWidgets", "shinyBS",
  
  # Data manipulation and utilities
  "plyr", "dplyr", "rlang", "rlist", "cli", "devtools", "BiocManager",
  
  # Visualization
  "DT", "plotly", "ggplot2", "corrgram", "visdat", "summarytools", "GGally",
  
  # Caret and ML framework
  "caret", "recipes", "doParallel", "butcher",
  
  # FAMILY 1: Linear and Regularized Regression
  "glmnet", "MASS",
  
  # FAMILY 2: PLS and Projection Methods
  "pls", "fastICA",
  
  # FAMILY 3: Tree and Rule-Based Models
  "rpart", "rpart.plot", "Cubist",
  
  # FAMILY 4: Random Forest
  "ranger", "quantregForest",
  
  # FAMILY 5: Gradient Boosting
  "xgboost", "gbm", "mboost", "bst",
  
  # FAMILY 6 & 8: SVM and Gaussian Processes (both use kernlab)
  "kernlab",
  
  # FAMILY 7: Neural Networks
  "nnet", "brnn", "neuralnet",
  
  # FAMILY 9: GAM and MARS
  "earth", "mgcv", "gam", "stats",
  
  # FAMILY 10: Bayesian and Sparse Models
  "spikeslab",
  
  # FAMILY 11: K-Nearest Neighbors
  "kknn"
)

# plyr must be loaded before dplyr to avoid conflicts
required_packages <- c(
  "plyr",
  required_packages[required_packages != "plyr"]
)

cat("\n", rep("=", 60), "\n", sep = "")
cat("DATA423 ASSIGNMENT 3 - LOADING PACKAGES\n")
cat(rep("=", 60), "\n", sep = "")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)) {
    cat("Installing missing package:", pkg, "\n")
    install.packages(pkg, repos = "https://cloud.r-project.org/")
    library(pkg, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
  } else {
    cat("✓", pkg, "\n")
  }
}

# Bioconductor: mixOmics (separate install pathway)
if (!require("mixOmics", character.only = TRUE, quietly = TRUE)) {
  cat("Installing missing package: mixOmics (via BiocManager)\n")
  BiocManager::install("mixOmics", update = FALSE, ask = FALSE)
  library(mixOmics, quietly = TRUE)
} else {
  cat("✓ mixOmics\n")
}

cat("\nAll packages ready! Launching app...\n")
cat(rep("=", 60), "\n\n", sep = "")


# ========================================================================
# SECTION 2: GLOBAL OPTIONS
# ========================================================================

options(digits = 3)
options(dplyr.summarise.inform = FALSE)


# ========================================================================
# SECTION 3: DEFAULT PREPROCESSING VECTORS
# ========================================================================
# These define the pre-selected steps shown in each model's preprocessing
# dropdown, grouped by model family requirements:
#
# ========================================================================

default_initial_recipe <- c("impute_knn", "dow", "dummy", "zv", "nzv", "center", "scale")

optimised_model_recipe  <- c("impute_bag", "dow", "dummy", "zv", "nzv", "center", "scale")


# ========================================================================
# SECTION 4: PREPROCESSING CHOICES
# ========================================================================
# Full list of steps available in every model's selectizeInput.
# The dynamicSteps() function (Section 6) translates these strings
# into actual recipes::step_* calls.
# ========================================================================

ppchoices <- c(
  "impute_knn", "impute_bag", "impute_median", "impute_mode", "YeoJohnson",
  "naomit", "pca", "pls", "ica", "center", "scale", "month", "dow",
  "dateDecimal", "nzv", "zv", "other", "dummy", "poly", "interact",
  "indicate_na", "corr"
)


# ========================================================================
# SECTION 5: PARALLEL PROCESSING UTILITIES
# ========================================================================

# ------------------------------------------------------------------------
# startMode()
#   Spins up a parallel cluster (up to 3 cores) and registers it with
#   doParallel so caret::train() can distribute resampling work.
#   Returns a list(cluster, outfile) that must be passed to stopMode().
#   Pass Parallel = FALSE to skip (single-threaded fallback).
# ------------------------------------------------------------------------

startMode <- function(Parallel = TRUE) {
  if (Parallel) {
    outfile <- tempfile(pattern = "output")
    unlink(outfile)
    
    clus <- makeCluster(
      min(c(3, detectCores(all.tests = FALSE, logical = TRUE))),
      outfile = outfile
    )
    
    clusterEvalQ(clus, {
      suppressPackageStartupMessages({
        library(plyr,             quietly = TRUE, warn.conflicts = FALSE)
        library(dplyr,            quietly = TRUE, warn.conflicts = FALSE)
        library(caret,            quietly = TRUE, warn.conflicts = FALSE)
        library(recipes,          quietly = TRUE, warn.conflicts = FALSE)
        library(ggplot2,          quietly = TRUE, warn.conflicts = FALSE)
        library(glmnet,           quietly = TRUE, warn.conflicts = FALSE)
        library(MASS,             quietly = TRUE, warn.conflicts = FALSE)
        library(pls,              quietly = TRUE, warn.conflicts = FALSE)
        library(rpart,            quietly = TRUE, warn.conflicts = FALSE)
        library(Cubist,           quietly = TRUE, warn.conflicts = FALSE)
        library(ranger,           quietly = TRUE, warn.conflicts = FALSE)
        library(quantregForest,   quietly = TRUE, warn.conflicts = FALSE)
        library(xgboost,          quietly = TRUE, warn.conflicts = FALSE)
        library(gbm,              quietly = TRUE, warn.conflicts = FALSE)
        library(mboost,           quietly = TRUE, warn.conflicts = FALSE)
        library(bst,              quietly = TRUE, warn.conflicts = FALSE)
        library(kernlab,          quietly = TRUE, warn.conflicts = FALSE)
        library(nnet,             quietly = TRUE, warn.conflicts = FALSE)
        library(neuralnet,        quietly = TRUE, warn.conflicts = FALSE)
        library(earth,            quietly = TRUE, warn.conflicts = FALSE)
        library(mgcv,             quietly = TRUE, warn.conflicts = FALSE)
        library(spikeslab,        quietly = TRUE, warn.conflicts = FALSE)
        library(kknn,             quietly = TRUE, warn.conflicts = FALSE)
      })
      TRUE
    })
    
    registerDoParallel(clus)
    list("cluster" = clus, "outfile" = outfile)
  } else {
    NULL
  }
}

# ------------------------------------------------------------------------
# stopMode()
#   Shuts down the parallel cluster, flushes its console output, and
#   re-registers sequential processing.  Always call in a finally{} block.
# ------------------------------------------------------------------------
stopMode <- function(obj) {
  if (!is.null(obj)) {
    stopCluster(obj$cluster)
    lines <- readLines(con = obj$outfile)
    lapply(paste0(lines, "\n"), FUN = cat)
    unlink(obj$outfile)
    registerDoSEQ()
  }
}


# ========================================================================
# SECTION 5B: TRAINING TIMER WRAPPER
# ========================================================================

# ------------------------------------------------------------------------
# trainWithTiming()
#   Wraps caret::train(), measures wall-clock elapsed time, and returns
#   a list(model, elapsed_sec).  Drop-in replacement for every
#   observeEvent(*_Go) block.
# ------------------------------------------------------------------------
trainWithTiming <- function(...) {
  t0    <- proc.time()["elapsed"]
  model <- caret::train(...)
  t1    <- proc.time()["elapsed"]
  list(model = model, elapsed_sec = as.numeric(t1 - t0))
}



# ========================================================================
# SECTION 6: RECIPE BUILDER
# ========================================================================

# ------------------------------------------------------------------------
# dynamicSteps()
#   Iterates over a character vector of preprocessing step names and
#   appends the corresponding recipes::step_*() call to the recipe.
#   The order of steps in the vector is preserved — this matters because
#   imputation must precede centering/scaling, etc.
#
#   Supported step names → recipes function mapping:
#     impute_knn   → step_impute_knn   (numeric + nominal, k = 5)
#     impute_bag   → step_impute_bag   (numeric + nominal, trees = 25)
#     impute_median→ step_impute_median (numeric only)
#     impute_mode  → step_impute_mode  (nominal only)
#     YeoJohnson   → step_YeoJohnson   (numeric predictors)
#     naomit       → step_naomit       (all predictors, skip = FALSE)
#     pca          → step_pca          (25 components)
#     pls          → step_pls          (25 components, outcome = Response)
#     ica          → step_ica          (25 components)
#     center       → step_center
#     scale        → step_scale
#     month        → step_date (feature = month)
#     dow          → step_date (feature = dow)
#     dateDecimal  → step_date (feature = decimal)
#     zv           → step_zv
#     nzv          → step_nzv          (freq_cut = 95/5, unique_cut = 10)
#     other        → step_other        (nominal predictors)
#     dummy        → step_dummy        (one_hot = FALSE)
#     poly         → step_poly         (degree = 2)
#     interact     → step_interact     (all numeric pairs)
#     corr         → step_corr         (threshold = 0.9)
#     indicate_na  → step_indicate_na
#     rm           → (no-op, reserved)
# ------------------------------------------------------------------------
dynamicSteps <- function(recipe, preprocess) {
  if (is.null(preprocess)) {
    stop("The preprocess list is NULL - check your control identifier")
  }
  
  for (s in preprocess) {
    if      (s == "impute_knn")    recipe <- step_impute_knn(recipe,    all_numeric_predictors(), all_nominal_predictors(), neighbors = 5)
    else if (s == "impute_bag")    recipe <- step_impute_bag(recipe,    all_numeric_predictors(), all_nominal_predictors(), trees = 25)
    else if (s == "impute_median") recipe <- step_impute_median(recipe, all_numeric_predictors())
    else if (s == "impute_mode")   recipe <- recipes::step_impute_mode(recipe,  all_nominal_predictors())
    else if (s == "YeoJohnson")    recipe <- recipes::step_YeoJohnson(recipe,   all_numeric_predictors())
    else if (s == "naomit")        recipe <- recipes::step_naomit(recipe,       all_predictors(), skip = FALSE)
    else if (s == "pca")           recipe <- recipes::step_pca(recipe,          all_numeric_predictors(), num_comp = 25)
    else if (s == "pls")           recipe <- recipes::step_pls(recipe,          all_numeric_predictors(), outcome = "Response", num_comp = 25)
    else if (s == "ica")           recipe <- recipes::step_ica(recipe,          all_numeric_predictors(), num_comp = 25)
    else if (s == "center")        recipe <- recipes::step_center(recipe,       all_numeric_predictors())
    else if (s == "scale")         recipe <- recipes::step_scale(recipe,        all_numeric_predictors())
    else if (s == "month")         recipe <- recipes::step_date(recipe,         has_type("date"), features = c("month"),   ordinal = FALSE)
    else if (s == "dow")           recipe <- recipes::step_date(recipe,         has_type("date"), features = c("dow"),     ordinal = FALSE)
    else if (s == "dateDecimal")   recipe <- recipes::step_date(recipe,         has_type("date"), features = c("decimal"), ordinal = FALSE)
    else if (s == "zv")            recipe <- recipes::step_zv(recipe,           all_predictors())
    else if (s == "nzv")           recipe <- recipes::step_nzv(recipe,          all_predictors(), freq_cut = 95/5, unique_cut = 10)
    else if (s == "other")         recipe <- recipes::step_other(recipe,        all_nominal_predictors())
    else if (s == "dummy")         recipe <- recipes::step_dummy(recipe,        all_nominal_predictors(), one_hot = FALSE)
    else if (s == "poly")          recipe <- recipes::step_poly(recipe,         all_numeric_predictors(), degree = 2)
    else if (s == "interact")      recipe <- recipes::step_interact(recipe,     terms = ~ all_numeric_predictors():all_numeric_predictors())
    else if (s == "corr")          recipe <- recipes::step_corr(recipe,         all_numeric_predictors(), threshold = 0.9)
    else if (s == "indicate_na")   recipe <- recipes::step_indicate_na(recipe,  all_predictors())
    else if (s == "rm")            { }   # intentionally blank
    else stop(paste("Attempting to use an unknown recipe step:", s))
  }
  recipe
}


# ========================================================================
# SECTION 7: MODEL DESCRIPTIONS
# ========================================================================

# ------------------------------------------------------------------------
# description()
#   Returns a human-readable summary string for a given caret method name.
#   Custom descriptions are defined inline for all models used in this app.
#   Falls back to caret::getModelInfo() for any unrecognised method name.
# ------------------------------------------------------------------------
description <- function(name) {
  
  custom_desc <- list(
    # ── FAMILY 0: Null Model ─────────────────────────────────────────────
    "null" = 'Method "null" is able to do Regression.\nIt uses parameters: (none).\nIts characteristics are: Interpretable, Linear Regression, Simple Model.',
    
    # ── FAMILY 1: Linear Models ──────────────────────────────────────────
    "lm"     = 'Method "lm" is able to do Regression.\nIt uses parameters: (none).\nIts characteristics are: Interpretable, Linear Regression, Ordinary Least Squares.',
    "glmnet" = 'Method "glmnet" is able to do Regression and Classification.\nIt uses parameters: alpha, lambda.\nIts characteristics are: Generalized Linear Model, Implicit Feature Selection, L1 Regularization, L2 Regularization, Linear Classifier, Linear Regression.',
    "rlm"    = 'Method "rlm" is able to do Regression.\nIt uses parameters: (none).\nIts characteristics are: Interpretable, Linear Regression, Robust Regression.',
    
    # ── FAMILY 2: PLS Models ─────────────────────────────────────────────
    "pls" = 'Method "pls" is able to do Regression and Classification.\nIt uses parameters: ncomp.\nIts characteristics are: Dimension Reduction, Linear Regression, Partial Least Squares.',
    "pcr" = 'Method "pcr" is able to do Regression.\nIt uses parameters: ncomp.\nIts characteristics are: Dimension Reduction, Linear Regression, Principal Component Analysis.',
    
    # ── FAMILY 3: Tree Models ────────────────────────────────────────────
    "rpart"  = 'Method "rpart" is able to do Regression and Classification.\nIt uses parameters: cp, maxdepth, minsplit.\nIts characteristics are: Interpretable, Recursive Partitioning, Rule-Based Model, Tree-Based Model.',
    "cubist" = 'Method "cubist" is able to do Regression.\nIt uses parameters: committees, neighbors.\nIts characteristics are: Ensemble Model, Interpretable, Rule-Based Model, Tree-Based Model.',
    
    # ── FAMILY 4: Random Forest ──────────────────────────────────────────
    "ranger" = 'Method "ranger" is able to do Regression and Classification.\nIt uses parameters: mtry, min.node.size, splitrule.\nIts characteristics are: Ensemble Model, Implicit Feature Selection, Random Forest, Robust, Tree-Based Model.',
    "qrf"    = 'Method "qrf" is able to do Regression.\nIt uses parameters: mtry, nodesize.\nIts characteristics are: Ensemble Model, Quantile Regression, Random Forest, Tree-Based Model.',
    
    # ── FAMILY 5: Gradient Boosting ──────────────────────────────────────
    "bstTree"    = 'Method "bstTree" is able to do Regression and Classification.\nIt uses parameters: mstop, maxdepth, nu.\nIts characteristics are: Boosted Tree, Ensemble Model, Gradient Boosting, Tree-Based Model.',
    "glmboost"   = 'Method "glmboost" is able to do Regression and Classification.\nIt uses parameters: mstop, prune.\nIts characteristics are: Boosted Linear Model, Ensemble Model, Gradient Boosting, Linear Regression.',
    "blackboost" = 'Method "blackboost" is able to do Regression and Classification.\nIt uses parameters: mstop, maxdepth.\nIts characteristics are: Boosted Tree, Ensemble Model, Gradient Boosting, Tree-Based Model.',
    "gamboost"   = 'Method "gamboost" is able to do Regression and Classification.\nIt uses parameters: mstop, prune.\nIts characteristics are: Additive Model, Boosted Model, Ensemble Model, Gradient Boosting, Smoothing Splines.',
    
    # ── FAMILY 6: SVM ────────────────────────────────────────────────────
    "svmRadial" = 'Method "svmRadial" is able to do Regression and Classification.\nIt uses parameters: sigma, C.\nIts characteristics are: Kernel Method, Nonlinear Regression, Quadratic Programming, Radial Basis Function, Support Vector Machine.',
    "svmPoly"   = 'Method "svmPoly" is able to do Regression and Classification.\nIt uses parameters: degree, scale, C.\nIts characteristics are: Kernel Method, Nonlinear Regression, Polynomial Kernel, Support Vector Machine.',
    "svmLinear" = 'Method "svmLinear" is able to do Regression and Classification.\nIt uses parameters: C.\nIts characteristics are: Kernel Method, Linear Kernel, Linear Regression, Support Vector Machine.',
    
    # ── FAMILY 7: Neural Networks ────────────────────────────────────────
    "avNNet"           = 'Method "avNNet" is able to do Regression and Classification.\nIt uses parameters: size, decay, bag.\nIts characteristics are: Ensemble Model, Neural Network, Nonlinear Regression.',
    "mlpWeightDecayML" = 'Method "mlpWeightDecayML" is able to do Regression and Classification.\nIt uses parameters: size, decay.\nIts characteristics are: Neural Network, Nonlinear Regression, Weight Decay Regularization.',
    "brnn"             = 'Method "brnn" is able to do Regression.\nIt uses parameters: neurons.\nIts characteristics are: Bayesian Neural Network, Neural Network, Nonlinear Regression.',
    "neuralnet"        = 'Method "neuralnet" is able to do Regression.\nIt uses parameters: layer1, layer2, layer3.\nIts characteristics are: Backpropagation, Neural Network, Nonlinear Regression.',
    
    # ── FAMILY 8: Gaussian Processes ─────────────────────────────────────
    "gaussprRadial" = 'Method "gaussprRadial" is able to do Regression and Classification.\nIt uses parameters: sigma.\nIts characteristics are: Gaussian Process, Kernel Method, Nonlinear Regression, Radial Basis Function.',
    "gaussprPoly"   = 'Method "gaussprPoly" is able to do Regression and Classification.\nIt uses parameters: degree, scale.\nIts characteristics are: Gaussian Process, Kernel Method, Nonlinear Regression, Polynomial Kernel.',
    
    # ── FAMILY 9: GAM / MARS ─────────────────────────────────────────────
    "earth" = 'Method "earth" is able to do Regression and Classification.\nIt uses parameters: degree, nprune.\nIts characteristics are: Interpretable, Multivariate Adaptive Regression Splines, Nonlinear Regression.',
    "gam"   = 'Method "gam" is able to do Regression and Classification.\nIt uses parameters: select, method.\nIts characteristics are: Additive Model, Generalized Additive Model, Nonlinear Regression, Smoothing Splines.',
    "ppr"   = 'Method "ppr" is able to do Regression.\nIt uses parameters: nterms.\nIts characteristics are: Interpretable, Nonlinear Regression, Projection Pursuit, Ridge Regression.',
    
    # ── FAMILY 10: Bayesian / Sparse ─────────────────────────────────────
    "spikeslab" = 'Method "spikeslab" is able to do Regression and Classification.\nIt uses parameters: maxit, n.iter1, n.iter2.\nIts characteristics are: Bayesian Model, Implicit Feature Selection, Linear Regression, Sparse Model, Spike and Slab Prior.',
    "rvmRadial"     = 'Method "rvmRadial" is able to do Regression and Classification.\nIt uses parameters: sigma.\nIts characteristics are: Gaussian Process, Kernel Method, Relevance Vector Machine, Sparse Model.',
    
    # ── FAMILY 11: K-Nearest Neighbors ───────────────────────────────────
    "kknn" = 'Method "kknn" is able to do Regression and Classification.\nIt uses parameters: kmax, distance, kernel.\nIts characteristics are: Distance-Based, Instance-Based Learning, K-Nearest Neighbors, Lazy Learning, Weighted Average.'
  )
  
  if (name %in% names(custom_desc)) return(custom_desc[[name]])
  
  # Fallback: query caret's model registry
  regexName <- paste0("^", name, "$")
  mlist <- caret::getModelInfo(model = regexName)[[name]]
  if (is.null(mlist)) return(paste0('Method "', name, '" description not available.'))
  
  paste(sep = "\n",
        paste0('Method "', name, '" is able to do ', paste(collapse = " and ", mlist$type), "."),
        paste0("It uses parameters: ",       paste0(collapse = ", ", mlist$parameters$parameter), "."),
        paste0("Its characteristics are: ",  paste0(collapse = ", ", mlist$tags))
  )
}


# ========================================================================
# SECTION 8: MODEL PERSISTENCE (UPDATED WITH TIMING)
# ========================================================================

saveToRds <- function(model, name, elapsed_sec = NULL) {
  try(
    if (!is.null(model$finalModel$classifier)) {
      rJava::.jcache(model$finalModel$classifier)
    }, silent = TRUE
  )
  
  if (!dir.exists(file.path(".", "SavedModels"))) {
    dir.create(file.path(".", "SavedModels"))
  }
  
  # Attach timing as attribute
  if (!is.null(elapsed_sec)) {
    attr(model, "elapsed_sec") <- as.numeric(elapsed_sec)
  }
  
  file   <- paste0(".", .Platform$file.sep, "SavedModels", .Platform$file.sep, name, ".rds")
  model2 <- butcher::axe_env(model, verbose = TRUE)
  saveRDS(model2, file)
}

# ------------------------------------------------------------------------
# loadRds() - UPDATED VERSION
# ------------------------------------------------------------------------
loadRds <- function(name, session) {
  rdsfile <- file.path(".", "SavedModels", paste0(name, ".rds"))
  if (!file.exists(rdsfile)) {
    showNotification("Model needs to be trained first", session = session, duration = 3)
    return(NULL)
  }
  
  showNotification(paste("Loading trained model", name, "from file", rdsfile),
                   session = session, duration = 3)
  model <- readRDS(file = rdsfile)
  
  # Recover timing attribute
  elapsed_sec <- attr(model, "elapsed_sec")
  
  if (!is.null(model$recipe)) {
    steps <- model$recipe$steps
    seld  <- c()
    for (step in steps) {
      s <- gsub(pattern = "step_", replacement = "", x = class(step)[1])
      if (s == "date") s <- step$features[1]
      seld <- c(seld, s)
    }
    preprocessingInputId <- paste0(name, "_Preprocess")
    updateSelectizeInput(session  = session,
                         inputId  = preprocessingInputId,
                         choices  = ppchoices,
                         selected = seld)
    if (length(seld) > 0) {
      showNotification(
        paste("Setting preprocessing for", name, "to", paste(seld, collapse = ",")),
        session = session, duration = 5
      )
    }
  }
  
  # Return a list with both model and timing
  list(model = model, elapsed_sec = elapsed_sec)
}

# ------------------------------------------------------------------------
# deleteRds() - KEEP THIS
# ------------------------------------------------------------------------
deleteRds <- function(name) {
  rdsfile <- file.path(".", "SavedModels", paste0(name, ".rds"))
  if (file.exists(rdsfile)) unlink(rdsfile, force = TRUE) else TRUE
}


# ========================================================================
# SECTION 9: DATA VALIDATION
# ========================================================================

# ------------------------------------------------------------------------
# checkDataAvailability()
#   Validates that Ass3Data.csv exists in the working directory, can be
#   read, and contains the required "Response" outcome column.
#   Called once at startup; result printed to console.
# ------------------------------------------------------------------------
checkDataAvailability <- function() {
  data_file <- "Ass3Data.csv"
  
  result <- list(
    file_exists  = file.exists(data_file),
    file_path    = normalizePath(data_file, mustWork = FALSE),
    can_read     = FALSE,
    n_rows       = NA,
    n_cols       = NA,
    has_response = FALSE,
    message      = ""
  )
  
  if (result$file_exists) {
    tryCatch({
      test_read        <- read.csv(data_file, nrows = 1)
      result$can_read  <- TRUE
      result$has_response <- "Response" %in% names(test_read)
      
      full_data      <- read.csv(data_file)
      result$n_rows  <- nrow(full_data)
      result$n_cols  <- ncol(full_data)
      result$message <- sprintf("✓ Data file found: %s (%d rows, %d columns)",
                                basename(result$file_path), result$n_rows, result$n_cols)
      
      if (!result$has_response)
        result$message <- paste(result$message, "⚠ WARNING: 'Response' column not found!")
      
    }, error = function(e) {
      result$can_read <- FALSE
      result$message  <- sprintf("✗ Cannot read data file: %s", e$message)
    })
  } else {
    result$message <- sprintf("✗ Data file NOT FOUND: '%s' in directory '%s'",
                              data_file, getwd())
  }
  result
}

# Run at startup
data_status <- checkDataAvailability()

cat("\n", rep("=", 60), "\n", sep = "")
cat("DATA423 ASSIGNMENT 3 - DATA STATUS\n")
cat(rep("=", 60), "\n", sep = "")
cat(data_status$message, "\n")
cat("Working directory:", getwd(), "\n")
cat(rep("=", 60), "\n\n", sep = "")


# ========================================================================
# END OF GLOBAL.R
# ========================================================================
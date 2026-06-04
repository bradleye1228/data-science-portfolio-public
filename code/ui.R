# ui.R

ui <- navbarPage(
  
  id = "navbar", 
  title = "        Assignment 01 Dashboard        –        Eduard Bradley (13241805)        ",
  theme = shinytheme("cerulean"),
  useShinyjs(),
  
  # ---------------- Global CSS for main panel expansion ----------------
  tags$head(
    tags$style(HTML("
      .sidebar-hidden .col-sm-4 { display: none; }
      .sidebar-hidden .col-sm-8 { width: 100% !important; transition: width 0.4s ease; }
      .col-sm-8 { transition: width 0.4s ease; }
    "))
  ),
  
  # ---------------- Navbar toggle button for all sidebars ----------------
  header = tagList(
    actionButton("toggle_sidebar_all",
                 label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                 style = "margin-left: 10px; margin-top: 8px;")
  ),
  
  
  # ============================================================================
  # WELCOME MODULE
  # ============================================================================
  
  tabPanel("Welcome",
           
           fluidPage(
             
             h2("Welcome!"),
             
             p("• Summary statistics of the dataset"),
             p("• Use the Boxplot tab to compare distributions across numerical variables"),
             p("• Use the Correlation tab to analyse relationships between numerical variables"),
             p("• Use the Missing tab to check for data completeness and NULL gaps"),
             p("• Use the Rising-Value tab to examine sequential value patterns"),
             p("• Use the Time Series tab to track numerical variables trends over time"),
             p("• Use the Tabplot tab to visualise overall data structure and missingness"),
             p("• Use the Mosaic Plot tab to analyse categorical combinations"),
             p("• Use the GGpairs Plot to investigate variable relationships"),
             p("• Use the Data Table tab to browse, search, and export raw data")
             
           )
  ),
  
  
  # ============================================================================
  # SUMMARY MODULE
  # ============================================================================
  
  tabPanel("Summary",
           fluidPage(
             
             h2("Dataset Summary Statistics"),
             hr(),
             
             # -------------------------
             # Dataset Overview Stats
             # -------------------------
             
             fluidRow(
               column(4, 
                      div(class = "well",
                          h4("Dataset Dimensions"),
                          hr(),
                          h3(textOutput("summary_row_count")),
                          p("Number of Rows"),
                          br(),
                          h3(textOutput("summary_col_count")),
                          p("Number of Variables"),
                          br(),
                          h3(textOutput("summary_total_cells")),
                          p("Total Cells (rows × columns)"),
                          br(),
                          h3(textOutput("summary_non_na_values")),
                          p("Actual Data Points (non-NA)"),
                          br(),
                          h3(textOutput("summary_missing_count")),
                          p("Missing Values (NA)")
                      )
               ),
               column(8,
                      div(class = "well",
                          h4("Data Quality & Quick Facts"),
                          hr(),
                          fluidRow(
                            column(6,
                                   uiOutput("summary_complete_cases"),
                                   br(),
                                   uiOutput("summary_incomplete_cases"),
                                   br(),
                                   uiOutput("summary_missing_cells")
                            ),
                            column(6,
                                   uiOutput("summary_data_completeness"),
                                   br(),
                                   uiOutput("summary_date_range_quick"),
                                   br(),
                                   uiOutput("summary_numeric_count"),
                                   br(),
                                   uiOutput("summary_categorical_count")
                            )
                          )
                      )
               )
             ),
             
             br(),
             
             # Custom CSS for spacing, hover, and DT tables
             # It's custom styling for the accordion-style panels (the clickable sections) 
             # and data tables in the Summary tab.
             
             tags$head(
               tags$style(HTML("
        .panel-heading {
          padding: 15px 20px;
          cursor: pointer;
          background-color: #f5f5f5;
          border-radius: 5px;
        }
        .panel-heading:hover { background-color: #e8e8e8; }
        .panel-title { margin: 0; font-size: 18px; font-weight: 500; }
        .panel-title a { display: block; text-decoration: none; color: #333; }
        .panel-title a:hover { text-decoration: none; color: #000; }
        .panel-group { margin-bottom: 25px; }
        .panel-body { padding: 25px; background-color: white; border: 1px solid #ddd; border-top: none; border-radius: 0 0 5px 5px; }
        .dataTables_wrapper { font-family: 'Arial', sans-serif; font-size: 14px; }
        table.dataTable thead th { padding: 12px 10px !important; font-weight: 600; background-color: #f8f9fa; border-bottom: 2px solid #dee2e6 !important; }
        table.dataTable tbody td { padding: 10px !important; vertical-align: top; }
        .section-spacer { margin-bottom: 30px; }
        .well { 
          background-color: #f8f9fa; 
          border-radius: 8px; 
          padding: 20px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          min-height: 250px;
        }
        .well h3 { 
          color: #2C3E50; 
          font-weight: bold; 
          margin: 5px 0;
          font-size: 32px;
        }
        .well h4 { 
          color: #2C3E50; 
          margin-top: 0;
          border-bottom: 2px solid #dee2e6;
          padding-bottom: 10px;
        }
        .well p { 
          color: #6c757d; 
          font-size: 14px;
          margin-bottom: 15px;
        }
        .stat-value {
          font-size: 24px;
          font-weight: bold;
          color: #2C3E50;
          line-height: 1.2;
        }
        .stat-label {
          font-size: 12px;
          color: #6c757d;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        .summarytools-container { 
          font-family: 'Arial', sans-serif; 
          font-size: 12px;
          overflow-x: auto;
          max-height: 600px;
          overflow-y: auto;
          padding: 10px;
          background-color: white;
          border: 1px solid #ddd;
          border-radius: 4px;
        }
        .summarytools-container table {
          border-collapse: collapse;
          width: 100%;
          font-size: 12px;
        }
        .summarytools-container th {
          background-color: #f8f9fa;
          font-weight: 600;
          padding: 8px;
          border: 1px solid #dee2e6;
          text-align: left;
        }
        .summarytools-container td {
          padding: 6px 8px;
          border: 1px solid #dee2e6;
          vertical-align: top;
        }
        .summarytools-container tr:nth-child(even) {
          background-color: #f8f9fa;
        }
      "))
             ),
             
             # -------------------------
             # Dataset Overview
             # -------------------------
             
             tags$div(
               class = "panel-group",
               tags$div(
                 class = "panel panel-default",
                 tags$div(
                   class = "panel-heading",
                   tags$h4(
                     class = "panel-title",
                     tags$a(`data-toggle` = "collapse", href = "#collapseOverview", "Dataset Overview")
                   )
                 ),
                 tags$div(
                   id = "collapseOverview",
                   class = "panel-collapse collapse in",
                   tags$div(
                     class = "panel-body",
                     h5("Dataset Preview (select rows per page)"),
                     DTOutput("summary_overview_table")
                   )
                 )
               )
             ),
             
             # -------------------------
             # Date Range
             # -------------------------
             
             tags$div(
               class = "panel-group",
               tags$div(
                 class = "panel panel-default",
                 tags$div(
                   class = "panel-heading",
                   tags$h4(
                     class = "panel-title",
                     tags$a(`data-toggle` = "collapse", href = "#collapseDateRange", "Date Range")
                   )
                 ),
                 tags$div(
                   id = "collapseDateRange",
                   class = "panel-collapse collapse in",
                   tags$div(
                     class = "panel-body",
                     verbatimTextOutput("summary_date_range")
                   )
                 )
               )
             ),
             
             # -------------------------
             # Variable Types
             # -------------------------
             
             tags$div(
               class = "panel-group",
               tags$div(
                 class = "panel panel-default",
                 tags$div(
                   class = "panel-heading",
                   tags$h4(
                     class = "panel-title",
                     tags$a(`data-toggle` = "collapse", href = "#collapseTypes", "Variable Types")
                   )
                 ),
                 tags$div(
                   id = "collapseTypes",
                   class = "panel-collapse collapse",
                   tags$div(
                     class = "panel-body",
                     DTOutput("summary_variable_types_table")
                   )
                 )
               )
             ),
             
             # -------------------------
             # Numeric Variables Summary
             # -------------------------
             
             tags$div(
               class = "panel-group",
               tags$div(
                 class = "panel panel-default",
                 tags$div(
                   class = "panel-heading",
                   tags$h4(
                     class = "panel-title",
                     tags$a(`data-toggle` = "collapse", href = "#collapseNumeric", "Numeric Variables Summary")
                   )
                 ),
                 tags$div(
                   id = "collapseNumeric",
                   class = "panel-collapse collapse",
                   tags$div(
                     class = "panel-body",
                     DTOutput("summary_numeric_table")
                   )
                 )
               )
             ),
             
             # -------------------------
             # Categorical Variables Summary
             # -------------------------
             
             tags$div(
               class = "panel-group",
               tags$div(
                 class = "panel panel-default",
                 tags$div(
                   class = "panel-heading",
                   tags$h4(
                     class = "panel-title",
                     tags$a(`data-toggle` = "collapse", href = "#collapseCategorical", "Categorical Variables Summary")
                   )
                 ),
                 tags$div(
                   id = "collapseCategorical",
                   class = "panel-collapse collapse",
                   tags$div(
                     class = "panel-body",
                     DTOutput("summary_categorical_table")
                   )
                 )
               )
             ),
             
             # -------------------------
             # Missing Values Summary
             # -------------------------
             
             tags$div(
               class = "panel-group",
               tags$div(
                 class = "panel panel-default",
                 tags$div(
                   class = "panel-heading",
                   tags$h4(
                     class = "panel-title",
                     tags$a(`data-toggle` = "collapse", href = "#collapseMissing", "Missing Values Summary")
                   )
                 ),
                 tags$div(
                   id = "collapseMissing",
                   class = "panel-collapse collapse",
                   tags$div(
                     class = "panel-body",
                     DTOutput("summary_missing_table")
                   )
                 )
               )
             ),
             
             # -------------------------
             # Complete Data Summary (summarytools)
             # -------------------------
             
             tags$div(
               class = "panel-group",
               tags$div(
                 class = "panel panel-default",
                 tags$div(
                   class = "panel-heading",
                   tags$h4(
                     class = "panel-title",
                     tags$a(`data-toggle` = "collapse", href = "#collapseDFSummary", 
                            "Complete Data Summary (summarytools)")
                   )
                 ),
                 tags$div(
                   id = "collapseDFSummary",
                   class = "panel-collapse collapse",
                   tags$div(
                     class = "panel-body",
                     div(class = "summarytools-container",
                         htmlOutput("summary_dfsummary")
                     )
                   )
                 )
               )
             ),
             
             br(), br()
           )
  ),
  
  
  # ============================================================================
  # BOXPLOT MODULE
  # ============================================================================
  
  tabPanel("Boxplot",
           div(id = "boxplot_wrapper",
               
               sidebarLayout(
                 sidebarPanel(id = "sidebar_boxplot",
                              
                              
                              # -----------------------------
                              # Visualisation Options
                              # -----------------------------
                              
                              h4("Data Transformation:"),
                              
                              sliderInput("iqr_multiplier", "Outlier IQR Multiplier:", 
                                          min = 0.5, max = 12.5, value = 1.5, step = 0.1),
                              
                              checkboxInput("center_data", "Center data:", FALSE),
                              checkboxInput("scale_data", "Scale data:", FALSE),
                              
                              hr(),
                              
                              # -----------------------------
                              # Variable Selection
                              # -----------------------------
                              
                              h4("Variable Selection:"),
                              
                              dateRangeInput("date_range", "Select Date Range:",
                                             start = min(df$Date, na.rm = TRUE), 
                                             end = max(df$Date, na.rm = TRUE)),
                              
                              pickerInput("numeric_vars", "Select Numeric Variables:", 
                                          choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                              
                              pickerInput("categorical_vars", "Select Categorical Variables:", 
                                          choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                              
                              checkboxInput("include_null_boxplot", 
                                            "Include NULL values in count and visualisations", 
                                            value = FALSE),
                              
                              uiOutput("categorical_filters")
                 ),
                 
                 mainPanel(
                   shinycssloaders::withSpinner(
                     plotlyOutput("boxplot", height = "650px"),
                     type = 4,
                     color = "#2C3E50",
                     size = 0.7
                   ),
                   br(),
                   textOutput("obs_count")
                 )
               )
           )),
  
  
  # ============================================================================
  # CORRELATION MODULE
  # ============================================================================
  
  tabPanel("Correlation",
           div(id = "correlation_wrapper",
               
               sidebarLayout(
                 sidebarPanel(id = "sidebar_correlation",
                            
                              # -----------------------------
                              # Visualisation Options
                              # -----------------------------
                              
                              h4("Correlation Settings:"),
                              
                              selectInput("corr_method",
                                          "Correlation Method:",
                                          choices = c("Pearson" = "pearson",
                                                      "Spearman" = "spearman",
                                                      "Kendall" = "kendall"),
                                          selected = "pearson"),
                              
                              selectInput("corr_order",
                                          "Order Variables By:",
                                          choices = c("Original" = "original", "AOE", "FPC", 
                                                      "Hierarchical Clustering" = "hclust", 
                                                      "Alphabetical" = "alphabet"),
                                          selected = "AOE"),
                              
                              conditionalPanel(
                                condition = "input.corr_order == 'hclust'",
                                selectInput("hclust_method",
                                            "Hierarchical Clustering Method:",
                                            choices = c("ward" = "ward",
                                                        "ward.D" = "ward.D",
                                                        "ward.D2" = "ward.D2",
                                                        "single" = "single",
                                                        "complete" = "complete",
                                                        "average" = "average",
                                                        "mcquitty" = "mcquitty",
                                                        "median" = "median",
                                                        "centroid" = "centroid"),
                                            selected = "complete")
                              ),
                              
                              h5("Further Features:"),
                              
                              checkboxInput("corr_abs", "Use Absolute Correlations:", FALSE),
                              checkboxInput("corr_show_values", "Show Correlation Values:", TRUE),
                              
                              conditionalPanel(
                                condition = "input.corr_show_values == true",
                                selectInput("corr_digits",
                                            "Decimal Places:",
                                            choices = c("1" = 1, "2" = 2, "3" = 3),
                                            selected = 1)
                              ),
                              
                              hr(),
                              
                              # -----------------------------
                              # Variable Selection
                              # -----------------------------
                              
                              h4("Variable Selection:"),
                              
                              dateRangeInput("corr_date_range", "Select Date Range:",
                                             start = min(df$Date, na.rm = TRUE), 
                                             end = max(df$Date, na.rm = TRUE)),
                              
                              pickerInput("corr_numeric_vars", "Select Numeric Variables:", 
                                          choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                              
                              pickerInput("corr_categorical_vars", "Select Categorical Variables:", 
                                          choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                              
                              checkboxInput("include_null_correlation", 
                                            "Include NULL values in count and visualisations", 
                                            value = FALSE),
                              
                              uiOutput("corr_categorical_filters")
                              
                 ),
                 
                 mainPanel(
                   shinycssloaders::withSpinner(
                     plotlyOutput("corr_plot", height = "650px"),
                     type = 4,
                     color = "#2C3E50",
                     size = 0.7
                   ),
                   br(),
                   textOutput("corr_obs_count")
                 )
               )
           )),
  
  
  # ============================================================================
  # MISSING VALUES MODULE
  # ============================================================================
  
  tabPanel("Missing Values",
           div(id = "mv_wrapper",
               
               sidebarLayout(
                 sidebarPanel(id = "sidebar_missing",
                              
                              # -----------------------------
                              # Visualisation Options
                              # -----------------------------
                              
                              h4("Visualisation Options:"),
                              
                              selectInput("mv_order_missing",
                                          "Order Variables By:",
                                          choices = c("Original Order" = "original",
                                                      "Percentage Missing (Descending)" = "desc",
                                                      "Percentage Missing (Ascending)" = "asc"),
                                          selected = "original"),
                              
                              hr(),
                              
                              # -----------------------------
                              # Variable Selection
                              # -----------------------------
                              
                              h4("Variable Selection:"),
                              
                              dateRangeInput("mv_date_range", "Select Date Range:",
                                             start = min(df$Date, na.rm = TRUE),
                                             end = max(df$Date, na.rm = TRUE)),
                              
                              pickerInput("mv_numeric_vars", "Select Numeric Variables:", 
                                          choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                              
                              pickerInput("mv_categorical_vars", "Select Categorical Variables:", 
                                          choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                              
                              uiOutput("mv_categorical_filters")
                 ),
                 
                 mainPanel(
                   shinycssloaders::withSpinner(
                     plotlyOutput("mv_plot", height = "650px"),
                     type = 4,
                     color = "#2C3E50",
                     size = 0.7
                   ),
                   br(),
                   textOutput("mv_obs_count")
                 )
               )
           )
  ),
  
  
  # ============================================================================
  # RISING VALUES MODULE
  # ============================================================================
  
  tabPanel("Rising Values",
           div(id = "rv_wrapper",
               sidebarLayout(
                 sidebarPanel(id = "sidebar_rising",
                              
                              # -----------------------------
                              # Visualisation Options
                              # -----------------------------
                              
                              h4("Visualisation Options:"),
                              
                              checkboxInput("rv_standardise",
                                            "Standardise values (Z-score)",
                                            value = TRUE),
                              
                              hr(),
                              
                              # -----------------------------
                              # Variable Selection
                              # -----------------------------
                              
                              h4("Variable Selection:"),
                              
                              dateRangeInput("rv_date_range", "Select Date Range:",
                                             start = min(df$Date, na.rm = TRUE),
                                             end = max(df$Date, na.rm = TRUE)),
                              
                              pickerInput("rv_numeric_vars", "Select Numeric Variables:",
                                          choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                              
                              pickerInput("rv_categorical_vars", "Select Categorical Variables:",
                                          choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                              
                              checkboxInput("rv_include_null", 
                                            "Include NULL values in count and visualisations", 
                                            value = FALSE),
                              
                              uiOutput("rv_categorical_filters")
                 ),
                 
                 mainPanel(
                   shinycssloaders::withSpinner(
                     plotlyOutput("rv_plot", height = "600px"),
                     type = 4,
                     color = "#2C3E50",
                     size = 0.7
                   ),
                   br(),
                   textOutput("rv_obs_count")
                 )
               )
           )
  ),
  
  
  # ============================================================================
  # TIME SERIES MODULE
  # ============================================================================
  
  tabPanel("Time Series",
           div(id = "ts_wrapper",
               
               sidebarLayout(
                 sidebarPanel(id = "sidebar_timeseries",
                              
                              # -----------------------------
                              # Visualisation Options
                              # -----------------------------
                              
                              h4("Data Transformation:"),
                              
                              checkboxInput("ts_center", "Center data (subtract mean)", FALSE),
                              checkboxInput("ts_scale", "Scale data (divide by SD)", FALSE),
                              
                              hr(),
                              
                              h4("Smoothing Options:"),
                              
                              checkboxInput("ts_smooth", "Add smooth line", TRUE),
                              
                              conditionalPanel(
                                condition = "input.ts_smooth == true",
                                selectInput("ts_smooth_method",
                                            "Smoothing Method:",
                                            choices = c("LOESS" = "loess",
                                                        "Linear Model" = "lm",
                                                        "Generalised Additive Model" = "gam"),
                                            selected = "loess"),
                                
                                # LOESS span slider: it only appears once LOESS is selected
                                conditionalPanel(
                                  condition = "input.ts_smooth_method == 'loess'",
                                  sliderInput("ts_smooth_span",
                                              "LOESS Span (smoothness):",
                                              min = 0.1, max = 1, value = 0.3, step = 0.05)
                                )
                              ),
                              
                              hr(),
                              
                              # -----------------------------
                              # Variable Selection
                              # -----------------------------
                              
                              h4("Variable Selection:"),
                              
                              dateRangeInput("ts_date_range", "Select Date Range:",
                                             start = min(df$Date, na.rm = TRUE),
                                             end = max(df$Date, na.rm = TRUE)),
                              
                              pickerInput("ts_numeric_vars", "Select Numeric Variables (max 6):",
                                          choices = NULL, multiple = TRUE,
                                          options = list(
                                            `actions-box` = TRUE,
                                            `live-search` = TRUE,
                                            `selected-text-format` = "count > 3",
                                            `count-selected-text` = "{0} variables selected"
                                          )),
                              
                              pickerInput("ts_categorical_vars", "Select Categorical Variables:",
                                          choices = NULL, multiple = TRUE,
                                          options = list(
                                            `actions-box` = TRUE,
                                            `live-search` = TRUE,
                                            `selected-text-format` = "count > 3"
                                          )),
                              
                              checkboxInput("ts_include_null",
                                            "Include NULL values in visualisations",
                                            value = FALSE),
                              
                              uiOutput("ts_categorical_filters"),
                              
                              hr(),
                              
                              # Warning for too many variables
                              uiOutput("ts_variable_warning")
                 ),
                 
                 mainPanel(
                   # Title
                   h4("Time Series Plot", style = "margin-top: 10px; margin-bottom: 15px;"),
                   
                   # Plot
                   shinycssloaders::withSpinner(
                     plotlyOutput("ts_plot", height = "600px"),
                     type = 4,
                     color = "#2C3E50",
                     size = 0.7
                   ),
                   
                   # Observation count
                   br(),
                   textOutput("ts_obs_count"),
                   br(),
                   
                   # Summary statistics table
                   conditionalPanel(
                     condition = "output.ts_has_data == true",
                     h5("Summary Statistics by Variable:"),
                     DTOutput("ts_summary_table")
                   )
                 )
               )
           )
  ),
  
  
  # ============================================================================
  # TABPLOT MODULE
  # ============================================================================
  
  tabPanel("Tabplot",
           div(id = "tabplot_wrapper",
               
               sidebarLayout(
                 sidebarPanel(id = "sidebar_tabplot",
                              
                              # -----------------------------
                              # Visualisation Options
                              # -----------------------------
                              
                              h4("Plot Settings:"),
                              
                              sliderInput("tabplot_nbins",
                                          "Number of bins:",
                                          min = 12, max = 72, value = 36, step = 6,
                                          post = " bins"),
                              
                              radioButtons("tabplot_time_order",
                                           "Order by Date:",
                                           choices = c(
                                             "Oldest First" = "asc",
                                             "Newest First" = "desc"
                                           ),
                                           selected = "asc"),
                              
                              checkboxInput("tabplot_showNA",
                                            "Show missing values as separate category",
                                            value = TRUE),
                              
                              hr(),
                              
                              # -----------------------------
                              # Variable Selection
                              # -----------------------------
                              
                              h4("Variable Selection:"),
                              
                              dateRangeInput("tabplot_date_range", "Select Date Range:",
                                             start = min(df$Date, na.rm = TRUE),
                                             end = max(df$Date, na.rm = TRUE)),
                              
                              pickerInput("tabplot_numeric_vars", "Select Numeric Variables:",
                                          choices = NULL, multiple = TRUE,
                                          options = list(
                                            `actions-box` = TRUE,
                                            `live-search` = TRUE,
                                            `selected-text-format` = "count > 5"
                                          )),
                              
                              pickerInput("tabplot_categorical_vars", "Select Categorical Variables:",
                                          choices = NULL, multiple = TRUE,
                                          options = list(
                                            `actions-box` = TRUE,
                                            `live-search` = TRUE,
                                            `selected-text-format` = "count > 5"
                                          )),
                              
                              checkboxInput("tabplot_include_null",
                                            "Include NULL values",
                                            value = TRUE),
                              
                              uiOutput("tabplot_categorical_filters")
                 ),
                 
                 mainPanel(
                   # Title as HTML text above the plot
                   h4("Tableplot Visualisation", style = "margin-top: 10px; margin-bottom: 15px;"),
                   
                   # Dynamic subtitle showing current settings
                   htmlOutput("tabplot_title_info", style = "margin-bottom: 15px; color: #2C3E50; font-size: 14px;"),
                   
                   # Plot with spinner
                   div(class = "plot-container",
                       shinycssloaders::withSpinner(
                         plotOutput("tabplot_plot", height = "650px", width = "100%"),
                         type = 4,
                         color = "#2C3E50",
                         size = 1
                       )
                   ),
                   
                   # Observation count below plot 
                   br(),
                   textOutput("tabplot_obs_count")
                 )
               )
           )
  ),
  
  
  # ============================================================================
  # MOSAIC PLOT MODULE
  # ============================================================================
  
  tabPanel("Mosaic Plot",
           div(id = "mosaic_wrapper",
               
               sidebarLayout(
                 sidebarPanel(id = "sidebar_mosaic",
                              
                              h4("Variable Selection:"),
                              
                              dateRangeInput("mosaic_date_range", "Select Date Range:",
                                             start = min(df$Date, na.rm = TRUE),
                                             end = max(df$Date, na.rm = TRUE)),

                              checkboxInput("mosaic_include_null", 
                                            "Include NULL values in plot", 
                                            value = FALSE),
                              
                              hr(),
                              
                              selectInput("mosaic_x",
                                          "Primary Variable (Outer Split):",
                                          choices = NULL),
                              
                              selectInput("mosaic_y",
                                          "Secondary Variable (Inner Split):",
                                          choices = NULL),
                              
                              selectInput("mosaic_z",
                                          "Optional Third Variable:",
                                          choices = c("None"),
                                          selected = "None"),
                              
                              selectInput("mosaic_w",
                                          "Optional Fourth Variable:",
                                          choices = c("None"),
                                          selected = "None"),
                              
                              hr(),
                              p("Variables are applied hierarchically: x (outer) → y → z → w (inner)", 
                                style = "font-size: 0.9em; color: #6c757d;")
                 ),
                 mainPanel(
                   div(class = "plot-container",
                       shinycssloaders::withSpinner(
                         plotOutput("mosaic_plot", height = "650px"),
                         type = 4,
                         color = "#2C3E50",
                         size = 1
                       )
                   ),
                   br(),
                   textOutput("mosaic_obs_count")
                 )
               )
           )
  ),
  
  
  # ============================================================================
  # GGPAIRS MODULE
  # ============================================================================
  
  tabPanel("GGpairs Plot",
           div(id = "ggpairs_wrapper",
               
               sidebarLayout(
                 sidebarPanel(id = "sidebar_ggpairs",
                              
                              h4("Visualisation Options:"),
                              
                              checkboxInput("ggpairs_show_cor", 
                                            "Show Correlation Values", value = TRUE),
                              
                              hr(),
                              
                              h4("Variable Selection (Max 10 total):"),
                              
                              dateRangeInput("ggpairs_date_range", "Select Date Range:",
                                             start = min(df$Date, na.rm = TRUE),
                                             end = max(df$Date, na.rm = TRUE)),
                              
                              # Deselect All buttons
                              div(
                                style = "margin-bottom: 10px;",
                                fluidRow(
                                  column(6,
                                         actionLink("deselect_numeric", "Clear Numeric", 
                                                    icon = icon("times-circle"),
                                                    style = "color: #dc3545;")
                                  ),
                                  column(6,
                                         actionLink("deselect_categorical", "Clear Categorical", 
                                                    icon = icon("times-circle"),
                                                    style = "color: #dc3545;")
                                  )
                                )
                              ),
                              
                              # Numeric variables picker (with actions-box = FALSE)
                              pickerInput("ggpairs_numeric_vars",
                                          "Numeric Variables:",
                                          choices = NULL,
                                          multiple = TRUE,
                                          options = list(
                                            `actions-box` = FALSE,
                                            `live-search` = TRUE,
                                            `selected-text-format` = "count > 3",
                                            `count-selected-text` = "{0} numeric vars selected"
                                          )),
                              
                              # Categorical variables picker (with actions-box = FALSE)  
                              pickerInput("ggpairs_categorical_vars",
                                          "Categorical Variables:",
                                          choices = NULL,
                                          multiple = TRUE,
                                          options = list(
                                            `actions-box` = FALSE,
                                            `live-search` = TRUE,
                                            `selected-text-format` = "count > 3",
                                            `count-selected-text` = "{0} categorical vars selected"
                                          )),
                              
                              # Total count display
                              uiOutput("ggpairs_total_count"),
                              
                              selectInput("ggpairs_color",
                                          "Color by (optional):",
                                          choices = NULL,
                                          selected = NULL)
                 ),
                 mainPanel(
                   div(class = "plot-container",
                       shinycssloaders::withSpinner(
                         plotlyOutput("ggpairs_plot", height = "800px", width = "100%"),
                         type = 4,
                         color = "#2C3E50",
                         size = 1
                       )
                   ),
                   br(),
                   textOutput("ggpairs_obs_count")
                 )
               )
           )),
  
  
  # ============================================================================
  # DATA TABLE
  # ============================================================================
  
  tabPanel("Data Table", 
           div(id = "datatable_wrapper",
               
               sidebarLayout(
                 sidebarPanel(id = "sidebar_datatable",
                              
                              h4("Data Table Options"),
                              
                              # Column selection picker
                              pickerInput("dt_columns", 
                                          "Select Columns to Display:",
                                          choices = NULL,
                                          multiple = TRUE,
                                          selected = NULL,
                                          options = list(
                                            `actions-box` = TRUE,
                                            `live-search` = TRUE,
                                            `selected-text-format` = "count > 5",
                                            `count-selected-text` = "{0} columns selected"
                                          )),
                              
                              # Select/Deselect all buttons
                              div(
                                style = "margin-bottom: 15px;",
                                actionButton("dt_select_all", "Select All", 
                                             icon = icon("check-square"), width = "48%"),
                                actionButton("dt_deselect_all", "Deselect All", 
                                             icon = icon("square"), width = "48%")
                              ),
                              
                              hr(),
                              
                              # Page length selector
                              h4("Display Options"),
                              
                              selectInput("dt_page_length",
                                          "Rows per page:",
                                          choices = c("15" = 15, 
                                                      "25" = 25, 
                                                      "50" = 50, 
                                                      "100" = 100,
                                                      "All" = -1),
                                          selected = 15),
                              
                              br(),
                              
                              p("Use the filters below each column to subset the data."),
                              p("Export buttons available for copying, CSV, Excel, PDF, and printing.")
                 ),
                 
                 mainPanel(
                   shinycssloaders::withSpinner(
                     DTOutput("datatable"),
                     type = 4,
                     color = "#2C3E50",
                     size = 0.7
                   )
                 )
               )
           )
  )
  
)

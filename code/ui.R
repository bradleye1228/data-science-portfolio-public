# ========================================================================
# UI.R - DATA423 ASSIGNMENT 3
# Author: Eduard Bradley
# ========================================================================

shinyUI(
  navbarPage(
    title = "DATA423 Assignment 3 - Eduard Bradley",
    theme = shinytheme("cerulean"),
    useShinyjs(),
    
    # ====================================================================
    # ====================================================================
    # SECTION 1: CSS STYLING
    # ====================================================================
    # ====================================================================
    
    tags$head(
      tags$style(HTML("
      .well {
        background-color: #f8f9fa;
        border-radius: 5px;
        border: 1px solid #e3e3e3;
      }
      .panel-heading:hover {
        background-color: #f5f5f5;
        cursor: pointer;
      }
      .summarytools-container .table {
        font-size: 12px;
      }
      .summarytools-container .table td, 
      .summarytools-container .table th {
        padding: 4px;
      }
      .tab-content {
        padding-top: 20px;
      }
      
      /* ======================================== */
      /* SIDEBAR TOGGLE - IMPROVED LAYOUT */
      /* ======================================== */
      
      .sidebar-wrapper {
        position: relative;
        transition: all 0.3s ease;
        width: 100%;
      }
      
      /* Flexbox container for sidebar + main */
      .sidebar-wrapper .row {
        display: flex !important;
        flex-wrap: nowrap !important;
        align-items: flex-start !important;
        margin-left: 0 !important;
        margin-right: 0 !important;
        width: 100% !important;
      }
      
      /* Sidebar panel styling - fixed width when visible */
      .sidebar-wrapper .sidebar-panel {
        flex: 0 0 280px !important;
        width: 280px !important;
        max-width: 280px !important;
        transition: all 0.3s ease;
        overflow-y: auto;
        max-height: calc(100vh - 150px);
        position: sticky;
        top: 10px;
      }
      
      /* Main panel - takes remaining space */
      .sidebar-wrapper .main-panel {
        flex: 1 1 auto !important;
        width: calc(100% - 280px) !important;
        min-width: 0 !important;
        transition: all 0.3s ease;
        overflow-x: auto;
        padding-left: 15px !important;
        padding-right: 15px !important;
      }
      
      /* When sidebar is hidden */
      .sidebar-wrapper.sidebar-hidden .sidebar-panel {
        display: none !important;
      }
      
      .sidebar-wrapper.sidebar-hidden .main-panel {
        width: 100% !important;
        flex: 1 1 100% !important;
        margin-left: 0 !important;
      }
      
      /* Ensure plot containers are responsive */
      .sidebar-wrapper .main-panel .plotly,
      .sidebar-wrapper .main-panel .plotly.html-widget,
      .sidebar-wrapper .main-panel .js-plotly-plot {
        width: 100% !important;
        max-width: 100% !important;
      }
      
      /* Plot container scrolling if needed */
      .plotly-container {
        width: 100%;
        overflow-x: auto;
      }
      
      /* Toggle button container */
      .toggle-container {
        text-align: right;
        margin-bottom: 10px;
      }
      
      /* ======================================== */
      /* FIX FOR ALL EDA TOGGLE WRAPPERS */
      /* ======================================== */
      
      #boxplot_wrapper,
      #correlation_wrapper,
      #heatmap_wrapper,
      #distribution_wrapper,
      #scatter_wrapper,
      #ggpairs_wrapper,
      #datatable_wrapper,
      #pred_wrapper,
      #residual_wrapper,
      #residual_boxplot_wrapper {
        width: 100%;
        position: relative;
      }
      
      /* Ensure these wrappers use flex */
      #boxplot_wrapper .row,
      #correlation_wrapper .row,
      #heatmap_wrapper .row,
      #distribution_wrapper .row,
      #scatter_wrapper .row,
      #ggpairs_wrapper .row,
      #datatable_wrapper .row,
      #pred_wrapper .row,
      #residual_wrapper .row,
      #residual_boxplot_wrapper .row {
        display: flex !important;
        flex-wrap: nowrap !important;
      }
      
      /* Override Bootstrap column classes for our layout */
      .sidebar-wrapper .sidebar-panel[class*='col-'] {
        flex: 0 0 280px !important;
        width: 280px !important;
        max-width: 280px !important;
        padding-left: 5px !important;
        padding-right: 5px !important;
      }
      
      .sidebar-wrapper .main-panel[class*='col-'] {
        flex: 1 1 auto !important;
        width: calc(100% - 280px) !important;
        padding-left: 15px !important;
        padding-right: 15px !important;
      }
      
      /* When sidebar hidden, override main panel width */
      .sidebar-wrapper.sidebar-hidden .main-panel[class*='col-'] {
        width: 100% !important;
      }
      
      /* ======================================== */
      /* PLOT SIZING AND SCROLLING */
      /* ======================================== */
      
      .plotly.html-widget {
        width: 100% !important;
        min-width: 100% !important;
      }
      
      .js-plotly-plot .plotly .svg-container {
        width: 100% !important;
        min-width: 100% !important;
      }
      
      /* Allow plots to scroll horizontally if needed */
      .plotly.html-widget-bound {
        width: 100% !important;
        overflow-x: auto;
      }
      
      /* ======================================== */
      /* ENHANCED PLOTLY STYLING */
      /* ======================================== */
      
      .js-plotly-plot .plotly .boxplot .box {
        fill: #13D4D4;
        fill-opacity: 0.7;
        stroke: #2C3E50;
        stroke-width: 1.5px;
      }
      
      .js-plotly-plot .plotly .boxplot .median {
        stroke: #e74c3c;
        stroke-width: 2px;
      }
      
      .js-plotly-plot .plotly .boxplot .mean {
        stroke: #f39c12;
        stroke-width: 2px;
      }
      
      .js-plotly-plot .plotly .boxplot .outlier {
        fill: #e74c3c;
        fill-opacity: 0.8;
        stroke: none;
      }
      
      /* Hover label styling */
      .hoverlayer .hoverlabel {
        background-color: white !important;
        border: 1px solid #2C3E50 !important;
        border-radius: 4px !important;
        font-family: monospace !important;
        font-size: 11px !important;
      }
      
      .hoverlayer .hoverlabel .name {
        color: #2C3E50 !important;
        font-weight: bold !important;
      }
      
      /* Axis styling */
      .main-svg .xtick line, 
      .main-svg .ytick line {
        stroke: #e0e0e0 !important;
        stroke-width: 0.5px !important;
      }
      
      .main-svg .xaxis-title, 
      .main-svg .yaxis-title {
        fill: #2C3E50 !important;
        font-size: 12px !important;
      }
      
      .main-svg .xtick text, 
      .main-svg .ytick text {
        fill: #2C3E50 !important;
        font-size: 10px !important;
      }
      
      /* Legend styling */
      .legend .traces .legendtext {
        fill: #2C3E50 !important;
        font-size: 10px !important;
      }
      
      /* Heatmap text readability */
      .heatmap text {
        font-size: 10px !important;
      }
      
      /* ======================================== */
      /* RESPONSIVE ADJUSTMENTS */
      /* ======================================== */
      
      @media (max-width: 992px) {
        .sidebar-wrapper .row {
          flex-direction: column !important;
        }
        
        .sidebar-wrapper .sidebar-panel,
        .sidebar-wrapper .sidebar-panel[class*='col-'] {
          flex: 0 0 100% !important;
          width: 100% !important;
          max-width: 100% !important;
          margin-bottom: 15px;
          position: relative;
          top: 0;
        }
        
        .sidebar-wrapper .main-panel,
        .sidebar-wrapper .main-panel[class*='col-'] {
          width: 100% !important;
          flex: 1 1 100% !important;
          padding-left: 0 !important;
        }
      }
      
      @media (max-width: 768px) {
        .sidebar-wrapper .sidebar-panel {
          width: 100% !important;
          margin-bottom: 15px;
        }
        
        .sidebar-wrapper .main-panel {
          width: 100% !important;
        }
        
        .js-plotly-plot .plotly {
          height: auto !important;
          min-height: 400px;
        }
      }
      
      /* Sidebar panel scroll styling */
      .sidebar-panel::-webkit-scrollbar {
        width: 6px;
      }
      
      .sidebar-panel::-webkit-scrollbar-track {
        background: #f1f1f1;
        border-radius: 3px;
      }
      
      .sidebar-panel::-webkit-scrollbar-thumb {
        background: #888;
        border-radius: 3px;
      }
      
      .sidebar-panel::-webkit-scrollbar-thumb:hover {
        background: #555;
      }
      ")),
      
      # Bootstrap collapse JS
      tags$script(src = "https://cdn.jsdelivr.net/npm/bootstrap@3.4.1/dist/js/bootstrap.min.js")
      
    ),
      
    
    
    
    
    # ====================================================================
    # ====================================================================
    # SECTION 2: EDA MAIN TAB
    # ====================================================================
    # ====================================================================
    
    tabPanel("EDA",
             tabsetPanel(
               
               # ----------------------------------------------------------------
               # Data Summary Sub-Tab
               # ----------------------------------------------------------------
               
               tabPanel("Data Summary",
                        fluidPage(
                          h3("Dataset Summary Statistics"),
                          hr(),
                          
                          # Dataset Dimensions and Quality
                          fluidRow(
                            column(4, 
                                   div(class = "well", style = "padding: 10px;",
                                       h5("Dataset Dimensions", style = "margin-top: 2px;"),
                                       hr(style = "margin-top: 5px; margin-bottom: 10px;"),
                                       fluidRow(
                                         column(6,
                                                h4(textOutput("summary_row_count"), style = "margin: 2px;"),
                                                p("Rows", style = "font-size: 12px; margin: 0;"),
                                                br(),
                                                h4(textOutput("summary_total_cells"), style = "margin: 2px;"),
                                                p("Total Cells", style = "font-size: 12px; margin: 0;")
                                         ),
                                         column(6,
                                                h4(textOutput("summary_col_count"), style = "margin: 2px;"),
                                                p("Columns", style = "font-size: 12px; margin: 0;"),
                                                br(),
                                                h4(textOutput("summary_non_na_values"), style = "margin: 2px;"),
                                                p("Data Points", style = "font-size: 12px; margin: 0;")
                                         )
                                       )
                                   )
                            ),
                            column(8,
                                   div(class = "well", style = "padding: 10px;",
                                       h5("Data Quality", style = "margin-top: 2px;"),
                                       hr(style = "margin-top: 5px; margin-bottom: 10px;"),
                                       fluidRow(
                                         column(3, uiOutput("summary_complete_cases")),
                                         column(3, uiOutput("summary_incomplete_cases")),
                                         column(3, uiOutput("summary_missing_cells")),
                                         column(3, uiOutput("summary_data_completeness"))
                                       ),
                                       fluidRow(
                                         column(3, uiOutput("summary_numeric_count")),
                                         column(3, uiOutput("summary_categorical_count")),
                                         column(6, uiOutput("summary_missing_types"))
                                       )
                                   )
                            )
                          ),
                          
                          br(),
                          
                          # Collapsible: Numeric Variables Summary
                          tags$div(class = "panel-group",
                                   tags$div(class = "panel panel-default",
                                            tags$div(class = "panel-heading",
                                                     tags$h4(class = "panel-title",
                                                             tags$a(`data-toggle` = "collapse", href = "#collapseNumeric", 
                                                                    "Numeric Variables Summary",
                                                                    style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                     )
                                            ),
                                            tags$div(id = "collapseNumeric", class = "panel-collapse collapse",
                                                     tags$div(class = "panel-body", DT::DTOutput("summary_numeric_table"))
                                            )
                                   )
                          ),
                          
                          br(),
                          
                          # Collapsible: Categorical Variables Summary
                          tags$div(class = "panel-group",
                                   tags$div(class = "panel panel-default",
                                            tags$div(class = "panel-heading",
                                                     tags$h4(class = "panel-title",
                                                             tags$a(`data-toggle` = "collapse", href = "#collapseCategorical", 
                                                                    "Categorical Variables Summary",
                                                                    style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                     )
                                            ),
                                            tags$div(id = "collapseCategorical", class = "panel-collapse collapse",
                                                     tags$div(class = "panel-body", DT::DTOutput("summary_categorical_table"))
                                            )
                                   )
                          ),
                          
                          br(),
                          
                          # Collapsible: Date Variables Summary with working buttons
                          tags$div(class = "panel-group",
                                   tags$div(class = "panel panel-default",
                                            tags$div(class = "panel-heading",
                                                     tags$h4(class = "panel-title",
                                                             tags$a(`data-toggle` = "collapse", href = "#collapseDate",
                                                                    "Date Variables Summary",
                                                                    style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                     )
                                            ),
                                            tags$div(id = "collapseDate", class = "panel-collapse collapse",
                                                     tags$div(class = "panel-body",
                                                              plotlyOutput(outputId = "summary_date_plot", height = "300px"),
                                                              br(),
                                                              DT::DTOutput("summary_date_table")
                                                     )
                                            )
                                   )
                          ),
                          
                          br(),
                          
                          # Collapsible: Missing Values Summary
                          tags$div(class = "panel-group",
                                   tags$div(class = "panel panel-default",
                                            tags$div(class = "panel-heading",
                                                     tags$h4(class = "panel-title",
                                                             tags$a(`data-toggle` = "collapse", href = "#collapseMissing", 
                                                                    "Missing Values Summary by Variable",
                                                                    style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                     )
                                            ),
                                            tags$div(id = "collapseMissing", class = "panel-collapse collapse",
                                                     tags$div(class = "panel-body", DT::DTOutput("summary_missing_table"))
                                            )
                                   )
                          ),
                          
                          br(),
                          
                          # Collapsible: Complete Data Summary
                          tags$div(class = "panel-group",
                                   tags$div(class = "panel panel-default",
                                            tags$div(class = "panel-heading",
                                                     tags$h4(class = "panel-title",
                                                             tags$a(`data-toggle` = "collapse", href = "#collapseDFSummary", 
                                                                    "Complete Data Summary (summarytools)",
                                                                    style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                     )
                                            ),
                                            tags$div(id = "collapseDFSummary", class = "panel-collapse collapse",
                                                     tags$div(class = "panel-body",
                                                              div(class = "summarytools-container", htmlOutput("summary_dfsummary"))
                                                     )
                                            )
                                   )
                          ),
                          br()
                        )
               ),
               
               # ----------------------------------------------------------------
               # Boxplot Analysis Sub-Tab
               # ----------------------------------------------------------------
               
               tabPanel("Boxplot Analysis",
                        div(id = "boxplot_wrapper", class = "sidebar-wrapper",
                            fluidRow(
                              # Sidebar
                              div(id = "boxplot_sidebar_panel", class = "col-sm-3 sidebar-panel",
                                  h4("Data Transformation:"),
                                  sliderInput("iqr_boxplot", "Outlier IQR Multiplier:", 
                                              min = 0.1, max = 2.5, value = 1.5, step = 0.1),
                                  checkboxInput("boxplot_center", "Center data:", TRUE),
                                  checkboxInput("boxplot_scale", "Scale data:", TRUE),
                                  hr(),
                                  h4("Variable Selection:"),
                                  selectizeInput("boxplot_numeric_vars", "Select Numeric Variables:", 
                                              choices = NULL, selected = NULL, multiple = TRUE,
                                              options = list(`actions-box` = TRUE, `live-search` = TRUE,
                                                             `selected-text-format` = "count > 3")),

                                  hr(),
                                  h4("Filter Data by Categorical Variables:"),
                                  selectizeInput("boxplot_filter_vars", "Select Categorical Variables to Filter:", 
                                              choices = NULL, selected = NULL, multiple = TRUE,
                                              options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                                  uiOutput("boxplot_cat_filters_ui"),
                                  hr(),
                                  
                                  checkboxInput("include_null_boxplot", 
                                                "Include rows with missing values:", 
                                                value = FALSE),
                                  
                                  br(),
                                  actionButton("reset_boxplot", "Reset to Defaults", 
                                               class = "btn-warning btn-sm", style = "width: 100%;")
                              ),
                              
                              # Main Panel
                              div(id = "boxplot_main_panel", class = "col-sm-9 main-panel",
                                  div(class = "toggle-container",
                                      actionButton("toggle_boxplot_sidebar", 
                                                   label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                                                   class = "btn-primary btn-sm",
                                                   style = "background-color: #2C3E50; border-color: #2C3E50;")
                                  ),
                                  shinycssloaders::withSpinner(
                                    plotlyOutput("boxplot_plot", height = "600px"),
                                    type = 4, color = "#2C3E50", size = 0.7
                                  ),
                                  br(), hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse", href = "#collapseBoxplotStats", 
                                                                            "Boxplot Statistics",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapseBoxplotStats", class = "panel-collapse collapse",
                                                             tags$div(class = "panel-body", verbatimTextOutput("boxplot_stats"))
                                                    )
                                           )
                                  )
                              )
                            )
                        )
               ),
               
               # ----------------------------------------------------------------
               # Correlation Analysis Sub-Tab
               # ----------------------------------------------------------------
               
               tabPanel("Correlation Analysis",
                        div(id = "correlation_wrapper", class = "sidebar-wrapper",
                            fluidRow(
                              # Sidebar
                              div(id = "correlation_sidebar_panel", class = "col-sm-3 sidebar-panel",
                                  h4("Correlation Settings:"),
                                  selectInput("corr_method", "Correlation Method:",
                                              choices = c("Pearson" = "pearson", "Spearman" = "spearman", "Kendall" = "kendall"),
                                              selected = "pearson"),
                                  selectInput("corr_order", "Variable Ordering:",
                                              choices = c("Original" = "original", "AOE", "FPC", 
                                                          "Hierarchical Clustering" = "hclust", "Alphabetical" = "alphabet"),
                                              selected = "AOE"),
                                  conditionalPanel(
                                    condition = "input.corr_order == 'hclust'",
                                    selectInput("hclust_method", "Clustering Method:",
                                                choices = c("ward", "ward.D", "ward.D2", "single", "complete", 
                                                            "average", "mcquitty", "median", "centroid"),
                                                selected = "complete")
                                  ),
                                  hr(),
                                  h5("Further Features:"),
                                  checkboxInput("corr_abs", "Use Absolute Correlations:", FALSE),
                                  checkboxInput("corr_show_values", "Show Correlation Values:", TRUE),
                                  conditionalPanel(
                                    condition = "input.corr_show_values == true",
                                    selectInput("corr_digits", "Decimal Places:",
                                                choices = c("1" = 1, "2" = 2, "3" = 3), selected = 2)
                                  ),
                                  hr(),
                                  h4("Missing Value Handling:"),
                                  checkboxInput("corr_na_omit", "Remove rows with missing values", value = TRUE),
                                  br(),
                                  actionButton("reset_correlation", "Reset to Defaults", 
                                               class = "btn-warning btn-sm", style = "width: 100%;")
                              ),
                              
                              # Main Panel
                              div(id = "correlation_main_panel", class = "col-sm-9 main-panel",
                                  div(class = "toggle-container",
                                      actionButton("toggle_correlation_sidebar", 
                                                   label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                                                   class = "btn-primary btn-sm",
                                                   style = "background-color: #2C3E50; border-color: #2C3E50;")
                                  ),
                                  shinycssloaders::withSpinner(
                                    plotlyOutput("correlation_plot", height = "700px"),
                                    type = 4, color = "#2C3E50", size = 0.7
                                  ),
                                  br(), hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse", href = "#collapseCorrelationStats", 
                                                                            "Correlation Statistics",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapseCorrelationStats", class = "panel-collapse collapse",
                                                             tags$div(class = "panel-body", verbatimTextOutput("correlation_stats"))
                                                    )
                                           )
                                  ),
                                  br(),
                                  textOutput("corr_obs_count")
                              )
                            )
                        )
               ),
               
               # ----------------------------------------------------------------
               # Missing Values Heatmap Sub-Tab
               # ----------------------------------------------------------------
               
               tabPanel("Missing Values Heatmap",
                        div(id = "heatmap_wrapper", class = "sidebar-wrapper",
                            fluidRow(
                              # Sidebar
                              div(id = "heatmap_sidebar_panel", class = "col-sm-3 sidebar-panel",
                                  h4("Missingness Thresholds:"),
                                  sliderInput("col_missing_threshold", "Max Column Missing %:", 
                                              min = 0, max = 100, value = 100, step = 5, post = "%"),
                                  sliderInput("row_missing_threshold", "Max Row Missing %:", 
                                              min = 0, max = 100, value = 100, step = 5, post = "%"),
                                  hr(),
                                  h4("Variable Selection:"),
                                  selectizeInput("heatmap_cat_vars", "Select Categorical Variables:", 
                                              choices = NULL, selected = NULL, multiple = TRUE,
                                              options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                                  selectizeInput("heatmap_numeric_vars", "Select Numeric Variables:", 
                                              choices = NULL, selected = NULL, multiple = TRUE,
                                              options = list(`actions-box` = TRUE, `live-search` = TRUE)),
                                  hr(),
                                  radioButtons("heatmap_order", "Order Variables:",
                                               choices = c("Original" = "original", "Most Missing First" = "desc"),
                                               selected = "original"),
                                  br(),
                                  actionButton("reset_heatmap", "Reset to Defaults", 
                                               class = "btn-warning btn-sm", style = "width: 100%;")
                              ),
                              
                              # Main Panel
                              div(id = "heatmap_main_panel", class = "col-sm-9 main-panel",
                                  div(class = "toggle-container",
                                      actionButton("toggle_heatmap_sidebar",
                                                   label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                                                   class = "btn-primary btn-sm",
                                                   style = "background-color: #2C3E50; border-color: #2C3E50;")
                                  ),
                                  shinycssloaders::withSpinner(
                                    plotlyOutput("heatmap_plot", height = "700px"),
                                    type = 4, color = "#2C3E50", size = 0.7
                                  ),
                                  br(), hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse", href = "#collapseHeatmapSummary", 
                                                                            "Missingness Summary",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapseHeatmapSummary", class = "panel-collapse collapse",
                                                             tags$div(class = "panel-body", verbatimTextOutput("heatmap_summary"))
                                                    )
                                           )
                                  )
                              )
                            )
                        )
               ),
               
               # ----------------------------------------------------------------
               # Distribution Plots Sub-Tab
               # ----------------------------------------------------------------
               
               tabPanel("Distribution Plots",
                        div(id = "distribution_wrapper", class = "sidebar-wrapper",
                            fluidRow(
                              # Sidebar
                              div(id = "distribution_sidebar_panel", class = "col-sm-3 sidebar-panel",
                                  h4("Plot Settings:"),
                                  sliderInput("dist_bins", "Number of Bins (numeric only):",
                                              min = 5, max = 50, value = 30),
                                  hr(),
                                  h4("Variable Selection:"),
                                  selectInput("dist_var", "Select Variable:",
                                              choices = NULL, selected = NULL),
                                  hr(),
                                  h4("Missing Value Handling:"),
                                  p("Missing values are automatically excluded from the plot.",
                                    style = "font-size: 11px; color: #666; margin-top: 8px;"),
                                  br(),
                                  actionButton("reset_distribution", "Reset to Defaults",
                                               class = "btn-warning btn-sm", style = "width: 100%;")
                              ),
                              
                              # Main Panel
                              div(id = "distribution_main_panel", class = "col-sm-9 main-panel",
                                  div(class = "toggle-container",
                                      actionButton("toggle_distribution_sidebar",
                                                   label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                                                   class = "btn-primary btn-sm",
                                                   style = "background-color: #2C3E50; border-color: #2C3E50;")
                                  ),
                                  shinycssloaders::withSpinner(
                                    plotlyOutput("distribution_plot", height = "500px"),
                                    type = 4, color = "#2C3E50", size = 0.7
                                  ),
                                  br(), hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse",
                                                                            href = "#collapseDistStats",
                                                                            "Distribution Statistics",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapseDistStats",
                                                             class = "panel-collapse collapse",
                                                             tags$div(class = "panel-body",
                                                                      verbatimTextOutput("distribution_stats")
                                                             )
                                                    )
                                           )
                                  )
                              )
                            )
                        )
               ),
               
               # ----------------------------------------------------------------
               # Scatter Plot Sub-Tab
               # ----------------------------------------------------------------
               
               tabPanel("Scatter Plot",
                        div(id = "scatter_wrapper", class = "sidebar-wrapper",
                            fluidRow(
                              # Sidebar
                              div(id = "scatter_sidebar_panel", class = "col-sm-3 sidebar-panel",
                                  h4("Variable Selection:"),
                                  selectInput("scatter_x", "X-Axis Variable:",
                                              choices = NULL, selected = NULL),
                                  selectInput("scatter_y", "Y-Axis Variable:",
                                              choices = NULL, selected = NULL),
                                  selectInput("scatter_color", "Color By (categorical):",
                                              choices = c("None"), selected = "None"),
                                  hr(),
                                  
                                  br(),
                                  actionButton("reset_scatter", "Reset to Defaults",
                                               class = "btn-warning btn-sm", style = "width: 100%;")
                              ),
                              
                              # Main Panel
                              div(id = "scatter_main_panel", class = "col-sm-9 main-panel",
                                  div(class = "toggle-container",
                                      actionButton("toggle_scatter_sidebar",
                                                   label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                                                   class = "btn-primary btn-sm",
                                                   style = "background-color: #2C3E50; border-color: #2C3E50;")
                                  ),
                                  shinycssloaders::withSpinner(
                                    plotlyOutput("scatter_plot", height = "500px"),
                                    type = 4, color = "#2C3E50", size = 0.7
                                  ),
                                  br(), hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse",
                                                                            href = "#collapseScatterStats",
                                                                            "Scatter Plot Summary",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapseScatterStats",
                                                             class = "panel-collapse collapse",
                                                             tags$div(class = "panel-body",
                                                                      verbatimTextOutput("scatter_stats")
                                                             )
                                                    )
                                           )
                                  )
                              )
                            )
                        )
               ),
               
               # ----------------------------------------------------------------
               # GGpairs Plot Sub-Tab
               # ----------------------------------------------------------------
               
               tabPanel("GGpairs Plot",
                        div(id = "ggpairs_wrapper", class = "sidebar-wrapper",
                            fluidRow(
                              # Sidebar
                              div(id = "ggpairs_sidebar_panel", class = "col-sm-3 sidebar-panel",
                                  h4("Variable Selection:"),
                                  p("Select 2–12 numeric variables. Plots slow down beyond ~8.",
                                    style = "font-size: 11px; color: #888;"),
                                  selectizeInput("ggpairs_numeric",
                                                 "Numeric Variables:",
                                                 choices = NULL,
                                                 selected = NULL,
                                                 multiple = TRUE,
                                                 options = list(placeholder = 'Select 2-12 numeric variables...',
                                                                maxItems = 12)),
                                  hr(),
                                  h4("Colour By (optional):"),
                                  selectInput("ggpairs_color", "Colour By (categorical):",
                                              choices = c("None"), selected = "None"),
                                  hr(),
                                  div(class = "alert alert-info",
                                      style = "padding: 8px; font-size: 11px;",
                                      HTML("<strong>Panel layout:</strong><br>
                            Diagonal: Density plots<br>
                            Lower: Scatter plots (hover for Patient ID)<br>
                            Upper: Correlation values")
                                  ),
                                  br(),
                                  actionButton("reset_ggpairs", "Reset to Defaults",
                                               class = "btn-warning btn-sm", style = "width: 100%;")
                              ),
                              
                              # Main Panel
                              div(id = "ggpairs_main_panel", class = "col-sm-9 main-panel",
                                  div(class = "toggle-container",
                                      actionButton("toggle_ggpairs_sidebar",
                                                   label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                                                   class = "btn-primary btn-sm",
                                                   style = "background-color: #2C3E50; border-color: #2C3E50;")
                                  ),
                                  shinycssloaders::withSpinner(
                                    plotlyOutput("ggpairs_plot", height = "800px"),
                                    type = 4, color = "#2C3E50", size = 0.7
                                  ),
                                  br(), hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse",
                                                                            href = "#collapseGGpairsSummary",
                                                                            "GGpairs Summary",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapseGGpairsSummary",
                                                             class = "panel-collapse collapse",
                                                             tags$div(class = "panel-body",
                                                                      verbatimTextOutput("ggpairs_summary")
                                                             )
                                                    )
                                           )
                                  )
                              )
                            )
                        )
               ),
               
               # ----------------------------------------------------------------
               # Raw Data Sub-Tab
               # ----------------------------------------------------------------
               
               tabPanel("Raw Data",
                        div(id = "datatable_wrapper", class = "sidebar-wrapper",
                            fluidRow(
                              # Sidebar
                              div(id = "datatable_sidebar_panel", class = "col-sm-3 sidebar-panel",
                                  h4("Data Table Options"),
                                  sliderInput("dt_row_range", "Select Row Range:",
                                              min = 1, max = 10, value = c(1, 10), step = 1),
                                  hr(),
                                  h4("Column Selection"),
                                  tabsetPanel(id = "dt_column_tabs", type = "tabs",
                                              tabPanel("All Columns",
                                                       br(),
                                                       div(style = "margin-bottom: 10px;",
                                                           actionButton("dt_all_select_all", "Select All Columns", 
                                                                        class = "btn-primary btn-sm", style = "margin-right: 10px;"),
                                                           actionButton("dt_all_deselect_all", "Deselect All Columns", 
                                                                        class = "btn-danger btn-sm")
                                                       ),
                                                       selectizeInput("dt_all_columns", "Choose columns to display:",
                                                                   choices = NULL, multiple = TRUE,
                                                                   options = list(`actions-box` = TRUE, `live-search` = TRUE,
                                                                                  `selected-text-format` = "count > 5",
                                                                                  `count-selected-text` = "{0} columns selected"))
                                              ),
                                              tabPanel("Numeric Columns",
                                                       br(),
                                                       div(style = "margin-bottom: 10px;",
                                                           actionButton("dt_num_select_all", "Select All Numeric", 
                                                                        class = "btn-primary btn-sm", style = "margin-right: 10px;"),
                                                           actionButton("dt_num_deselect_all", "Deselect All Numeric", 
                                                                        class = "btn-danger btn-sm")
                                                       ),
                                                       selectizeInput("dt_numeric_columns", "Choose numeric columns to display:",
                                                                   choices = NULL, multiple = TRUE,
                                                                   options = list(`actions-box` = TRUE, `live-search` = TRUE,
                                                                                  `selected-text-format` = "count > 5",
                                                                                  `count-selected-text` = "{0} columns selected"))
                                              ),
                                              tabPanel("Categorical Columns",
                                                       br(),
                                                       div(style = "margin-bottom: 10px;",
                                                           actionButton("dt_cat_select_all", "Select All Categorical", 
                                                                        class = "btn-primary btn-sm", style = "margin-right: 10px;"),
                                                           actionButton("dt_cat_deselect_all", "Deselect All Categorical", 
                                                                        class = "btn-danger btn-sm")
                                                       ),
                                                       selectizeInput("dt_categorical_columns", "Choose categorical columns to display:",
                                                                   choices = NULL, multiple = TRUE,
                                                                   options = list(`actions-box` = TRUE, `live-search` = TRUE,
                                                                                  `selected-text-format` = "count > 5",
                                                                                  `count-selected-text` = "{0} columns selected"))
                                              )
                                  ),
                                  hr(),
                                  h4("Display Options"),
                                  selectInput("dt_page_length", "Rows per page:",
                                              choices = c("10" = 10, "25" = 25, "50" = 50, "100" = 100, "All" = -1),
                                              selected = 25),
                                  br(),
                                  p("Use the filters below each column to subset the data."),
                                  p("Export buttons available for copying, CSV, Excel, PDF, and printing."),
                                  br(),
                                  actionButton("reset_datatable", "Reset to Defaults", 
                                               class = "btn-warning btn-sm", style = "width: 100%;")
                              ),
                              
                              # Main Panel
                              div(id = "datatable_main_panel", class = "col-sm-9 main-panel",
                                  div(class = "toggle-container",
                                      actionButton("toggle_datatable_sidebar", 
                                                   label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                                                   class = "btn-primary btn-sm",
                                                   style = "background-color: #2C3E50; border-color: #2C3E50;")
                                  ),
                                  div(style = "margin-bottom: 10px; padding: 8px; background-color: #f8f9fa; border-radius: 4px;",
                                      textOutput("dt_row_info")),
                                  shinycssloaders::withSpinner(
                                    DT::DTOutput("raw_data_table"),
                                    type = 4, color = "#2C3E50", size = 0.7
                                  )
                              )
                            )
                        )
               )
             )
    ),
    
    
    
    
    
    # ====================================================================
    # ====================================================================
    # SECTION 3: DATA SPLITTING MAIN TAB
    # ====================================================================
    # ====================================================================
    
    tabPanel("Split",
             fluidPage(
               sliderInput(inputId = "Split", label = "Train proportion", min = 0, max = 1, value = 0.8),
               verbatimTextOutput(outputId = "SplitSummary")
             )
    ),
    
    
    
    
    
    # ====================================================================
    # ====================================================================
    # SECTION 4: AVAILABLE METHODS MAIN TAB
    # ====================================================================
    # ====================================================================
    
    tabPanel("Available methods",
             fluidPage(
               h3("Regression methods in caret"),
               shinycssloaders::withSpinner(DT::dataTableOutput(outputId = "Available"))
             )
    ),
    
    
    
    
    
    # ====================================================================
    # ====================================================================
    # SECTION 5: MODELLING METHODS MAIN TAB
    # ====================================================================
    # ====================================================================
    
    tabPanel("Methods",
             fluidPage(
               checkboxInput(inputId = "Parallel", label = "Use parallel processing", value = TRUE),
               bsTooltip(id = "Parallel", title = paste("This will utilise all", detectCores(), "available CPUs during training")),
               p("The preprocessing steps and their order are important.", style = "margin-top: 10px;"),
               HTML("See function <code>dynamicSteps</code> in global.R for interpretation of preprocessing options. "),
               tags$a("Documentation", href = "https://www.rdocumentation.org/packages/recipes/versions/0.1.16", target = "_blank"),
               hr(),
               
               # Family Tabs
               tabsetPanel(id = "model_family_tabs", type = "pills", selected = "Model Optimisation",
                           
                           # ============================================================
                           # FAMILY 0: NULL Model (Model 00)
                           # ============================================================
                           
                           tabPanel("Null Model",
                                    br(),
                                    fluidRow(
                                      column(width = 4),
                                      column(width = 1, actionButton(inputId = "null_Go", label = "Train", icon = icon("play"))),
                                      column(width = 1, actionButton(inputId = "null_Load", label = "Load", icon = icon("file-arrow-up"))),
                                      column(width = 1, actionButton(inputId = "null_Delete", label = "Forget", icon = icon("trash-can")))
                                    ),
                                    hr(),
                                    h3("Resampled performance:"), tableOutput(outputId = "null_Metrics"),
                                    hr(),
                                    h3("Recipe:"), htmlOutput(outputId = "null_RecipePrint"),
                                    h3("Outputs"), tableOutput(outputId = "null_RecipeOutput"),
                                    fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "null_TrainSummary")))
                           ),
                           
                           # ============================================================
                           # FAMILY 1: Linear Models (Models 01-03)
                           # ============================================================
                          
                            tabPanel("Linear Models",
                                    br(),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 01: lm
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("lm - Linear Regression",           # was "lm"
                                                         br(),
                                                         verbatimTextOutput(outputId = "lm_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "lm_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "lm_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "lm_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "lm_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "lm_Metrics"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "lm_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "lm_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "lm_TrainSummary")),
                                                           column(width = 6, h3("Coefficients"), wellPanel(tableOutput(outputId = "lm_Coef")))
                                                         )
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 02: glmnet
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("glmnet - Elastic Net",             # was "glmnet"  
                                                         verbatimTextOutput(outputId = "glmnet_MethodSummary"), br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "glmnet_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "glmnet_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "glmnet_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "glmnet_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "glmnet_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "glmnet_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "glmnet_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "glmnet_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "glmnet_TrainSummary")),
                                                           column(width = 6, h3("Coefficients"), wellPanel(tableOutput(outputId = "glmnet_Coef")))
                                                         )
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 03: rlm
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("rlm - Robust Linear Model",        # was "rlm"
                                                         br(),
                                                         verbatimTextOutput(outputId = "rlm_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "rlm_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "rlm_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "rlm_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "rlm_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "rlm_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "rlm_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "rlm_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "rlm_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "rlm_TrainSummary")),
                                                           column(width = 6, h3("Coefficients"), wellPanel(tableOutput(outputId = "rlm_Coef")))
                                                         )
                                                )
                                    )
                           ),
                           
                           # ============================================================
                           # FAMILY 2: PLS Models (Models 04-05)
                           # ============================================================
                           
                           tabPanel("PLS Models",
                                    br(),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 04: pls
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("pls - Partial Least Squares",      # was "pls"
                                                         verbatimTextOutput(outputId = "pls_MethodSummary"), br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "pls_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "pls_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "pls_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "pls_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "pls_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "pls_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "pls_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "pls_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "pls_TrainSummary")),
                                                           column(width = 6, h3("Coefficients"), wellPanel(tableOutput(outputId = "pls_Coef")))
                                                         )
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 05: pcr
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("pcr - Principal Component Reg",    # was "pcr"
                                                         verbatimTextOutput(outputId = "pcr_MethodSummary"), br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "pcr_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "pcr_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "pcr_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "pcr_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "pcr_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "pcr_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "pcr_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "pcr_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "pcr_TrainSummary")),
                                                           column(width = 6, h3("Coefficients"), wellPanel(tableOutput(outputId = "pcr_Coef")))
                                                         )
                                                )
                                    )
                           ),
                           
                           # ============================================================
                           # FAMILY 3: Tree Models (Models 06-07)
                           # ============================================================
                           
                           tabPanel("Tree Models",
                                    br(),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 06: rpart
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("rpart - CART Decision Tree",       # was "rpart"
                                                         verbatimTextOutput(outputId = "rpart_MethodSummary"), br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "rpart_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "rpart_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "rpart_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "rpart_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "rpart_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "rpart_ModelTune"),
                                                         hr(),
                                                         h3("Model tree:"), plotOutput(outputId = "rpart_ModelTree"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "rpart_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "rpart_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "rpart_TrainSummary")))
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 07: cubist
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("cubist - Rule-Based Model",        # was "cubist"
                                                         br(),
                                                         verbatimTextOutput(outputId = "cubist_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "cubist_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "cubist_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "cubist_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "cubist_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "cubist_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "cubist_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "cubist_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "cubist_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "cubist_TrainSummary")))
                                                )
                                    )
                           ),
                           
                           # ============================================================
                           # FAMILY 4: Random Forest (Models 08-09)
                           # ============================================================
                           
                           tabPanel("Random Forest",
                                    br(),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 08: ranger
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("ranger - Random Forest",           # was "ranger"
                                                         br(),
                                                         verbatimTextOutput(outputId = "ranger_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "ranger_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "ranger_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "ranger_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "ranger_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "ranger_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "ranger_ModelTune"),
                                                         hr(),
                                                         h3("Variable Importance:"), plotOutput(outputId = "ranger_VarImp"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "ranger_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "ranger_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "ranger_TrainSummary")),
                                                           column(width = 6, h3("Model Info:"), verbatimTextOutput(outputId = "ranger_ModelInfo"))
                                                         )
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 09: qrf
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("qrf - Quantile Random Forest",     # was "qrf"
                                                         br(),
                                                         verbatimTextOutput(outputId = "qrf_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "qrf_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "qrf_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "qrf_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "qrf_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "qrf_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "qrf_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "qrf_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "qrf_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "qrf_TrainSummary")))
                                                )
                                    )
                           ),
                           
                           # ============================================================
                           # FAMILY 5: Gradient Boosting (Models 10-12)
                           # ============================================================
                           
                           tabPanel("Gradient Boosting",
                                    br(),
                                    p("NOTE: These methods include boosted linear models and black box boosting.",
                                      style = "color: #666; margin-bottom: 15px;"),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 10: bstTree
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("bstTree - Boosted Trees",          # was "bstTree"
                                                         verbatimTextOutput(outputId = "bstTree_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4,
                                                                  selectizeInput(inputId = "bstTree_Preprocess",
                                                                                 label = "Pre-processing",
                                                                                 choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                 multiple = TRUE,
                                                                                 selected = default_initial_recipe)
                                                           ),
                                                           column(width = 1, actionButton(inputId = "bstTree_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "bstTree_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "bstTree_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "bstTree_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "bstTree_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "bstTree_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "bstTree_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "bstTree_TrainSummary")),
                                                           column(width = 6, h3("Best Tune"), wellPanel(tableOutput(outputId = "bstTree_BestTune")))
                                                         )
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 11: glmboost
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("glmboost - Boosted Linear",        # was "glmboost"
                                                         verbatimTextOutput(outputId = "glmboost_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "glmboost_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe , ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe )),
                                                           column(width = 1, actionButton(inputId = "glmboost_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "glmboost_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "glmboost_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "glmboost_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "glmboost_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "glmboost_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "glmboost_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "glmboost_TrainSummary")),
                                                           column(width = 6, h3("Coefficients"), wellPanel(tableOutput(outputId = "glmboost_Coef")))
                                                         )
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 12: blackboost
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("blackboost - Black Box Boost",     # was "blackboost"
                                                         verbatimTextOutput(outputId = "blackboost_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4,
                                                                  selectizeInput(inputId = "blackboost_Preprocess",
                                                                                 label = "Pre-processing",
                                                                                 choices = unique(c(default_initial_recipe , ppchoices)),
                                                                                 multiple = TRUE,
                                                                                 selected = default_initial_recipe)
                                                           ),
                                                           column(width = 1, actionButton(inputId = "blackboost_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "blackboost_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "blackboost_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "blackboost_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "blackboost_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "blackboost_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "blackboost_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "blackboost_TrainSummary")),
                                                           column(width = 6, h3("Variable Importance"), wellPanel(plotOutput(outputId = "blackboost_VarImp")))
                                                         )
                                                )
                                    )
                           ),
                           
                           # ============================================================
                           # FAMILY 6: SVM Models (Models 13-15)
                           # ============================================================
                           
                           tabPanel("SVM",
                                    br(),
                                    p("NOTE: Scaling is critical for SVM performance.", style = "color: #d9534f;"),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 13: svmRadial
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("svmRadial - SVM (RBF Kernel)",     # was "svmRadial"
                                                         br(),
                                                         verbatimTextOutput(outputId = "svmRadial_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "svmRadial_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "svmRadial_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "svmRadial_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "svmRadial_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "svmRadial_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "svmRadial_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "svmRadial_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "svmRadial_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "svmRadial_TrainSummary")))
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 14: svmPoly
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("svmPoly - SVM (Polynomial)",       # was "svmPoly"
                                                         br(),
                                                         verbatimTextOutput(outputId = "svmPoly_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "svmPoly_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "svmPoly_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "svmPoly_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "svmPoly_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "svmPoly_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "svmPoly_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "svmPoly_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "svmPoly_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "svmPoly_TrainSummary")))
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 15: svmLinear
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("svmLinear - SVM (Linear)",         # was "svmLinear"
                                                         verbatimTextOutput(outputId = "svmLinear_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4,
                                                                  selectizeInput(inputId = "svmLinear_Preprocess",
                                                                                 label = "Pre-processing",
                                                                                 choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                 multiple = TRUE,
                                                                                 selected = default_initial_recipe)
                                                           ),
                                                           column(width = 1, actionButton(inputId = "svmLinear_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "svmLinear_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "svmLinear_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "svmLinear_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "svmLinear_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "svmLinear_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "svmLinear_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "svmLinear_TrainSummary")),
                                                           column(width = 6, h3("Best Tune"), wellPanel(tableOutput(outputId = "svmLinear_BestTune")))
                                                         )
                                                )
                                    )
                           ),
                           
                           # ============================================================
                           # FAMILY 7: Neural Networks (Models 16-19)
                           # ============================================================
                           
                           tabPanel("Neural Networks",
                                    br(),
                                    p("NOTE: Scaling is critical for neural network convergence.", style = "color: #d9534f;"),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 16: avNNet
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("avNNet - Averaged Neural Net",     # was "avNNet"
                                                         br(),
                                                         verbatimTextOutput(outputId = "avNNet_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "avNNet_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "avNNet_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "avNNet_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "avNNet_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "avNNet_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "avNNet_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "avNNet_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "avNNet_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "avNNet_TrainSummary")))
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 17: mlpWeightDecayML
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("mlpWeightDecayML - Multi-Layer Perceptron",  # was "mlpWeightDecayML"
                                                         br(),
                                                         verbatimTextOutput(outputId = "mlpWeightDecayML_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "mlpWeightDecayML_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "mlpWeightDecayML_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "mlpWeightDecayML_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "mlpWeightDecayML_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "mlpWeightDecayML_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "mlpWeightDecayML_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "mlpWeightDecayML_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "mlpWeightDecayML_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "mlpWeightDecayML_TrainSummary")))
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 18: brnn
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("brnn - Bayesian Neural Net",       # was "brnn"
                                                         br(),
                                                         verbatimTextOutput(outputId = "brnn_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "brnn_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "brnn_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "brnn_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "brnn_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "brnn_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "brnn_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "brnn_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "brnn_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "brnn_TrainSummary")))
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 19: neuralnet
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("neuralnet - Backpropagation NN",   # was "neuralnet"
                                                         verbatimTextOutput(outputId = "neuralnet_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4,
                                                                  selectizeInput(inputId = "neuralnet_Preprocess",
                                                                                 label = "Pre-processing",
                                                                                 choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                 multiple = TRUE,
                                                                                 selected = default_initial_recipe)
                                                           ),
                                                           column(width = 1, actionButton(inputId = "neuralnet_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "neuralnet_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "neuralnet_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "neuralnet_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "neuralnet_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "neuralnet_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "neuralnet_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "neuralnet_TrainSummary")),
                                                           column(width = 6, h3("Best Tune"), wellPanel(tableOutput(outputId = "neuralnet_BestTune")))
                                                         )
                                                )
                                    )
                           ),
                           
                           # ============================================================
                           # FAMILY 8: Gaussian Processes (Models 20-21)
                           # ============================================================
                           
                           tabPanel("Gaussian Processes",
                                    br(),
                                    p("NOTE: Scaling is critical for kernel methods.", style = "color: #d9534f;"),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 20: gaussprRadial
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("gaussprRadial - GP (RBF Kernel)",  # was "gaussprRadial"
                                                         br(),
                                                         verbatimTextOutput(outputId = "gaussprRadial_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "gaussprRadial_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "gaussprRadial_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "gaussprRadial_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "gaussprRadial_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "gaussprRadial_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "gaussprRadial_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "gaussprRadial_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "gaussprRadial_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "gaussprRadial_TrainSummary")))
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 21: gaussprPoly
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("gaussprPoly - GP (Polynomial)",    # was "gaussprPoly"
                                                         br(),
                                                         verbatimTextOutput(outputId = "gaussprPoly_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "gaussprPoly_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "gaussprPoly_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "gaussprPoly_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "gaussprPoly_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "gaussprPoly_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "gaussprPoly_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "gaussprPoly_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "gaussprPoly_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "gaussprPoly_TrainSummary")))
                                                )
                                    )
                           ),
                           
                           # ============================================================
                           # FAMILY 9: GAM / MARS Models (Models 22-24)
                           # ============================================================
                           
                           tabPanel("GAM / MARS",
                                    br(),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 22: earth
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("earth - MARS (Splines)",           # was "earth"
                                                         br(),
                                                         verbatimTextOutput(outputId = "earth_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "earth_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "earth_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "earth_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "earth_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "earth_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "earth_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "earth_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "earth_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "earth_TrainSummary")))
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 23: gam
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("gam - Generalized Additive",       # was "gam"
                                                         br(),
                                                         verbatimTextOutput(outputId = "gam_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "gam_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "gam_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "gam_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "gam_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "gam_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "gam_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "gam_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "gam_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "gam_TrainSummary")))
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model 24: ppr
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("ppr - Projection Pursuit",         # was "PPR"
                                                         verbatimTextOutput(outputId = "ppr_MethodSummary"), 
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "ppr_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "ppr_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "ppr_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "ppr_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "ppr_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "ppr_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "ppr_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "ppr_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "ppr_TrainSummary")),
                                                           column(width = 6, h3("Coefficients / Terms"), wellPanel(tableOutput(outputId = "ppr_Coef")))
                                                         )
                                                )
                                    )
                           ), 
                           
                           # ============================================================
                           # FAMILY 10: Bayesian / Sparse Models (Models 25-26)
                           # ============================================================
                           
                           tabPanel("Bayesian",
                                    br(),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 25: spikeslab
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("spikeslab - Spike & Slab",         # was "spikeslab"
                                                         br(),
                                                         verbatimTextOutput(outputId = "spikeslab_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "spikeslab_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "spikeslab_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "spikeslab_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "spikeslab_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "spikeslab_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "spikeslab_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "spikeslab_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "spikeslab_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "spikeslab_TrainSummary")))
                                                ),
                                                
                                                
                                                
                                                # ------------------------------------------------------------
                                                # Model 26: rvmRadial
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("rvmRadial - Relevance Vector",     # was "rvmRadial"
                                                         br(),
                                                         verbatimTextOutput(outputId = "rvmRadial_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "rvmRadial_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "rvmRadial_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "rvmRadial_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "rvmRadial_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "rvmRadial_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "rvmRadial_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "rvmRadial_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "rvmRadial_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "rvmRadial_TrainSummary")))
                                                )
                                    )
                           ),
                                    
                           
                           # ============================================================
                           # FAMILY 11: KNN (Model 27)
                           # ============================================================
                           
                           tabPanel("KNN",
                                    br(),
                                    p("NOTE: Scaling is critical for distance-based methods.", style = "color: #d9534f;"),
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model 27: kknn
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("kknn - Weighted KNN", 
                                                         br(),
                                                         verbatimTextOutput(outputId = "kknn_MethodSummary"), 
                                                         br(),
                                                         
                                                         fluidRow(
                                                           column(width = 4, selectizeInput(inputId = "kknn_Preprocess", label = "Pre-processing",
                                                                                            choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                            multiple = TRUE, selected = default_initial_recipe)),
                                                           column(width = 1, actionButton(inputId = "kknn_Go", label = "Train", icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "kknn_Load", label = "Load", icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "kknn_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"), tableOutput(outputId = "kknn_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"), plotOutput(outputId = "kknn_ModelTune"),
                                                         hr(),
                                                         h3("Recipe:"), htmlOutput(outputId = "kknn_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "kknn_RecipeOutput"),
                                                         fluidRow(column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "kknn_TrainSummary")))
                                                )
                                    )
                           ),
                           
                           # ============================================================
                           # FAMILY 12: MODEL OPTIMISATION
                           # ============================================================
                           
                           tabPanel("Model Optimisation",
                                    br(),
                                    p(strong("FOCUS:"), " Intensive tuning of your best-performing models with expanded hyperparameter grids and specialized preprocessing.",
                                      style = "color: #2C3E50; background-color: #e8f4f8; padding: 10px; border-radius: 5px;"),
                                    p("These models have shown the best performance. This panel allows deeper exploration of hyperparameters and preprocessing combinations.",
                                      style = "color: #666; margin-bottom: 15px;"),
                                    tags$div(class = "alert alert-info", style = "padding: 8px; margin-bottom: 15px;",
                                             icon("info-circle"),
                                             strong("Note:"),
                                             " Training optimised models takes longer due to expanded hyperparameter grids. Use 'Load' to restore previously saved models."
                                    ),
                                    
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # Model O1: brnn (Optimised)
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("brnn (Optimised)",
                                                         br(),
                                                         verbatimTextOutput(outputId = "brnn_optim_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4,
                                                                  selectizeInput(inputId = "brnn_optim_Preprocess",
                                                                                 label = "Pre-processing (Neural Networks):",
                                                                                 choices = unique(c(optimised_model_recipe, ppchoices)),
                                                                                 multiple = TRUE,
                                                                                 selected = optimised_model_recipe)
                                                           ),
                                                           column(width = 3,
                                                                  selectInput("brnn_optim_neurons", "Neurons range:",
                                                                              choices = c("1-5 (small)"  = "small",
                                                                                          "1-10 (medium)" = "medium",
                                                                                          "1-15 (large)"  = "large",
                                                                                          "1-20 (xlarge)" = "xlarge",
                                                                                          "Custom"        = "custom"),
                                                                              selected = "medium"),
                                                                  conditionalPanel(
                                                                    condition = "input.brnn_optim_neurons == 'custom'",
                                                                    textInput("brnn_optim_neurons_custom", "Neurons (comma-separated):",
                                                                              value = "1,2,3,4,5,6,7,8,9,10,12,14,16,18,20")
                                                                  )
                                                           ),
                                                           column(width = 1, actionButton(inputId = "brnn_optim_Go",     label = "Train",  icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "brnn_optim_Load",   label = "Load",   icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "brnn_optim_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled Performance:"),    tableOutput(outputId = "brnn_optim_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning Results:"), plotOutput(outputId = "brnn_optim_ModelTune", height = "400px"),
                                                         hr(),
                                                         h3("Recipe:"),  htmlOutput(outputId = "brnn_optim_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "brnn_optim_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "brnn_optim_TrainSummary")),
                                                           column(width = 6, h3("Best Tune:"),        verbatimTextOutput(outputId = "brnn_optim_BestTune"))
                                                         )
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model O2: gaussprPoly (Optimised)
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("gaussprPoly (Optimised)",
                                                         br(),
                                                         verbatimTextOutput(outputId = "gaussprPoly_optim_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4,
                                                                  selectizeInput(inputId = "gaussprPoly_optim_Preprocess",
                                                                                 label = "Pre-processing (Kernel methods):",
                                                                                 choices = unique(c(optimised_model_recipe, ppchoices)),
                                                                                 multiple = TRUE,
                                                                                 selected = optimised_model_recipe)
                                                           ),
                                                           column(width = 2,
                                                                  selectInput("gaussprPoly_optim_degree", "Degree range:",
                                                                              choices = c("1-3 (small)"  = "small",
                                                                                          "1-5 (medium)" = "medium",
                                                                                          "1-7 (large)"  = "large",
                                                                                          "Custom"       = "custom"),
                                                                              selected = "medium")
                                                           ),
                                                           column(width = 2,
                                                                  selectInput("gaussprPoly_optim_scale", "Scale range:",
                                                                              choices = c("0.01-0.1 (small)"  = "small",
                                                                                          "0.01-1 (medium)"   = "medium",
                                                                                          "0.01-10 (large)"   = "large",
                                                                                          "Custom"            = "custom"),
                                                                              selected = "medium"),
                                                                  conditionalPanel(
                                                                    condition = "input.gaussprPoly_optim_degree == 'custom' || input.gaussprPoly_optim_scale == 'custom'",
                                                                    textInput("gaussprPoly_optim_custom", "Custom (degree | scale):",
                                                                              value = "degree: 1,2,3,4,5 | scale: 0.01,0.05,0.1,0.5,1,2,5")
                                                                  )
                                                           ),
                                                           column(width = 1, actionButton(inputId = "gaussprPoly_optim_Go",     label = "Train",  icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "gaussprPoly_optim_Load",   label = "Load",   icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "gaussprPoly_optim_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled Performance:"),    tableOutput(outputId = "gaussprPoly_optim_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning Results:"), plotOutput(outputId = "gaussprPoly_optim_ModelTune", height = "400px"),
                                                         hr(),
                                                         h3("Recipe:"),  htmlOutput(outputId = "gaussprPoly_optim_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "gaussprPoly_optim_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "gaussprPoly_optim_TrainSummary")),
                                                           column(width = 6, h3("Best Tune:"),        verbatimTextOutput(outputId = "gaussprPoly_optim_BestTune"))
                                                         )
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model O3: svmPoly (Optimised)
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("svmPoly (Optimised)",
                                                         br(),
                                                         verbatimTextOutput(outputId = "svmPoly_optim_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4,
                                                                  selectizeInput(inputId = "svmPoly_optim_Preprocess",
                                                                                 label = "Pre-processing (SVM):",
                                                                                 choices = unique(c(optimised_model_recipe, ppchoices)),
                                                                                 multiple = TRUE,
                                                                                 selected = optimised_model_recipe)
                                                           ),
                                                           column(width = 1,
                                                                  selectInput("svmPoly_optim_degree", "Degree:",
                                                                              choices = c("1-3" = "small", "1-4" = "medium", "1-5" = "large", "Custom" = "custom"),
                                                                              selected = "medium")
                                                           ),
                                                           column(width = 1,
                                                                  selectInput("svmPoly_optim_scale", "Scale:",
                                                                              choices = c("0.001-0.1" = "small", "0.001-1" = "medium", "0.001-10" = "large", "Custom" = "custom"),
                                                                              selected = "medium")
                                                           ),
                                                           column(width = 1,
                                                                  selectInput("svmPoly_optim_C", "Cost (C):",
                                                                              choices = c("0.1-5" = "small", "0.1-20" = "medium", "0.1-100" = "large", "Custom" = "custom"),
                                                                              selected = "medium"),
                                                                  conditionalPanel(
                                                                    condition = "input.svmPoly_optim_degree == 'custom' || input.svmPoly_optim_scale == 'custom' || input.svmPoly_optim_C == 'custom'",
                                                                    textInput("svmPoly_optim_custom", "Custom (degree | scale | C):",
                                                                              value = "degree: 1,2,3,4 | scale: 0.001,0.01,0.1,1,10 | C: 0.1,0.5,1,2,5,10,20")
                                                                  )
                                                           ),
                                                           column(width = 1, actionButton(inputId = "svmPoly_optim_Go",     label = "Train",  icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "svmPoly_optim_Load",   label = "Load",   icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "svmPoly_optim_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled Performance:"),    tableOutput(outputId = "svmPoly_optim_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning Results:"), plotOutput(outputId = "svmPoly_optim_ModelTune", height = "400px"),
                                                         hr(),
                                                         h3("Recipe:"),  htmlOutput(outputId = "svmPoly_optim_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "svmPoly_optim_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "svmPoly_optim_TrainSummary")),
                                                           column(width = 6, h3("Best Tune:"),        verbatimTextOutput(outputId = "svmPoly_optim_BestTune"))
                                                         )
                                                ),
                                                
                                                # ------------------------------------------------------------
                                                # Model O4: svmRadial (Optimised)
                                                # ------------------------------------------------------------
                                                
                                                tabPanel("svmRadial (Optimised)",
                                                         br(),
                                                         verbatimTextOutput(outputId = "svmRadial_optim_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4,
                                                                  selectizeInput(inputId = "svmRadial_optim_Preprocess",
                                                                                 label = "Pre-processing (RBF SVM):",
                                                                                 choices = unique(c(optimised_model_recipe, ppchoices)),
                                                                                 multiple = TRUE,
                                                                                 selected = optimised_model_recipe)
                                                           ),
                                                           column(width = 2,
                                                                  selectInput("svmRadial_optim_sigma", "Sigma (RBF width):",
                                                                              choices = c("0.001-0.1 (small)"  = "small",
                                                                                          "0.001-1 (medium)"   = "medium",
                                                                                          "0.001-10 (large)"   = "large",
                                                                                          "Custom"             = "custom"),
                                                                              selected = "medium")
                                                           ),
                                                           column(width = 2,
                                                                  selectInput("svmRadial_optim_C", "Cost (C):",
                                                                              choices = c("0.1-10 (small)"  = "small",
                                                                                          "0.1-50 (medium)" = "medium",
                                                                                          "0.1-100 (large)" = "large",
                                                                                          "Custom"          = "custom"),
                                                                              selected = "medium"),
                                                                  conditionalPanel(
                                                                    condition = "input.svmRadial_optim_sigma == 'custom' || input.svmRadial_optim_C == 'custom'",
                                                                    textInput("svmRadial_optim_custom", "Custom (sigma | C):",
                                                                              value = "sigma: 0.001,0.005,0.01,0.05,0.1,0.5,1,2,5 | C: 0.1,0.5,1,2,5,10,25,50,100")
                                                                  )
                                                           ),
                                                           column(width = 1, actionButton(inputId = "svmRadial_optim_Go",     label = "Train",  icon = icon("play"))),
                                                           column(width = 1, actionButton(inputId = "svmRadial_optim_Load",   label = "Load",   icon = icon("file-arrow-up"))),
                                                           column(width = 1, actionButton(inputId = "svmRadial_optim_Delete", label = "Forget", icon = icon("trash-can")))
                                                         ),
                                                         hr(),
                                                         h3("Resampled Performance:"),    tableOutput(outputId = "svmRadial_optim_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning Results:"), plotOutput(outputId = "svmRadial_optim_ModelTune", height = "400px"),
                                                         hr(),
                                                         h3("Recipe:"),  htmlOutput(outputId = "svmRadial_optim_RecipePrint"),
                                                         h3("Outputs"), tableOutput(outputId = "svmRadial_optim_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6, h3("Training Summary:"), verbatimTextOutput(outputId = "svmRadial_optim_TrainSummary")),
                                                           column(width = 6, h3("Best Tune:"),        verbatimTextOutput(outputId = "svmRadial_optim_BestTune"))
                                                         )
                                                )
                                    )
                           ),
                           
                           # ================================================================
                           # FAMILY 13: TRANSPARENT MODEL OPTIMISATION (glmnet with Interactions)
                           # ================================================================
                           
                           tabPanel("Transparent Models",
                                    br(),
                                    p("Elastic Net regression with automatic 2-way interaction terms for transparent feature selection.",
                                      style = "color: #2C3E50; margin-bottom: 15px;"),
                                    hr(),
                                    
                                    # Main model: glmnet with interactions
                                    tabsetPanel(type = "pills",
                                                
                                                # ------------------------------------------------------------
                                                # glmnet_interact - Elastic Net with 2-Way Interaction Terms
                                                # ------------------------------------------------------------
                                               
                                                tabPanel("glmnet_interact",
                                                         verbatimTextOutput(outputId = "glmnet_interact_MethodSummary"),
                                                         br(),
                                                         fluidRow(
                                                           column(width = 4,
                                                                  selectizeInput(inputId = "glmnet_interact_Preprocess",
                                                                                 label = "Pre-processing",
                                                                                 choices = unique(c(default_initial_recipe, ppchoices)),
                                                                                 multiple = TRUE,
                                                                                 selected = default_initial_recipe)
                                                           ),
                                                           column(width = 1,
                                                                  actionButton(inputId = "glmnet_interact_Go", label = "Train", icon = icon("play")),
                                                                  bsTooltip(id = "glmnet_interact_Go", title = "Train or retrain model")
                                                           ),
                                                           column(width = 1,
                                                                  actionButton(inputId = "glmnet_interact_Load", label = "Load", icon = icon("file-arrow-up")),
                                                                  bsTooltip(id = "glmnet_interact_Load", title = "Reload saved model")
                                                           ),
                                                           column(width = 1,
                                                                  actionButton(inputId = "glmnet_interact_Delete", label = "Forget", icon = icon("trash-can")),
                                                                  bsTooltip(id = "glmnet_interact_Delete", title = "Remove model from memory")
                                                           )
                                                         ),
                                                         hr(),
                                                         h4("Elastic Net Settings"),
                                                         fluidRow(
                                                           column(width = 6,
                                                                  numericInput(inputId = "glmnet_interact_alpha", 
                                                                               label = "Alpha (Elastic Net Mix)",
                                                                               value = 0.5, min = 0, max = 1, step = 0.1),
                                                                  bsTooltip(id = "glmnet_interact_alpha",
                                                                            title = "0 = Ridge (L2 penalty), 0.5 = Elastic Net, 1 = Lasso (L1 penalty)")
                                                           ),
                                                           column(width = 6,
                                                                  p("Interaction terms: 2-way interactions automatically included",
                                                                    style = "margin-top: 30px; color: #2C3E50; font-style: italic;")
                                                           )
                                                         ),
                                                         hr(),
                                                         h3("Resampled performance:"),
                                                         tableOutput(outputId = "glmnet_interact_Metrics"),
                                                         hr(),
                                                         h3("Hyperparameter Tuning:"),
                                                         plotOutput(outputId = "glmnet_interact_ModelTune"),
                                                         hr(),
                                                         h3("Selected Features & Coefficients"),
                                                         fluidRow(
                                                           column(width = 12,
                                                                  wellPanel(
                                                                    h4("Non-zero Coefficients (Selected Features)"),
                                                                    p("This shows which main effects and interaction terms were selected by Lasso."),
                                                                    tableOutput(outputId = "glmnet_interact_Coef")
                                                                  )
                                                           )
                                                         ),
                                                         hr(),
                                                         h3("Recipe:"),
                                                         htmlOutput(outputId = "glmnet_interact_RecipePrint"),
                                                         h3("Outputs"),
                                                         tableOutput(outputId = "glmnet_interact_RecipeOutput"),
                                                         fluidRow(
                                                           column(width = 6,
                                                                  h3("Training Summary:"),
                                                                  verbatimTextOutput(outputId = "glmnet_interact_TrainSummary")
                                                           ),
                                                           column(width = 6,
                                                                  h3("Model Info:"),
                                                                  verbatimTextOutput(outputId = "glmnet_interact_ModelInfo")
                                                           )
                                                         )
                                                )
                                    )
                           )
                           
                           
                           
               )  
             )    
    ),           
    
    
    
    
    
    # ====================================================================
    # ====================================================================
    # SECTION 6: MODEL SELECTION MAIN TAB
    # ====================================================================
    # ====================================================================
    
    tabPanel("Model Selection",
             fluidPage(
               tags$h5("Bootstrap Resampling Results (25 iterations):"),
               fluidRow(
                 column(4,
                        checkboxInput(inputId = "Notch", label = "Show notch", value = FALSE)
                 ),
                 column(4,
                        checkboxInput(inputId = "NullNormalise", label = "Normalise to Null", value = TRUE)
                 ),
                 column(4,
                        checkboxInput(inputId = "HideWorse", label = "Hide models worse than null", value = TRUE)
                 )
               ),
               br(),
               plotOutput(outputId = "SelectionBoxPlot", height = "600px"),
               br(),
               hr(),
               
               # Selected Model Summary Box
               wellPanel(
                 style = "background-color: #f8f9fa; border-left: 4px solid #2C3E50;",
                 fluidRow(
                   column(12,
                          h4("Selected Model Summary", style = "color: #2C3E50; margin-top: 0;"),
                          hr(style = "margin-top: 5px; margin-bottom: 15px;")
                   )
                 ),
                 fluidRow(
                   column(12,
                          radioButtons(inputId = "Choice", label = "Choose model:", 
                                       choices = c("Loading..." = ""),  # Empty initially
                                       selected = "",
                                       inline = TRUE)
                   )
                 ),
                 br(),
                 fluidRow(
                   column(4,
                          div(class = "well", style = "background-color: white; text-align: center; padding: 10px;",
                              h5("RMSE", style = "margin: 0; color: #666;"),
                              h3(textOutput("selected_model_rmse"), style = "margin: 5px 0; color: #13D4D4;"),
                              p(textOutput("selected_model_rmse_sd"), style = "font-size: 11px; color: #999; margin: 0;")
                          )
                   ),
                   column(4,
                          div(class = "well", style = "background-color: white; text-align: center; padding: 10px;",
                              h5("R²", style = "margin: 0; color: #666;"),
                              h3(textOutput("selected_model_rsquared"), style = "margin: 5px 0; color: #2ecc71;"),
                              p(textOutput("selected_model_rsquared_sd"), style = "font-size: 11px; color: #999; margin: 0;")
                          )
                   ),
                   column(4,
                          div(class = "well", style = "background-color: white; text-align: center; padding: 10px;",
                              h5("MAE", style = "margin: 0; color: #666;"),
                              h3(textOutput("selected_model_mae"), style = "margin: 5px 0; color: #f39c12;"),
                              p(textOutput("selected_model_mae_sd"), style = "font-size: 11px; color: #999; margin: 0;")
                          )
                   )
                 ),
                 br(),
                 
                 div(
                   tags$button(
                     style = "background-color: #2C3E50; color: white; width: 100%; text-align: left; padding: 10px 15px; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;",
                     onclick = "var content = this.nextElementSibling; if (content.style.display === 'none') { content.style.display = 'block'; } else { content.style.display = 'none'; }",
                     HTML('<i class="fa fa-chart-bar"></i> Boxplot Statistics (Bootstrap Distribution) <span style="float: right;">▼</span>')
                   ),
                   div(
                     style = "display: none; padding: 15px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 4px 4px;",
                     fluidRow(
                       column(4,
                              div(style = "background-color: #f8f9fa; border-radius: 5px; padding: 10px; height: 100%;",
                                  h5("RMSE Distribution", style = "color: #13D4D4; margin-top: 0; text-align: center;"),
                                  hr(style = "margin: 5px 0 10px 0;"),
                                  verbatimTextOutput("selected_model_rmse_boxplot_stats")
                              )
                       ),
                       column(4,
                              div(style = "background-color: #f8f9fa; border-radius: 5px; padding: 10px; height: 100%;",
                                  h5("R² Distribution", style = "color: #2ecc71; margin-top: 0; text-align: center;"),
                                  hr(style = "margin: 5px 0 10px 0;"),
                                  verbatimTextOutput("selected_model_rsquared_boxplot_stats")
                              )
                       ),
                       column(4,
                              div(style = "background-color: #f8f9fa; border-radius: 5px; padding: 10px; height: 100%;",
                                  h5("MAE Distribution", style = "color: #f39c12; margin-top: 0; text-align: center;"),
                                  hr(style = "margin: 5px 0 10px 0;"),
                                  verbatimTextOutput("selected_model_mae_boxplot_stats")
                              )
                       )
                     ),
                     hr(),
                     fluidRow(
                       column(12,
                              div(style = "background-color: #fff3e0; border-radius: 5px; padding: 10px;",
                                  h5("Outlier Analysis", style = "color: #e74c3c; margin-top: 0;"),
                                  uiOutput("selected_model_outlier_warning"),
                                  verbatimTextOutput("selected_model_outlier_stats")
                              )
                       )
                     )
                   )
                 )
               )
             )
    ),
    
    
    
    
    
    # ====================================================================
    # ====================================================================
    # SECTION 7: TRAINING SUMMARY TAB
    # ====================================================================
    # ====================================================================
    
    tabPanel("Training Summary",
             fluidPage(
               br(),
               h3("Resampled Performance — All Models"),
               p("All models use the same default preprocessing recipe (unless customised). Sorted by RMSE ascending.",
                 style = "color: #666; margin-bottom: 20px;"),
               shinycssloaders::withSpinner(
                 DT::dataTableOutput("training_summary_table"),
                 type = 4, color = "#2C3E50", size = 0.7
               ),
               br(), hr(),
               h3("Training Time Comparison"),
               shinycssloaders::withSpinner(
                 plotOutput("training_time_plot", height = "500px"),
                 type = 4, color = "#2C3E50", size = 0.7
               )
             )
    ),
    
    
    
    
    
    # ====================================================================
    # ====================================================================
    # SECTION 8: PERFORMANCE MAIN TAB
    # ====================================================================
    # ====================================================================
    
    tabPanel("Performance",
             tabsetPanel(
               
               # Performance Summary Tab with Model Selector
               tabPanel("Performance Summary",
                        fluidPage(
                          br(),
                          wellPanel(
                            h4("Select Model to Evaluate"),
                            hr(),
                            fluidRow(
                              column(6,
                                     selectInput("perf_model_choice", 
                                                 label = "Choose a trained model:",
                                                 choices = c("brnn_optim" = "brnn_optim"),
                                                 selected = "brnn_optim",
                                                 width = "100%")
                              ),
                              column(6,
                                     br(),
                                     p("Select a model from the dropdown above to see its performance metrics on the test set.",
                                       style = "color: #666; margin-top: 8px;")
                              )
                            )
                          ),
                          br(),
                          h3("Test Set Performance Metrics"),
                          tableOutput("perf_metrics_table"),
                          br(),
                          h3("Train vs Test Comparison"),
                          uiOutput("perf_comparison_report")
                        )
               ),
               
               # ====================================================================
               # SUB-TAB 1: Predictions vs Actual
               # ====================================================================
               
               tabPanel("Predictions vs Actual",
                        div(id = "pred_wrapper", class = "sidebar-wrapper",
                            fluidRow(
                              div(id = "pred_sidebar_panel", class = "col-sm-3 sidebar-panel",
                                  div(class = "well",
                                      h4("Display Controls"), hr(),
                                      radioButtons("pred_display_dataset", "Dataset to Display:",
                                                   choices = c("Train Only" = "train", "Test Only" = "test", "Both (Train + Test)" = "both"),
                                                   selected = "both"),
                                      hr(),
                                      p("Points show predicted vs actual values.", style = "font-size: 11px; color: #666;"),
                                      p("Dashed line represents perfect prediction (y = x).", style = "font-size: 11px; color: #666; margin-top: 5px;"),
                                      p("Hover over points to see Patient ID, Actual, and Predicted values.", style = "font-size: 11px; color: #666; margin-top: 5px;")
                                  )
                              ),
                              div(id = "pred_main_panel", class = "col-sm-9 main-panel",
                                  div(class = "toggle-container",
                                      actionButton("toggle_pred_sidebar", 
                                                   label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                                                   class = "btn-primary btn-sm",
                                                   style = "background-color: #2C3E50; border-color: #2C3E50;")
                                  ),
                                  shinycssloaders::withSpinner(plotlyOutput("pred_plot", height = "600px"), type = 4, color = "#2C3E50", size = 0.7),
                                  br(), hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse", href = "#collapsePredStats", "Prediction Statistics",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapsePredStats", class = "panel-collapse collapse",
                                                             tags$div(class = "panel-body", verbatimTextOutput("pred_stats"))
                                                    )
                                           )
                                  )
                              )
                            )
                        )
               ),
               # ====================================================================
               # SUB-TAB 2: Residual Analysis (Scatter)
               # ====================================================================
               
               tabPanel("Residual Analysis",
                        div(id = "residual_wrapper", class = "sidebar-wrapper",
                            fluidRow(
                              div(id = "residual_sidebar_panel", class = "col-sm-3 sidebar-panel",
                                  div(class = "well",
                                      h4("Display Controls"), hr(),
                                      radioButtons("residual_display_dataset", "Dataset to Display:",
                                                   choices = c("Train Only" = "train", "Test Only" = "test", "Both (Train + Test)" = "both"),
                                                   selected = "both"),
                                      hr(),
                                      sliderInput("residual_iqr_slider", "Outlier IQR Multiplier:", min = 0.1, max = 5.0, value = 1.5, step = 0.1),
                                      p(class = "help-block", "Standard IQR multiplier is 1.5. Higher values = fewer outliers detected.",
                                        style = "font-size: 11px; color: #666; margin-top: 5px;")
                                  )
                              ),
                              div(id = "residual_main_panel", class = "col-sm-9 main-panel",
                                  div(class = "toggle-container",
                                      actionButton("toggle_residual_sidebar", 
                                                   label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                                                   class = "btn-primary btn-sm",
                                                   style = "background-color: #2C3E50; border-color: #2C3E50;")
                                  ),
                                  shinycssloaders::withSpinner(plotlyOutput("residual_plot", height = "500px"), type = 4, color = "#2C3E50", size = 0.7),
                                  hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse", href = "#collapseResidualStats", "Residual Statistics",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapseResidualStats", class = "panel-collapse collapse",
                                                             tags$div(class = "panel-body", verbatimTextOutput("residual_stats"))
                                                    )
                                           )
                                  ),
                                  hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse", href = "#collapseResidualOutliers", "Residual Outliers",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapseResidualOutliers", class = "panel-collapse collapse in",
                                                             tags$div(class = "panel-body", DT::DTOutput("residual_outliers"))
                                                    )
                                           )
                                  )
                              )
                            )
                        )
               ),
               
               # ====================================================================
               # SUB-TAB 3: Residual Boxplot
               # ====================================================================
               
               tabPanel("Residual Boxplot",
                        div(id = "residual_boxplot_wrapper", class = "sidebar-wrapper",
                            fluidRow(
                              div(id = "residual_boxplot_sidebar_panel", class = "col-sm-3 sidebar-panel",
                                  div(class = "well",
                                      h4("Residual Analysis Controls"), hr(),
                                      radioButtons("residual_boxplot_dataset", "Dataset to Display:",
                                                   choices = c("Train Only" = "train", "Test Only" = "test", "Both (Train + Test)" = "both"),
                                                   selected = "both"),
                                      hr(),
                                      sliderInput("residual_boxplot_iqr_slider", "Outlier IQR Multiplier:", min = 0.1, max = 5.0, value = 1.5, step = 0.1),
                                      hr(),
                                      h5("Display Options:"),
                                      checkboxInput("residual_boxplot_show_train_box", "Show Train Boxplot", value = TRUE),
                                      checkboxInput("residual_boxplot_show_test_box", "Show Test Boxplot", value = TRUE),
                                      hr(),
                                      h5("Individual Points:"),
                                      checkboxInput("residual_boxplot_show_train_points", "Show Train Points", value = TRUE),
                                      checkboxInput("residual_boxplot_show_test_points", "Show Test Points", value = TRUE),
                                      p("Points are displayed to the right of each boxplot", style = "font-size: 11px; color: #666; margin-top: 10px;"),
                                      hr(),
                                      p("Hover over boxes to see:", style = "font-weight: bold; font-size: 11px; margin-bottom: 5px;"),
                                      p("• Min, Q1, Median, Q3, Max", style = "font-size: 11px; margin-left: 10px;"),
                                      p("• IQR and outlier bounds", style = "font-size: 11px; margin-left: 10px;"),
                                      p("• Number of observations", style = "font-size: 11px; margin-left: 10px;")
                                  )
                              ),
                              div(id = "residual_boxplot_main_panel", class = "col-sm-9 main-panel",
                                  div(class = "toggle-container",
                                      actionButton("toggle_residual_boxplot_sidebar", 
                                                   label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'),
                                                   class = "btn-primary btn-sm",
                                                   style = "background-color: #2C3E50; border-color: #2C3E50;")
                                  ),
                                  shinycssloaders::withSpinner(plotlyOutput("residual_boxplot", height = "550px"), type = 4, color = "#2C3E50", size = 0.7),
                                  br(), hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse", href = "#collapseResidualBoxplotStats", "Residual Boxplot Statistics",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapseResidualBoxplotStats", class = "panel-collapse collapse",
                                                             tags$div(class = "panel-body", verbatimTextOutput("residual_boxplot_stats"))
                                                    )
                                           )
                                  ),
                                  hr(),
                                  tags$div(class = "panel-group",
                                           tags$div(class = "panel panel-default",
                                                    tags$div(class = "panel-heading",
                                                             tags$h4(class = "panel-title",
                                                                     tags$a(`data-toggle` = "collapse", href = "#collapseResidualBoxplotOutliers", "Residual Outliers (by IQR method)",
                                                                            style = "cursor: pointer; text-decoration: none; color: #2C3E50;")
                                                             )
                                                    ),
                                                    tags$div(id = "collapseResidualBoxplotOutliers", class = "panel-collapse collapse in",
                                                             tags$div(class = "panel-body", DT::DTOutput("residual_boxplot_outliers"))
                                                    )
                                           )
                                  )
                              )
                            )
                        )
               )
             )
    )
  )  # <-- CLOSE navbarPage
)    # <-- CLOSE shinyUI
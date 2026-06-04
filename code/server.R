# ========================================================================
# SERVER.R - DATA423 ASSIGNMENT 3
# Author: Eduard Bradley
# ========================================================================

shinyServer(function(input, output, session) {
  
  # ========================================================================
  # ========================================================================
  # SECTION 1: GLOBAL SETUP & INITIALISATION
  # ========================================================================
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # 1.1 Reactive storage and directories
  # ------------------------------------------------------------------------
  
  # Reactive values for storing trained models
  models <- reactiveValues()
  training_times <- reactiveValues()   # stores elapsed seconds per model key
  training_metrics <- reactiveValues()  # stores full metrics for each model
  
  # Ensure the SavedModels folder exists
  if (!"./SavedModels" %in% list.dirs()) {
    dir.create("./SavedModels")
  }
  
  # Session end handler
  shiny::onSessionEnded(stopApp)
  
  
  # ------------------------------------------------------------------------
  # 1.2 Sidebar state initialisation
  # ------------------------------------------------------------------------
  
  sidebar_state <- reactiveValues(
    boxplot = TRUE,
    correlation = TRUE,
    heatmap = TRUE,
    distribution = TRUE,
    scatter      = TRUE,
    ggpairs      = TRUE,
    datatable = TRUE,
    pred = TRUE,
    residual = TRUE,
    residual_boxplot = TRUE
  )
  
  
  # ------------------------------------------------------------------------
  # 1.3 Generic toggle function and observers
  # ------------------------------------------------------------------------
  
  # Generic toggle function
  toggle_sidebar <- function(wrapper_id, sidebar_panel_id, main_panel_id, sidebar_state_name, session, button_id) {
    current_state <- sidebar_state[[sidebar_state_name]]
    if(current_state) {
      shinyjs::hide(id = sidebar_panel_id)
      shinyjs::removeClass(id = main_panel_id, class = "col-sm-9")
      shinyjs::addClass(id = main_panel_id, class = "col-sm-12")
      shinyjs::addClass(id = wrapper_id, class = "sidebar-hidden")
      sidebar_state[[sidebar_state_name]] <- FALSE
      updateActionButton(session, button_id, label = HTML('<i class="fa fa-sliders-h"></i> Show Filters'))
    } else {
      shinyjs::show(id = sidebar_panel_id)
      shinyjs::removeClass(id = main_panel_id, class = "col-sm-12")
      shinyjs::addClass(id = main_panel_id, class = "col-sm-9")
      shinyjs::removeClass(id = wrapper_id, class = "sidebar-hidden")
      sidebar_state[[sidebar_state_name]] <- TRUE
      updateActionButton(session, button_id, label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'))
    }
  }
  
  # Sidebar toggle observers
  observeEvent(input$toggle_boxplot_sidebar, { 
    toggle_sidebar("boxplot_wrapper", "boxplot_sidebar_panel", 
                   "boxplot_main_panel", "boxplot", session, 
                   "toggle_boxplot_sidebar") })
  
  observeEvent(input$toggle_correlation_sidebar, { 
    toggle_sidebar("correlation_wrapper", "correlation_sidebar_panel", 
                   "correlation_main_panel", "correlation", session, 
                   "toggle_correlation_sidebar") })
  
  observeEvent(input$toggle_heatmap_sidebar, { 
    toggle_sidebar("heatmap_wrapper", "heatmap_sidebar_panel", 
                   "heatmap_main_panel", "heatmap", session, 
                   "toggle_heatmap_sidebar") })
  
  observeEvent(input$toggle_datatable_sidebar, { 
    toggle_sidebar("datatable_wrapper", "datatable_sidebar_panel", 
                   "datatable_main_panel", "datatable", session, 
                   "toggle_datatable_sidebar") })
  
  observeEvent(input$toggle_pred_sidebar, { 
    toggle_sidebar("pred_wrapper", "pred_sidebar_panel", 
                   "pred_main_panel", "pred", session, 
                   "toggle_pred_sidebar") })
  
  observeEvent(input$toggle_residual_sidebar, { 
    toggle_sidebar("residual_wrapper", "residual_sidebar_panel", 
                   "residual_main_panel", "residual", 
                   session, "toggle_residual_sidebar") })
  
  observeEvent(input$toggle_residual_boxplot_sidebar, { 
    toggle_sidebar("residual_boxplot_wrapper", "residual_boxplot_sidebar_panel", 
                   "residual_boxplot_main_panel", "residual_boxplot", session, 
                   "toggle_residual_boxplot_sidebar") })
  
  observeEvent(input$toggle_distribution_sidebar, {
    toggle_sidebar("distribution_wrapper", "distribution_sidebar_panel",
                   "distribution_main_panel", "distribution", session,
                   "toggle_distribution_sidebar")})
  
  observeEvent(input$toggle_scatter_sidebar, {
    toggle_sidebar("scatter_wrapper", "scatter_sidebar_panel",
                   "scatter_main_panel", "scatter", session,
                   "toggle_scatter_sidebar")})
  
  observeEvent(input$toggle_ggpairs_sidebar, {
    toggle_sidebar("ggpairs_wrapper", "ggpairs_sidebar_panel",
                   "ggpairs_main_panel", "ggpairs", session,
                   "toggle_ggpairs_sidebar")})
  
  
  
  
  
  # ========================================================================
  # ========================================================================
  # SECTION 2: DATA LOADING & PREPROCESSING
  # ========================================================================
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # 2.1 Main data loader
  # ------------------------------------------------------------------------
  
  getData <- reactive({
    d <- read.csv(file = "Ass3Data.csv", row.names = "Patient", stringsAsFactors = TRUE)
    d$ObservationDate <- as.Date(d$ObservationDate, "%Y-%m-%d")
    d
  })
  
  # Diagnostic - Check if data loads
  observe({
    data <- getData()
    print(paste("Data loaded:", nrow(data), "rows,", ncol(data), "columns"))
    print(head(names(data), 21))
  })
  
  
  # ------------------------------------------------------------------------
  # 2.2 Data column type helpers
  # ------------------------------------------------------------------------
  
  numeric_cols <- reactive({
    data <- getData()
    names(data)[sapply(data, is.numeric)]
  })
  
  categorical_cols <- reactive({
    data <- getData()
    names(data)[sapply(data, function(x) is.factor(x) | is.character(x))]
  })
  
  date_cols <- reactive({
    data <- getData()
    names(data)[sapply(data, function(x) inherits(x, "Date"))]
  })
  
  
  # ------------------------------------------------------------------------
  # 2.3 Data splitting
  # ------------------------------------------------------------------------
  
  getSplit <- reactive({
    set.seed(199)
    createDataPartition(y = getData()$Response, p = input$Split, list = FALSE)
  })
  
  getTrainData <- reactive({ getData()[getSplit(),] })
  getTestData <- reactive({ getData()[-getSplit(),] })
  
  output$SplitSummary <- renderPrint({
    cat(paste("Training observations:", nrow(getTrainData()), "\n", "Testing observations:", nrow(getTestData())))
  })
  
  
  # ------------------------------------------------------------------------
  # 2.4 Helper functions for modelling
  # ------------------------------------------------------------------------
  
  getTrControl <- reactive({
    y <- getTrainData()[,"Response"]
    n <- 25
    set.seed(673)
    seeds <- vector(mode = "list", length = n + 1)
    for (i in 1:n) { seeds[[i]] <- as.integer(c(runif(n = 200, min = 1000, max = 5000))) }
    seeds[[n + 1]] <- as.integer(runif(n = 1, min = 1000, max = 5000))
    
    trainControl(
      method = "boot", number = n, repeats = NA, allowParallel = TRUE,
      search = "grid", index = caret::createResample(y = y, times = n),
      savePredictions = "final", seeds = seeds, trim = TRUE
    )
  })
  
  recipeOutputTable <- function(mod) {
    terms <- as.data.frame(mod$recipe$term_info)
    n <- dim(terms)[1]
    types <- vector(mode = "character", length = n)
    for (row in 1:n) types[row] <- paste(collapse = " ", unlist(terms$type[row]))
    terms$type <- types
    terms %>% dplyr::filter(role == "predictor") %>%
      dplyr::select(type, source) %>%
      dplyr::group_by(type, source) %>%
      dplyr::summarise(count = n())
  }
  
  recipePrintHTML <- function(mod) {
    html <- mod$recipe %>% print() %>% cli::cli_fmt() %>%
      cli::ansi_collapse(sep = "<br>", last = "<br>") %>%
      cli::ansi_html(escape_reserved = FALSE) %>%
      gsub(pattern = "──────", replacement = "─", x = ., fixed = TRUE)
    css <- paste(format(ansi_html_style()), collapse = "\n")
    tagList(tags$head(tags$style(css)), tags$pre(HTML(html)))
  }
  
  
  
  
  # ========================================================================
  # ========================================================================
  # SECTION 3: EXPLORATORY DATA ANALYSIS
  # ========================================================================
  # ========================================================================
  
  
  
  # ========================================================================
  # SUBSECTION 3.1: DATA SUMMARY MODULE
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # PART 3.1.1: Basic summary statistics outputs
  # ------------------------------------------------------------------------
  
  output$summary_row_count <- renderText({ format(nrow(getData()), big.mark = ",") })
  output$summary_col_count <- renderText({ ncol(getData()) })
  output$summary_total_cells <- renderText({ format(nrow(getData()) * ncol(getData()), big.mark = ",") })
  
  output$summary_non_na_values <- renderText({
    data <- getData()
    total_cells <- nrow(data) * ncol(data)
    total_missing <- sum(sapply(data, function(x) sum(is.na(x))))
    format(total_cells - total_missing, big.mark = ",")
  })
  
  # ------------------------------------------------------------------------
  # PART 3.1.2: Data quality UI outputs
  # ------------------------------------------------------------------------
  
  output$summary_complete_cases <- renderUI({
    data <- getData()
    complete_rows <- sum(complete.cases(data))
    pct <- round(100 * complete_rows / nrow(data), 1)
    div(h5(complete_rows, style = "margin: 2px; font-weight: bold;"),
        p(paste("Complete Rows (", pct, "%)", sep = ""), style = "font-size: 11px; margin: 0;"))
  })
  
  output$summary_incomplete_cases <- renderUI({
    data <- getData()
    complete_rows <- sum(complete.cases(data))
    incomplete_rows <- nrow(data) - complete_rows
    pct <- round(100 * incomplete_rows / nrow(data), 1)
    div(h5(incomplete_rows, style = "margin: 2px; font-weight: bold;"),
        p(paste("Rows with Missing (", pct, "%)", sep = ""), style = "font-size: 11px; margin: 0;"))
  })
  
  output$summary_missing_cells <- renderUI({
    data <- getData()
    total_cells <- nrow(data) * ncol(data)
    total_missing <- sum(sapply(data, function(x) sum(is.na(x))))
    pct <- round(100 * total_missing / total_cells, 1)
    div(h5(paste(pct, "%", sep = ""), style = "margin: 2px; font-weight: bold;"),
        p("Missing Cells", style = "font-size: 11px; margin: 0;"))
  })
  
  output$summary_data_completeness <- renderUI({
    data <- getData()
    total_cells <- nrow(data) * ncol(data)
    total_missing <- sum(sapply(data, function(x) sum(is.na(x))))
    complete_pct <- round(100 * (total_cells - total_missing) / total_cells, 1)
    div(h5(paste(complete_pct, "%", sep = ""), style = "margin: 2px; font-weight: bold;"),
        p("Data Complete", style = "font-size: 11px; margin: 0;"))
  })
  
  output$summary_numeric_count <- renderUI({ 
    div(h5(length(numeric_cols()), style = "margin: 2px; font-weight: bold;"), 
        p("Numeric Vars", style = "font-size: 11px; margin: 0;")) 
  })
  
  output$summary_categorical_count <- renderUI({ 
    div(h5(length(categorical_cols()), style = "margin: 2px; font-weight: bold;"), 
        p("Categorical Vars", style = "font-size: 11px; margin: 0;")) 
  })
  
  output$summary_missing_types <- renderUI({
    div(h5("Missing Data", style = "margin: 2px; font-weight: bold;"),
        p("NA values shown", style = "font-size: 11px; margin: 0;"))
  })
  
  # ------------------------------------------------------------------------
  # PART 3.1.3: Numeric variables summary table
  # ------------------------------------------------------------------------
  
  output$summary_numeric_table <- renderDT({
    data <- getData()
    num_cols <- numeric_cols()
    
    if(length(num_cols) == 0) {
      return(datatable(data.frame(Message = "No numeric variables found"), 
                       options = list(dom = 't'), rownames = FALSE))
    }
    
    summary_list <- lapply(num_cols, function(col) {
      if(col %in% names(data)) {
        vals <- data[[col]]
        total_missing <- sum(is.na(vals))
        if(sum(!is.na(vals)) > 0) {
          data.frame(Variable = gsub("_", " ", col), 
                     Min = round(min(vals, na.rm = TRUE), 2),
                     Q1 = round(quantile(vals, 0.25, na.rm = TRUE), 2),
                     Median = round(median(vals, na.rm = TRUE), 2),
                     Mean = round(mean(vals, na.rm = TRUE), 2),
                     Q3 = round(quantile(vals, 0.75, na.rm = TRUE), 2),
                     Max = round(max(vals, na.rm = TRUE), 2), 
                     SD = round(sd(vals, na.rm = TRUE), 2),
                     N = sum(!is.na(vals)), 
                     Missing = total_missing,
                     Missing_Pct = paste0(round(100 * total_missing / length(vals), 1), "%"),
                     stringsAsFactors = FALSE)
        } else {
          data.frame(Variable = gsub("_", " ", col), 
                     Min = NA, Q1 = NA, Median = NA, Mean = NA,
                     Q3 = NA, Max = NA, SD = NA, N = 0, Missing = total_missing,
                     Missing_Pct = "100%", stringsAsFactors = FALSE)
        }
      } else {
        data.frame(Variable = gsub("_", " ", col), 
                   Min = NA, Q1 = NA, Median = NA, Mean = NA,
                   Q3 = NA, Max = NA, SD = NA, N = 0, Missing = nrow(data),
                   Missing_Pct = "100%", stringsAsFactors = FALSE)
      }
    })
    
    summary_df <- do.call(rbind, summary_list)
    colnames(summary_df) <- c("Variable", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD",
                              "N", "Missing", "Missing %")
    
    datatable(summary_df, 
              options = list(paging = FALSE, searching = FALSE, info = FALSE, scrollX = TRUE, dom = 't'),
              rownames = FALSE) %>% 
      formatRound(columns = c("Min", "Q1", "Median", "Mean", "Q3", "Max", "SD"), digits = 2)
  })
  
  # ------------------------------------------------------------------------
  # PART 3.1.4: Categorical variables summary table
  # ------------------------------------------------------------------------
  
  output$summary_categorical_table <- renderDT({
    data <- getData()
    cat_cols <- categorical_cols()
    
    if(length(cat_cols) == 0) {
      return(datatable(data.frame(Message = "No categorical variables found"), 
                       options = list(dom = 't'), rownames = FALSE))
    }
    
    summary_list <- lapply(cat_cols, function(col) {
      if(col %in% names(data)) {
        vals <- data[[col]]
        val_counts <- table(vals, useNA = "no")
        n_unique <- length(val_counts)
        if(length(val_counts) > 0) {
          most_common <- names(sort(val_counts, decreasing = TRUE))[1]
          most_common_count <- max(val_counts)
          most_common_pct <- paste0(round(100 * most_common_count / length(vals), 1), "%")
        } else {
          most_common <- NA
          most_common_count <- 0
          most_common_pct <- "0%"
        }
        total_missing <- sum(is.na(vals))
        data.frame(Variable = gsub("_", " ", col), 
                   Unique_Values = n_unique,
                   Most_Common = as.character(most_common), 
                   Most_Common_Count = most_common_count,
                   Most_Common_Pct = most_common_pct, 
                   Total_Obs = length(vals),
                   Missing_Total = total_missing, 
                   Missing_Pct = paste0(round(100 * total_missing / length(vals), 1), "%"),
                   stringsAsFactors = FALSE)
      } else {
        data.frame(Variable = gsub("_", " ", col), 
                   Unique_Values = 0,
                   Most_Common = NA, 
                   Most_Common_Count = 0,
                   Most_Common_Pct = "0%", 
                   Total_Obs = nrow(data),
                   Missing_Total = nrow(data), 
                   Missing_Pct = "100%", 
                   stringsAsFactors = FALSE)
      }
    })
    
    summary_df <- do.call(rbind, summary_list)
    colnames(summary_df) <- c("Variable", "Unique Values", "Most Common", "Most Common Count",
                              "Most Common %", "Total Obs", "Missing Total", "Missing %")
    
    datatable(summary_df, 
              options = list(paging = FALSE, searching = FALSE, info = FALSE, scrollX = TRUE, dom = 't'), 
              rownames = FALSE)
  })
  
  # ------------------------------------------------------------------------
  # PART 3.1.5: Date variables summary table
  # ------------------------------------------------------------------------
  
  output$summary_date_table <- renderDT({
    data <- getData()
    date_cols_list <- date_cols()
    
    if(length(date_cols_list) == 0) {
      return(datatable(data.frame(Message = "No date variables found in the dataset"), 
                       options = list(dom = 't', pageLength = 1),
                       rownames = FALSE))
    }
    
    summary_list <- lapply(date_cols_list, function(col) {
      if(col %in% names(data)) {
        vals <- data[[col]]
        total_missing <- sum(is.na(vals))
        
        if(sum(!is.na(vals)) > 0) {
          non_na_vals <- vals[!is.na(vals)]
          date_range <- paste(format(min(non_na_vals), "%Y-%m-%d"), "to", format(max(non_na_vals), "%Y-%m-%d"))
          timespan_days <- as.numeric(diff(range(non_na_vals)))
          timespan_years <- round(timespan_days / 365.25, 1)
          
          years <- format(non_na_vals, "%Y")
          months <- format(non_na_vals, "%Y-%m")
          quarters <- paste0(format(non_na_vals, "%Y"), "-Q", quarters(non_na_vals))
          
          most_common_year <- names(sort(table(years), decreasing = TRUE))[1]
          most_common_year_count <- max(table(years))
          most_common_year_pct <- paste0(round(100 * most_common_year_count / length(non_na_vals), 1), "%")
          
          most_common_month <- names(sort(table(months), decreasing = TRUE))[1]
          most_common_month_count <- max(table(months))
          most_common_month_pct <- paste0(round(100 * most_common_month_count / length(non_na_vals), 1), "%")
          
          most_common_quarter <- names(sort(table(quarters), decreasing = TRUE))[1]
          most_common_quarter_count <- max(table(quarters))
          most_common_quarter_pct <- paste0(round(100 * most_common_quarter_count / length(non_na_vals), 1), "%")
          
          data.frame(
            Variable = gsub("_", " ", col),
            Min_Date = format(min(non_na_vals), "%Y-%m-%d"),
            Max_Date = format(max(non_na_vals), "%Y-%m-%d"),
            Date_Range = date_range,
            Timespan_Days = timespan_days,
            Timespan_Years = timespan_years,
            Total_Obs = length(vals),
            Missing_Count = total_missing,
            Missing_Pct = paste0(round(100 * total_missing / length(vals), 1), "%"),
            Most_Common_Year = paste0(most_common_year, " (", most_common_year_count, ", ", most_common_year_pct, ")"),
            Most_Common_Month = paste0(most_common_month, " (", most_common_month_count, ", ", most_common_month_pct, ")"),
            Most_Common_Quarter = paste0(most_common_quarter, " (", most_common_quarter_count, ", ", most_common_quarter_pct, ")"),
            stringsAsFactors = FALSE
          )
        } else {
          data.frame(
            Variable = gsub("_", " ", col),
            Min_Date = NA,
            Max_Date = NA,
            Date_Range = "No valid dates",
            Timespan_Days = NA,
            Timespan_Years = NA,
            Total_Obs = length(vals),
            Missing_Count = total_missing,
            Missing_Pct = "100%",
            Most_Common_Year = "No valid dates",
            Most_Common_Month = "No valid dates",
            Most_Common_Quarter = "No valid dates",
            stringsAsFactors = FALSE
          )
        }
      } else {
        data.frame(
          Variable = gsub("_", " ", col),
          Min_Date = NA,
          Max_Date = NA,
          Date_Range = "Column not found",
          Timespan_Days = NA,
          Timespan_Years = NA,
          Total_Obs = nrow(data),
          Missing_Count = nrow(data),
          Missing_Pct = "100%",
          Most_Common_Year = "N/A",
          Most_Common_Month = "N/A",
          Most_Common_Quarter = "N/A",
          stringsAsFactors = FALSE
        )
      }
    })
    
    summary_df <- do.call(rbind, summary_list)
    colnames(summary_df) <- c("Variable", "Min Date", "Max Date", "Date Range", 
                              "Timespan (Days)", "Timespan (Years)", "Total Obs", 
                              "Missing Count", "Missing %", "Most Common Year", 
                              "Most Common Month", "Most Common Quarter")
    
    datatable(summary_df, 
              options = list(
                paging = FALSE, 
                searching = FALSE, 
                info = FALSE, 
                scrollX = TRUE, 
                dom = 't',
                columnDefs = list(
                  list(className = 'dt-center', targets = '_all')
                )
              ), 
              rownames = FALSE) %>% 
      formatRound(columns = c("Timespan (Days)", "Timespan (Years)"), digits = 1)
  })
  
  # ------------------------------------------------------------------------
  # PART 3.1.6: Missing values summary table
  # ------------------------------------------------------------------------
  
  output$summary_missing_table <- renderDT({
    data <- getData()
    
    missing_df <- data.frame(Variable = gsub("_", " ", names(data)), 
                             Total_Obs = nrow(data),
                             Missing_Count = sapply(data, function(x) sum(is.na(x))),
                             stringsAsFactors = FALSE)
    
    missing_df$Missing_Pct <- paste0(round(100 * missing_df$Missing_Count / nrow(data), 1), "%")
    missing_df$Type <- ifelse(names(data) %in% numeric_cols(), "Numeric", "Categorical")
    missing_df <- missing_df[, c("Variable", "Type", "Total_Obs", "Missing_Count", "Missing_Pct")]
    colnames(missing_df) <- c("Variable", "Type", "Total Obs", "Missing Count", "Missing %")
    
    datatable(missing_df, 
              options = list(paging = FALSE, searching = FALSE, info = FALSE, scrollX = TRUE, dom = 't'), 
              rownames = FALSE)
  })
  
  # ------------------------------------------------------------------------
  # PART 3.1.7: Date distribution plot (Monthly Line Graph) - CLEANED
  # ------------------------------------------------------------------------
  
  output$summary_date_plot <- renderPlotly({
    data <- getData()
    date_cols_list <- date_cols()
    
    if (length(date_cols_list) == 0) {
      return(
        plot_ly() %>%
          add_annotations(text = "No date variables found", x = 0.5, y = 0.5,
                          showarrow = FALSE, font = list(size = 16, color = "#e74c3c")) %>%
          layout(xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
      )
    }
    
    date_col <- date_cols_list[1]
    vals <- data[[date_col]]
    vals <- vals[!is.na(vals)]
    
    if (length(vals) == 0) {
      return(
        plot_ly() %>%
          add_annotations(text = "No valid dates to plot", x = 0.5, y = 0.5,
                          showarrow = FALSE, font = list(size = 16, color = "#e74c3c")) %>%
          layout(xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
      )
    }
    
    # Monthly aggregation
    ym <- format(vals, "%Y-%m")
    monthly_counts <- as.data.frame(table(ym), stringsAsFactors = FALSE)
    names(monthly_counts) <- c("YearMonth", "Count")
    monthly_counts$Count <- as.integer(monthly_counts$Count)
    monthly_counts$Date  <- as.Date(paste0(monthly_counts$YearMonth, "-01"))
    monthly_counts <- monthly_counts[order(monthly_counts$Date), ]
    monthly_counts$Label <- format(monthly_counts$Date, "%b %Y")
    
    overall_mean <- mean(monthly_counts$Count)
    
    plot_ly() %>%
      add_bars(
        data = monthly_counts,
        x    = ~Date,
        y    = ~Count,
        name = "Monthly Count",
        marker = list(color = "#13D4D4", opacity = 0.75,
                      line = list(color = "#0a9c9c", width = 0.5)),
        text          = ~paste0("<b>", Label, "</b><br>Count: ", Count),
        hoverinfo     = "text",
        hovertemplate = "%{text}<extra></extra>"
      ) %>%
      add_lines(
        x    = range(monthly_counts$Date),
        y    = c(overall_mean, overall_mean),
        name = paste0("Mean (", round(overall_mean, 1), ")"),
        line = list(color = "#e74c3c", width = 1.5, dash = "dash"),
        hoverinfo  = "skip",
        showlegend = TRUE
      ) %>%
      layout(
        title = list(
          text = paste("Monthly Distribution —", gsub("_", " ", date_col)),
          font = list(size = 14, color = "#2C3E50", family = "Arial"),
          x    = 0.5
        ),
        xaxis = list(
          title      = "",
          type       = "date",
          tickformat = "%b %Y",
          tickangle  = -45,
          tickfont   = list(size = 10),
          gridcolor  = "#ebebeb",
          showgrid   = TRUE,
          zeroline   = FALSE,
          automargin = TRUE
        ),
        yaxis = list(
          title     = "Count",
          titlefont = list(size = 12, color = "#2C3E50"),
          tickfont  = list(size = 10),
          gridcolor = "#ebebeb",
          showgrid  = TRUE,
          zeroline  = FALSE
        ),
        plot_bgcolor  = "#fafafa",
        paper_bgcolor = "#ffffff",
        hovermode     = "x unified",
        bargap        = 0.15,
        showlegend    = TRUE,
        legend = list(
          orientation = "v",        # Vertical legend
          yanchor     = "top",      # Anchor at top
          y           = 1,          # Position at top of plot area
          xanchor     = "left",     # Anchor at left
          x           = 1.02,       # Position to the right of the plot
          font        = list(size = 11),
          bgcolor     = "rgba(255,255,255,0.8)",  # Semi-transparent background
          bordercolor = "#cccccc",
          borderwidth = 1
        ),
        margin = list(l = 55, r = 100, t = 60, b = 90)  # Increased right margin for legend
      )
  })
  
  # ------------------------------------------------------------------------
  # PART 3.1.8: Complete data summary using summarytools
  # ------------------------------------------------------------------------
  
  output$summary_dfsummary <- renderUI({
    tryCatch({
      if(!requireNamespace("summarytools", quietly = TRUE)) {
        return(HTML("<div class='alert alert-warning'><strong>Package not installed:</strong> 'summarytools' is required for this feature.</div>"))
      }
      data <- getData()
      summary_df <- summarytools::dfSummary(data, 
                                            graph.col = FALSE, 
                                            valid.col = TRUE, 
                                            silent = TRUE,
                                            style = "grid", 
                                            plain.ascii = FALSE, 
                                            headings = FALSE, 
                                            method = 'render', 
                                            footnote = NA,
                                            tmp.img.dir = "/tmp")
      html_output <- capture.output(summarytools::view(summary_df, method = 'render', bootstrap.css = FALSE, silent = TRUE))
      HTML(paste(html_output, collapse = "\n"))
    }, error = function(e) {
      HTML(paste0("<div class='alert alert-danger'><strong>Error generating summary:</strong> ", e$message, "</div>"))
    })
  })
  
  
  
  # ========================================================================
  # SUBSECTION 3.2: BOXPLOT ANALYSIS MODULE
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # PART 3.2.1: Boxplot - Update picker inputs
  # ------------------------------------------------------------------------
  
  # Use observeEvent with once = TRUE for initial setup only
  observeEvent(getData(), {
    data <- getData()
    numeric_vars <- names(data)[sapply(data, is.numeric)]
    categorical_vars <- names(data)[sapply(data, function(x) is.factor(x) | is.character(x))]
    
    # Only set initial selections once
    isolate({
      updateSelectizeInput(session, "boxplot_numeric_vars",
                        choices = numeric_vars,
                        selected = numeric_vars[1:min(21, length(numeric_vars))])  # Start with first 5 only
      
      updateSelectizeInput(session, "boxplot_cat_vars_group",
                        choices = c("None", categorical_vars),
                        selected = "None")
      
      updateSelectizeInput(session, "boxplot_filter_vars",
                        choices = categorical_vars,
                        selected = character(0))
    })
  }, once = TRUE)  # KEY: only run this once at startup
  
  # ------------------------------------------------------------------------
  # PART 3.2.2: Boxplot - Dynamic filter UI
  # ------------------------------------------------------------------------
  
  # ------------------------------------------------------------------------
  # PART 3.2.2: Boxplot - Dynamic filter UI (UPDATED with selectizeInput)
  # ------------------------------------------------------------------------
  
  output$boxplot_cat_filters_ui <- renderUI({
    req(input$boxplot_filter_vars)
    data <- getData()
    filter_list <- list()
    
    for(var in input$boxplot_filter_vars) {
      if(var %in% names(data)) {
        choices <- unique(data[[var]])
        # Get current selections if they exist
        current_selected <- input[[paste0("boxplot_filter_", var)]]
        if(is.null(current_selected)) {
          current_selected <- choices  # Default to all selected
        }
        
        filter_list[[var]] <- div(
          style = "margin-top: 10px; margin-bottom: 15px;",
          tags$label(class = "control-label", paste("Filter", gsub("_", " ", var), ":"),
                     style = "font-weight: bold; font-size: 12px;"),
          selectizeInput(
            inputId = paste0("boxplot_filter_", var),
            label = NULL,  # No label, we added one above
            choices = choices,
            selected = current_selected,
            multiple = TRUE,
            options = list(
              placeholder = paste('Select', gsub("_", " ", var), 'values...'),
              plugins = list('remove_button')
            )
          )
        )
      }
    }
    
    do.call(tagList, filter_list)
  })
  
  # ------------------------------------------------------------------------
  # PART 3.2.3: Boxplot - Reset button observer
  # ------------------------------------------------------------------------
  
  observeEvent(input$reset_boxplot, {
    data <- isolate(getData())
    numeric_vars <- names(data)[sapply(data, is.numeric)]
    categorical_vars <- names(data)[sapply(data, function(x) is.factor(x) | is.character(x))]
    
    updateSliderInput(session, "iqr_boxplot", value = 1.5)
    updateCheckboxInput(session, "boxplot_center", value = TRUE)
    updateCheckboxInput(session, "boxplot_scale", value = TRUE)
    updateCheckboxInput(session, "include_null_boxplot", value = FALSE)
    
    updateSelectizeInput(session, "boxplot_numeric_vars",
                         choices = numeric_vars,
                         selected = numeric_vars[1:min(5, length(numeric_vars))])
    
    updateSelectizeInput(session, "boxplot_cat_vars_group",
                         choices = c("None", categorical_vars),
                         selected = "None")
    
    # Clear filter selections
    updateSelectizeInput(session, "boxplot_filter_vars",
                         choices = categorical_vars,
                         selected = character(0))
    
    # Note: The dynamic filter UI will re-render and reset automatically
    # because boxplot_filter_vars is now empty
  })
  
  # ------------------------------------------------------------------------
  # PART 3.2.4: Boxplot - Helper function to calculate outliers
  # ------------------------------------------------------------------------
  
  calculate_outliers <- function(values, iqr_multiplier = 1.5) {
    q1 <- quantile(values, 0.25, na.rm = TRUE)
    q3 <- quantile(values, 0.75, na.rm = TRUE)
    iqr <- q3 - q1
    lower_bound <- q1 - iqr_multiplier * iqr
    upper_bound <- q3 + iqr_multiplier * iqr
    outliers <- which(values < lower_bound | values > upper_bound)
    return(list(
      indices = outliers,
      lower = lower_bound,
      upper = upper_bound,
      values = values[outliers]
    ))
  }
  
  # ------------------------------------------------------------------------
  # PART 3.2.5: Boxplot - Render plot
  # ------------------------------------------------------------------------
  
  output$boxplot_plot <- renderPlotly({
    req(input$boxplot_numeric_vars)
    
    data <- getData()
    
    # Ensure Patient IDs are available as row names
    patient_ids <- rownames(data)
    if(is.null(patient_ids)) {
      patient_ids <- as.character(1:nrow(data))
    }
    
    # Apply categorical filters
    if(!is.null(input$boxplot_filter_vars)) {
      for(var in input$boxplot_filter_vars) {
        selected_vals <- input[[paste0("boxplot_filter_", var)]]
        if(!is.null(selected_vals)) {
          filter_idx <- data[[var]] %in% selected_vals
          data <- data[filter_idx, ]
          patient_ids <- patient_ids[filter_idx]
        }
      }
    }
    
    # Handle missing values — always remove incomplete cases for selected vars
    complete_cases <- complete.cases(data[, input$boxplot_numeric_vars, drop = FALSE])
    data <- data[complete_cases, ]
    patient_ids <- patient_ids[complete_cases]
    
    
    
    
    # Center and scale if selected
    plot_data <- data[, input$boxplot_numeric_vars, drop = FALSE]
    original_values <- plot_data
    
    if(input$boxplot_center | input$boxplot_scale) {
      plot_data <- scale(plot_data, center = input$boxplot_center, scale = input$boxplot_scale)
      plot_data <- as.data.frame(plot_data)
      names(plot_data) <- input$boxplot_numeric_vars
    }
    
    # Calculate dynamic height
    n_vars <- length(input$boxplot_numeric_vars)
    plot_height <- min(900, max(500, n_vars * 50 + 100))
    
    # Create horizontal boxplot
    plot_data$Patient <- patient_ids
    plot_data$OriginalValues <- original_values
    
    plot_data_long <- tidyr::pivot_longer(plot_data, 
                                          cols = -c(Patient, OriginalValues),
                                          names_to = "variable", 
                                          values_to = "value")
    
    # Extract original values
    original_long <- tidyr::pivot_longer(original_values,
                                         cols = everything(),
                                         names_to = "variable",
                                         values_to = "original_value")
    plot_data_long$original_value <- original_long$original_value
    
    # Identify outliers
    plot_data_long <- plot_data_long %>%
      group_by(variable) %>%
      mutate(
        is_outlier = {
          outlier_info <- calculate_outliers(value, input$iqr_boxplot)
          seq_along(value) %in% outlier_info$indices
        }
      ) %>%
      ungroup()
    
    # Create hover text
    plot_data_long$hover_text <- paste0(
      "<b>Patient:</b> ", plot_data_long$Patient, "<br>",
      "<b>Variable:</b> ", gsub("_", " ", plot_data_long$variable), "<br>",
      "<b>Value:</b> ", round(plot_data_long$original_value, 3)
    )
    
    # Create display names
    plot_data_long$display_name <- gsub("_", " ", plot_data_long$variable)
    unique_names <- unique(plot_data_long$display_name)
    
    # Create plot
    p <- plot_ly(height = plot_height)
    
    for(var_name in unique_names) {
      var_data <- plot_data_long %>% filter(display_name == var_name)
      
      p <- p %>% add_trace(
        data = var_data,
        y = ~display_name,
        x = ~value,
        type = "box",
        name = var_name,
        orientation = "h",
        boxpoints = FALSE,
        line = list(color = "steelblue", width = 2),
        fillcolor = "lightblue",
        marker = list(color = "steelblue"),
        hoverinfo = "none",
        showlegend = FALSE
      )
    }
    
    # Add outlier points
    outliers <- plot_data_long %>% filter(is_outlier)
    if(nrow(outliers) > 0) {
      p <- p %>% add_trace(
        data = outliers,
        y = ~display_name,
        x = ~value,
        type = "scatter",
        mode = "markers",
        name = "Outliers",
        marker = list(size = 12, color = 'red', symbol = 'circle',
                      line = list(color = 'darkred', width = 1.5)),
        text = ~hover_text,
        hoverinfo = "text",
        hoverlabel = list(bgcolor = "white", font = list(size = 12, color = "black", family = "monospace"),
                          bordercolor = "red", borderwidth = 1),
        showlegend = TRUE
      )
    }
    
    p <- p %>% layout(
      title = list(text = "Horizontal Boxplot Analysis - Outliers Highlighted in Red",
                   font = list(size = 16, color = "#2C3E50")),
      xaxis = list(title = "Value", gridcolor = "#e0e0e0", zerolinecolor = "#cccccc"),
      yaxis = list(title = "", tickangle = 0, gridcolor = "#e0e0e0",
                   categoryorder = "array", categoryarray = rev(unique_names),
                   tickfont = list(size = 11)),
      hovermode = "closest",
      legend = list(orientation = "h", yanchor = "bottom", y = -0.08,
                    xanchor = "center", x = 0.5, font = list(size = 10)),
      plot_bgcolor = "#f8f9fa", paper_bgcolor = "#ffffff",
      margin = list(l = 150, r = 50, t = 80, b = 80)
    )
    
    p
  })
  
  # ------------------------------------------------------------------------
  # PART 3.2.6: Boxplot - Statistics output
  # ------------------------------------------------------------------------
  
  output$boxplot_stats <- renderPrint({
    req(input$boxplot_numeric_vars)
    
    data <- getData()
    patient_ids <- rownames(data)
    if(is.null(patient_ids)) {
      patient_ids <- as.character(1:nrow(data))
    }
    
    # Apply filters
    if(!is.null(input$boxplot_filter_vars)) {
      for(var in input$boxplot_filter_vars) {
        selected_vals <- input[[paste0("boxplot_filter_", var)]]
        if(!is.null(selected_vals)) {
          filter_idx <- data[[var]] %in% selected_vals
          data <- data[filter_idx, ]
          patient_ids <- patient_ids[filter_idx]
        }
      }
    }
    
    if(!input$include_null_boxplot) {
      complete_cases <- complete.cases(data[, input$boxplot_numeric_vars, drop = FALSE])
      data <- data[complete_cases, ]
      patient_ids <- patient_ids[complete_cases]
    }
    
    W <- 79  # total line width including borders
    inner <- W - 2
    
    pad <- function(label, value, width = inner) {
      content <- paste0("  ", label, value)
      padded  <- formatC(content, width = -width, flag = "-")
      cat(paste0("\u2551", padded, "\u2551\n"))
    }
    
    cat("\n")
    cat(paste0("\u2554", paste(rep("\u2550", inner), collapse = ""), "\u2557\n"))
    title <- "BOXPLOT STATISTICS REPORT"
    cat(paste0("\u2551", formatC(title, width = -inner, flag = "-"), "\u2551\n"))
    cat(paste0("\u2560", paste(rep("\u2550", inner), collapse = ""), "\u2563\n"))
    pad("IQR Multiplier : ", input$iqr_boxplot)
    pad("Center Data    : ", input$boxplot_center)
    pad("Scale Data     : ", input$boxplot_scale)
    pad("Variables      : ", paste(input$boxplot_numeric_vars, collapse = ", "))
    cat(paste0("\u255a", paste(rep("\u2550", inner), collapse = ""), "\u255d\n"))
    cat("\n")
    
    for(var in input$boxplot_numeric_vars) {
      vals <- data[[var]]
      if(length(vals) > 0) {
        outlier_info <- calculate_outliers(vals, input$iqr_boxplot)
        
        cat("\n", rep("\u2501", 70), "\n", sep = "")
        cat(sprintf("   %s\n", toupper(gsub("_", " ", var))))
        cat(rep("\u2501", 70), "\n", sep = "")
        
        cat(sprintf("  \u2022 Minimum:                     %12.3f\n", min(vals, na.rm = TRUE)))
        cat(sprintf("  \u2022 Q1 (25th percentile):        %12.3f\n", quantile(vals, 0.25, na.rm = TRUE)))
        cat(sprintf("  \u2022 Median (Q2):                 %12.3f\n", median(vals, na.rm = TRUE)))
        cat(sprintf("  \u2022 Mean:                        %12.3f\n", mean(vals, na.rm = TRUE)))
        cat(sprintf("  \u2022 Q3 (75th percentile):        %12.3f\n", quantile(vals, 0.75, na.rm = TRUE)))
        cat(sprintf("  \u2022 Maximum:                     %12.3f\n", max(vals, na.rm = TRUE)))
        cat(sprintf("  \u2022 IQR (Q3 - Q1):               %12.3f\n", IQR(vals, na.rm = TRUE)))
        cat(sprintf("  \u2022 Lower Bound (IQR x %.1f):   %12.3f\n", input$iqr_boxplot, outlier_info$lower))
        cat(sprintf("  \u2022 Upper Bound (IQR x %.1f):   %12.3f\n", input$iqr_boxplot, outlier_info$upper))
        cat(sprintf("  \u2022 Total Observations:          %12d\n", length(vals)))
        cat(sprintf("  \u2022 Missing Values:              %12d\n", sum(is.na(vals))))
        cat(sprintf("  \u2022 Number of Outliers:          %12d\n", length(outlier_info$indices)))
        
        if(length(outlier_info$indices) > 0) {
          cat("\n")
          cat("  +------------------+-------------+------------------------------------------+\n")
          cat("  |   Patient ID     |    Value    |   Type                                   |\n")
          cat("  +------------------+-------------+------------------------------------------+\n")
          
          for(i in seq_along(outlier_info$indices)) {
            idx      <- outlier_info$indices[i]
            pid      <- patient_ids[idx]
            value    <- outlier_info$values[i]
            type_str <- ifelse(value < outlier_info$lower, "BELOW LOWER BOUND", "ABOVE UPPER BOUND")
            cat(sprintf("  | %-16s | %11.3f | %-40s |\n",
                        substr(pid, 1, 16), value, type_str))
          }
          cat("  +------------------+-------------+------------------------------------------+\n")
        }
        cat("\n")
      }
    }
  })
  
  
  
  # ========================================================================
  # SUBSECTION 3.3: CORRELATION ANALYSIS MODULE
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # PART 3.3.1: Helper function for correlation ordering
  # ------------------------------------------------------------------------
  
  order_correlation <- function(corr_matrix) {
    hc <- hclust(as.dist(1 - abs(corr_matrix)), method = "complete")
    return(hc$order)
  }
  
  # ------------------------------------------------------------------------
  # PART 3.3.2: Correlation - Reset button observer
  # ------------------------------------------------------------------------
  
  observeEvent(input$reset_correlation, {
    updateSelectInput(session, "corr_method", selected = "pearson")
    updateSelectInput(session, "corr_order", selected = "AOE")
    updateCheckboxInput(session, "corr_abs", value = FALSE)
    updateCheckboxInput(session, "corr_show_values", value = TRUE)
    updateSelectInput(session, "corr_digits", selected = 2)
    updateCheckboxInput(session, "corr_na_omit", value = TRUE)
  })
  
  # ------------------------------------------------------------------------
  # PART 3.3.3: Correlation - Render plot
  # ------------------------------------------------------------------------
  
  output$correlation_plot <- renderPlotly({
    data <- getData()
    numeric_data <- data[, sapply(data, is.numeric), drop = FALSE]
    
    if(input$corr_na_omit) {
      numeric_data <- na.omit(numeric_data)
    }
    
    if(ncol(numeric_data) < 2) {
      return(plot_ly() %>% 
               add_annotations(text = "Need at least 2 numeric variables", x = 0.5, y = 0.5, showarrow = FALSE) %>%
               layout(xaxis = list(visible = FALSE), yaxis = list(visible = FALSE)))
    }
    
    cor_matrix <- cor(numeric_data, method = input$corr_method, use = "pairwise.complete.obs")
    
    if(input$corr_abs) {
      cor_matrix_for_plot <- abs(cor_matrix)
      colorscale <- list(list(0, "white"), list(0.5, "#ff9999"), list(1, "red"))
      zmin <- 0
      zmax <- 1
      colorbar_title <- "Absolute Correlation"
    } else {
      cor_matrix_for_plot <- cor_matrix
      colorscale <- list(list(0, "blue"), list(0.5, "white"), list(1, "red"))
      zmin <- -1
      zmax <- 1
      colorbar_title <- "Correlation"
    }
    
    # Simple ordering if AOE is selected
    if(input$corr_order == "AOE" && requireNamespace("corrgram", quietly = TRUE)) {
      tryCatch({
        corr_order <- corrgram::order.correlation(cor_matrix_for_plot)
        cor_matrix <- cor_matrix[corr_order, corr_order]
        cor_matrix_for_plot <- cor_matrix_for_plot[corr_order, corr_order]
      }, error = function(e) {})
    }
    
    # Dynamic height based on number of variables
    n_vars <- ncol(cor_matrix)
    plot_height <- min(900, max(400, n_vars * 35 + 100))
    
    p <- plot_ly(
      z = cor_matrix_for_plot,
      x = colnames(cor_matrix),
      y = rownames(cor_matrix),
      type = "heatmap",
      colorscale = colorscale,
      zmin = zmin, zmax = zmax,
      showscale = TRUE,
      colorbar = list(title = colorbar_title, len = 0.8),
      text = if(input$corr_show_values) round(cor_matrix, as.numeric(input$corr_digits)) else NULL,
      texttemplate = if(input$corr_show_values) "%{text}" else NULL,
      textfont = list(size = 10),
      hovertemplate = "<b>%{x}</b> vs <b>%{y}</b><br>Correlation: %{z:.3f}<extra></extra>"
    )
    
    p %>% layout(
      title = list(text = paste(toupper(input$corr_method), "Correlation Matrix"),
                   font = list(size = 16, color = "#2C3E50")),
      xaxis = list(title = "", tickangle = -45, tickfont = list(size = 10)),
      yaxis = list(title = "", tickfont = list(size = 10)),
      plot_bgcolor = "#f8f9fa",
      paper_bgcolor = "#ffffff",
      margin = list(l = 120, r = 50, t = 80, b = 100),
      height = plot_height
    )
  })
  
  # ------------------------------------------------------------------------
  # PART 3.3.4: Correlation - Statistics output
  # ------------------------------------------------------------------------
  
  output$correlation_stats <- renderPrint({
    data <- getData()
    numeric_data <- data[, sapply(data, is.numeric), drop = FALSE]
    
    if(input$corr_na_omit) {
      numeric_data <- na.omit(numeric_data)
    }
    
    if(ncol(numeric_data) < 2) {
      cat("Need at least 2 numeric variables for correlation analysis.\n")
      return()
    }
    
    cor_matrix <- cor(numeric_data, method = input$corr_method, use = "pairwise.complete.obs")
    
    W     <- 76
    inner <- W - 2
    
    pad <- function(label, value) {
      content <- paste0("  ", label, value)
      cat(paste0("\u2551", formatC(content, width = -inner, flag = "-"), "\u2551\n"))
    }
    
    cat(paste0("\u2554", paste(rep("\u2550", inner), collapse = ""), "\u2557\n"))
    title <- "CORRELATION MATRIX SUMMARY"
    cat(paste0("\u2551", formatC(title, width = -inner, flag = "-"), "\u2551\n"))
    cat(paste0("\u2560", paste(rep("\u2550", inner), collapse = ""), "\u2563\n"))
    pad("Method                    : ", toupper(input$corr_method))
    pad("Absolute correlations     : ", input$corr_abs)
    pad("Ordering                  : ", input$corr_order)
    if(input$corr_order == "hclust") {
      pad("Clustering method         : ", input$hclust_method)
    }
    cat(paste0("\u2560", paste(rep("\u2550", inner), collapse = ""), "\u2563\n"))
    pad("Number of variables       : ", ncol(numeric_data))
    pad("Observations (after NA)   : ", nrow(numeric_data))
    cat(paste0("\u255a", paste(rep("\u2550", inner), collapse = ""), "\u255d\n"))
    cat("\n")
    
    upper_tri <- cor_matrix[upper.tri(cor_matrix)]
    
    cat(paste(rep("\u2500", 50), collapse = ""), "\n")
    cat("  Correlation Statistics\n")
    cat(paste(rep("\u2500", 50), collapse = ""), "\n")
    cat(sprintf("  %-30s %8.3f\n", "Minimum correlation:",  min(upper_tri,    na.rm = TRUE)))
    cat(sprintf("  %-30s %8.3f\n", "Maximum correlation:",  max(upper_tri,    na.rm = TRUE)))
    cat(sprintf("  %-30s %8.3f\n", "Mean correlation:",     mean(upper_tri,   na.rm = TRUE)))
    cat(sprintf("  %-30s %8.3f\n", "Median correlation:",   median(upper_tri, na.rm = TRUE)))
    cat(sprintf("  %-30s %8.3f\n", "SD of correlations:",   sd(upper_tri,     na.rm = TRUE)))
    cat("\n")
    
    cor_flat <- cor_matrix
    diag(cor_flat) <- NA
    cor_values <- abs(cor_flat)
    high_cors  <- which(!is.na(cor_values), arr.ind = TRUE)
    
    if(nrow(high_cors) > 0) {
      cor_df <- data.frame(
        Variable1   = rownames(cor_flat)[high_cors[, 1]],
        Variable2   = colnames(cor_flat)[high_cors[, 2]],
        Correlation = cor_flat[high_cors]
      )
      cor_df <- cor_df[!duplicated(t(apply(cor_df[, 1:2], 1, sort))), ]
      cor_df <- cor_df[order(abs(cor_df$Correlation), decreasing = TRUE), ]
      cor_df <- head(cor_df, 5)
      
      cat(paste(rep("\u2500", 50), collapse = ""), "\n")
      cat("  Top 5 Strongest Correlations\n")
      cat(paste(rep("\u2500", 50), collapse = ""), "\n")
      for(i in 1:nrow(cor_df)) {
        direction <- if(cor_df$Correlation[i] > 0) "Positive" else "Negative"
        cat(sprintf("  %-20s <-> %-20s  %s (%.3f)\n",
                    cor_df$Variable1[i], cor_df$Variable2[i],
                    direction, cor_df$Correlation[i]))
      }
    }
  })
  
  # ------------------------------------------------------------------------
  # PART 3.3.5: Correlation - Observation count output
  # ------------------------------------------------------------------------
  
  output$corr_obs_count <- renderText({
    data <- getData()
    numeric_data <- data[, sapply(data, is.numeric), drop = FALSE]
    if(input$corr_na_omit) {
      numeric_data <- na.omit(numeric_data)
    }
    paste("Analysis based on", nrow(numeric_data), "complete observations")
  })
  
  
  
  # ========================================================================
  # SUBSECTION 3.4: MISSING VALUES HEATMAP MODULE
  # ========================================================================
  
  
  # ------------------------------------------------------------------------
  # PART 3.4.1: Heatmap - Update picker inputs
  # ------------------------------------------------------------------------
  
  observeEvent(getData(), {
    data <- getData()
    numeric_vars <- names(data)[sapply(data, is.numeric)]
    categorical_vars <- names(data)[sapply(data, function(x) is.factor(x) | is.character(x))]
    
    isolate({
      updateSelectizeInput(session, "heatmap_numeric_vars",
                        choices = numeric_vars,
                        selected = numeric_vars)  # Select all numeric by default
      
      updateSelectizeInput(session, "heatmap_cat_vars",
                        choices = categorical_vars,
                        selected = categorical_vars)  # Select all categorical by default
    })
  }, once = TRUE)  # KEY: only run once
  
  # ------------------------------------------------------------------------
  # PART 3.4.2: Heatmap - Reset button observer
  # ------------------------------------------------------------------------
  
  observeEvent(input$reset_heatmap, {
    data <- isolate(getData())
    numeric_vars <- names(data)[sapply(data, is.numeric)]
    categorical_vars <- names(data)[sapply(data, function(x) is.factor(x) | is.character(x))]
    
    updateSliderInput(session, "col_missing_threshold", value = 100)
    updateSliderInput(session, "row_missing_threshold", value = 100)
    updateRadioButtons(session, "heatmap_order", selected = "original")
    
    updatePickerInput(session, "heatmap_numeric_vars",
                      choices = numeric_vars,
                      selected = numeric_vars)
    
    updatePickerInput(session, "heatmap_cat_vars",
                      choices = categorical_vars,
                      selected = categorical_vars)
  })
  
  # ------------------------------------------------------------------------
  # PART 3.4.3: Heatmap - Render plot with percentage-based row filtering
  # ------------------------------------------------------------------------
  
  output$heatmap_plot <- renderPlotly({
    data <- getData()
    
    patient_ids <- rownames(data)
    if(is.null(patient_ids)) {
      patient_ids <- as.character(1:nrow(data))
    }
    
    selected_vars <- c(input$heatmap_numeric_vars, input$heatmap_cat_vars)
    req(length(selected_vars) > 0)
    
    plot_data <- data[, selected_vars, drop = FALSE]
    missing_matrix <- is.na(plot_data)
    
    # Apply thresholds
    col_missing_pct <- colMeans(missing_matrix) * 100
    cols_to_keep <- col_missing_pct <= input$col_missing_threshold
    missing_matrix <- missing_matrix[, cols_to_keep, drop = FALSE]
    
    row_missing_pct <- rowMeans(missing_matrix) * 100
    rows_to_keep <- row_missing_pct <= input$row_missing_threshold
    missing_matrix <- missing_matrix[rows_to_keep, , drop = FALSE]
    
    if(ncol(missing_matrix) == 0 || nrow(missing_matrix) == 0) {
      return(plot_ly() %>% 
               add_annotations(text = "No data meets criteria", x = 0.5, y = 0.5, showarrow = FALSE) %>%
               layout(xaxis = list(visible = FALSE), yaxis = list(visible = FALSE)))
    }
    
    # Order if selected
    if(input$heatmap_order == "desc") {
      col_order <- order(colMeans(missing_matrix), decreasing = TRUE)
      missing_matrix <- missing_matrix[, col_order, drop = FALSE]
    }
    
    missing_numeric <- matrix(as.numeric(missing_matrix), 
                              nrow = nrow(missing_matrix), 
                              ncol = ncol(missing_matrix))
    colnames(missing_numeric) <- colnames(missing_matrix)
    rownames(missing_numeric) <- patient_ids[rows_to_keep]
    
    # Dynamic height based on number of rows and columns
    n_rows <- nrow(missing_numeric)
    n_cols <- ncol(missing_numeric)
    plot_height <- min(900, max(400, n_rows * 20 + n_cols * 15 + 100))
    
    p <- plot_ly(
      z = missing_numeric,
      x = colnames(missing_numeric),
      y = rownames(missing_numeric),
      type = "heatmap",
      colorscale = list(list(0, "lightblue"), list(1, "red")),
      showscale = TRUE,
      colorbar = list(title = "Data Status", tickvals = c(0, 1), ticktext = c("Present", "Missing"), len = 0.8),
      hovertemplate = "Variable: %{x}<br>Patient: %{y}<br>Status: %{z}<extra></extra>"
    )
    
    p %>% layout(
      title = "Missing Values Heatmap",
      xaxis = list(title = "Variables", tickangle = -45, tickfont = list(size = 10)),
      yaxis = list(
        title = list(
          text = "Patients",
          standoff = 20  # This brings the title closer to the plot area
        ),
        titlefont = list(size = 12),
        tickfont = list(size = 8),
        automargin = TRUE  # Automatically adjusts margins for labels
      ),
      height = plot_height,
      margin = list(l = 100, r = 50, t = 60, b = 100)  # Increase left margin for patient labels
    )
  })
  
  # ------------------------------------------------------------------------
  # PART 3.4.4: Heatmap - Summary output with percentage-based info
  # ------------------------------------------------------------------------
  
  output$heatmap_summary <- renderPrint({
    data <- getData()
    patient_ids <- rownames(data)
    if(is.null(patient_ids)) patient_ids <- as.character(1:nrow(data))
    
    total_missing <- sum(is.na(data))
    total_cells   <- nrow(data) * ncol(data)
    missing_pct   <- 100 * total_missing / total_cells
    
    W     <- 57
    inner <- W - 2
    rule  <- paste(rep("\u2500", inner), collapse = "")
    
    cat(paste0("\u250c", rule, "\u2510\n"))
    title <- "  MISSING DATA SUMMARY"
    cat(paste0("\u2502", formatC(title, width = -inner, flag = "-"), "\u2502\n"))
    cat(paste0("\u251c", rule, "\u2524\n"))
    
    row2 <- function(label, value) {
      content <- sprintf("  %-32s %s", label, as.character(value))
      cat(paste0("\u2502", formatC(content, width = -inner, flag = "-"), "\u2502\n"))
    }
    
    row2("Total observations:",       nrow(data))
    row2("Total variables:",          ncol(data))
    row2("Total cells:",              total_cells)
    row2("Total missing values:",     total_missing)
    row2("Overall missing %:",        paste0(round(missing_pct, 2), "%"))
    
    cat(paste0("\u251c", rule, "\u2524\n"))
    title2 <- "  Variables with Most Missing"
    cat(paste0("\u2502", formatC(title2, width = -inner, flag = "-"), "\u2502\n"))
    cat(paste0("\u251c", rule, "\u2524\n"))
    
    missing_by_var <- sort(colSums(is.na(data)), decreasing = TRUE)
    shown <- 0
    for(i in seq_along(missing_by_var)) {
      if(missing_by_var[i] == 0) break
      if(shown >= 10) break
      pct     <- round(100 * missing_by_var[i] / nrow(data), 1)
      content <- sprintf("  %-28s %4d  (%4.1f%%)", names(missing_by_var)[i], missing_by_var[i], pct)
      cat(paste0("\u2502", formatC(content, width = -inner, flag = "-"), "\u2502\n"))
      shown <- shown + 1
    }
    if(shown == 0) {
      cat(paste0("\u2502", formatC("  No missing values found.", width = -inner, flag = "-"), "\u2502\n"))
    }
    
    cat(paste0("\u251c", rule, "\u2524\n"))
    title3 <- "  Patients with Highest Missing %"
    cat(paste0("\u2502", formatC(title3, width = -inner, flag = "-"), "\u2502\n"))
    cat(paste0("\u251c", rule, "\u2524\n"))
    
    missing_by_row_pct <- sort(rowMeans(is.na(data)) * 100, decreasing = TRUE)
    shown2 <- 0
    for(i in seq_along(missing_by_row_pct)) {
      if(missing_by_row_pct[i] == 0) break
      if(shown2 >= 10) break
      pid     <- if(i <= length(patient_ids)) patient_ids[order(rowMeans(is.na(data)), decreasing = TRUE)[i]] else "Unknown"
      content <- sprintf("  %-28s %5.1f%%", pid, missing_by_row_pct[i])
      cat(paste0("\u2502", formatC(content, width = -inner, flag = "-"), "\u2502\n"))
      shown2 <- shown2 + 1
    }
    if(shown2 == 0) {
      cat(paste0("\u2502", formatC("  No rows with missing values.", width = -inner, flag = "-"), "\u2502\n"))
    }
    
    cat(paste0("\u2514", rule, "\u2518\n"))
  })
  
  
  
  # ========================================================================
  # SUBSECTION 3.5: DISTRIBUTION PLOTS MODULE
  # ========================================================================
  
  
  # ------------------------------------------------------------------------
  # PART 3.5.1: Distribution - Update UI inputs
  # ------------------------------------------------------------------------
  
  observe({
    data <- getData()
    num_vars <- names(data)[sapply(data, is.numeric)]
    all_vars <- names(data)
    
    updateSelectInput(session, "dist_var",
                      choices = all_vars,
                      selected = if (length(num_vars) > 0) num_vars[1] else all_vars[1])
  })
  
  # ------------------------------------------------------------------------
  # PART 3.5.2: Distribution - Render plot
  # ------------------------------------------------------------------------
  
  output$distribution_plot <- renderPlotly({
    req(input$dist_var)
    data <- getData()
    var  <- input$dist_var
    req(var %in% names(data))
    
    vals        <- data[[var]]
    patient_ids <- rownames(data)
    if (is.null(patient_ids)) patient_ids <- as.character(seq_len(nrow(data)))
    
    is_numeric_var <- is.numeric(vals)
    
    if (is_numeric_var) {
      plot_df <- data.frame(
        value   = as.numeric(vals),
        patient = patient_ids,
        stringsAsFactors = FALSE
      )
      plot_df <- plot_df[!is.na(plot_df$value), ]
      req(nrow(plot_df) > 0)
      
      p <- ggplot(plot_df, aes(x = value)) +
        geom_histogram(bins = input$dist_bins, fill = "#13D4D4", color = "white", alpha = 0.75) +
        geom_rug(aes(x = value), alpha = 0.4, colour = "#2C3E50", sides = "b") +
        labs(title = paste("Distribution of", gsub("_", " ", var)),
             x = gsub("_", " ", var), y = "Count") +
        theme_minimal() +
        theme(plot.title = element_text(hjust = 0.5, face = "bold", colour = "#2C3E50", size = 14))
      
      ggplotly(p) %>%
        layout(plot_bgcolor = "#f8f9fa", paper_bgcolor = "#ffffff", hovermode = "closest")
      
    } else {
      vals_chr <- as.character(vals)
      vals_chr[is.na(vals_chr)] <- "(Missing)"
      
      freq_df <- as.data.frame(table(vals_chr), stringsAsFactors = FALSE)
      names(freq_df) <- c("category", "count")
      freq_df$pct <- round(100 * freq_df$count / sum(freq_df$count), 1)
      freq_df <- freq_df[order(freq_df$count), ]
      freq_df$category <- factor(freq_df$category, levels = freq_df$category)
      
      p <- ggplot(freq_df, aes(x = category, y = count, fill = category)) +
        geom_bar(stat = "identity", alpha = 0.75, show.legend = FALSE) +
        coord_flip() +
        labs(title = paste("Bar Chart of", gsub("_", " ", var)), x = NULL, y = "Count") +
        theme_minimal() +
        theme(plot.title = element_text(hjust = 0.5, face = "bold", colour = "#2C3E50", size = 14))
      
      ggplotly(p) %>%
        layout(plot_bgcolor = "#f8f9fa", paper_bgcolor = "#ffffff", hovermode = "closest")
    }
  })
  
  # ------------------------------------------------------------------------
  # PART 3.5.3: Distribution statistics text
  # ------------------------------------------------------------------------
  
  output$distribution_stats <- renderPrint({
    req(input$dist_var)
    data <- getData()
    var  <- input$dist_var
    req(var %in% names(data))
    vals <- data[[var]]
    
    W     <- 57
    inner <- W - 2
    rule  <- paste(rep("\u2500", inner), collapse = "")
    
    cat(paste0("\u250c", rule, "\u2510\n"))
    title <- paste0("  DISTRIBUTION: ", toupper(gsub("_", " ", var)))
    cat(paste0("\u2502", formatC(title, width = -inner, flag = "-"), "\u2502\n"))
    cat(paste0("\u251c", rule, "\u2524\n"))
    
    row2 <- function(label, value) {
      content <- sprintf("  %-30s %s", label, as.character(value))
      cat(paste0("\u2502", formatC(content, width = -inner, flag = "-"), "\u2502\n"))
    }
    
    row2("Total observations:", length(vals))
    row2("Missing values:",     sum(is.na(vals)))
    row2("Complete cases:",     sum(!is.na(vals)))
    cat(paste0("\u251c", rule, "\u2524\n"))
    
    if(is.numeric(vals)) {
      v <- vals[!is.na(vals)]
      row2("Min:",    round(min(v),             4))
      row2("Q1:",     round(quantile(v, 0.25),  4))
      row2("Median:", round(median(v),          4))
      row2("Mean:",   round(mean(v),            4))
      row2("Q3:",     round(quantile(v, 0.75),  4))
      row2("Max:",    round(max(v),             4))
      row2("SD:",     round(sd(v),              4))
      row2("IQR:",    round(IQR(v),             4))
      cat(paste0("\u2514", rule, "\u2518\n"))
    } else {
      cat(paste0("\u2514", rule, "\u2518\n"))
      cat("\n")
      freq <- sort(table(as.character(vals), useNA = "no"), decreasing = TRUE)
      cat(paste(rep("\u2500", 47), collapse = ""), "\n")
      cat("  Frequency Table\n")
      cat(paste(rep("\u2500", 47), collapse = ""), "\n")
      cat(sprintf("  %-28s %6s   %6s\n", "Category", "Count", "Pct"))
      cat(paste(rep("\u2500", 47), collapse = ""), "\n")
      for(i in seq_len(min(20, length(freq)))) {
        pct <- round(100 * freq[i] / sum(freq), 1)
        cat(sprintf("  %-28s %6d   %5.1f%%\n", names(freq)[i], freq[i], pct))
      }
      if(length(freq) > 20)
        cat(sprintf("  ... and %d more levels\n", length(freq) - 20))
      cat(paste(rep("\u2500", 47), collapse = ""), "\n")
    }
  })
  
  # ------------------------------------------------------------------------
  # PART 3.5.4: Distribution reset
  # ------------------------------------------------------------------------
  
  observeEvent(input$reset_distribution, {
    data     <- getData()
    num_vars <- names(data)[sapply(data, is.numeric)]
    updateSliderInput(session, "dist_bins", value = 30)
    updateSelectInput(session, "dist_var",
                      selected = if (length(num_vars) > 0) num_vars[1] else names(data)[1])
  })
  
  
  
  # ========================================================================
  # SUBSECTION 3.6: SCATTER PLOT MODULE
  # ========================================================================
  
  
  # ------------------------------------------------------------------------
  # PART 3.6.1: Scatter - Update UI inputs
  # ------------------------------------------------------------------------
  
  observe({
    data <- getData()
    num_vars <- names(data)[sapply(data, is.numeric)]
    cat_vars <- names(data)[sapply(data, function(x) is.factor(x) | is.character(x))]
    
    updateSelectInput(session, "scatter_x",
                      choices = num_vars,
                      selected = if (length(num_vars) >= 1) num_vars[1] else NULL)
    
    updateSelectInput(session, "scatter_y",
                      choices = num_vars,
                      selected = if (length(num_vars) >= 2) num_vars[2] else num_vars[1])
    
    updateSelectInput(session, "scatter_color",
                      choices = c("None", cat_vars),
                      selected = "None")
  })
  
  # ------------------------------------------------------------------------
  # PART 3.6.2: Scatter - Render plot
  # ------------------------------------------------------------------------
  
  output$scatter_plot <- renderPlotly({
    req(input$scatter_x, input$scatter_y)
    data      <- getData()
    x_var     <- input$scatter_x
    y_var     <- input$scatter_y
    color_var <- input$scatter_color
    
    req(x_var %in% names(data), y_var %in% names(data))
    
    patient_ids <- rownames(data)
    if (is.null(patient_ids)) patient_ids <- as.character(seq_len(nrow(data)))
    
    x_vals <- as.numeric(data[[x_var]])
    y_vals <- as.numeric(data[[y_var]])
    
    plot_df <- data.frame(
      x       = x_vals,
      y       = y_vals,
      patient = patient_ids,
      stringsAsFactors = FALSE
    )
    
    has_colour <- (color_var != "None" && color_var %in% names(data))
    if (has_colour) {
      plot_df$colour <- as.factor(data[[color_var]])
    }
    
    # Drop rows missing x or y
    complete_idx <- !is.na(plot_df$x) & !is.na(plot_df$y)
    plot_df      <- plot_df[complete_idx, ]
    req(nrow(plot_df) > 0)
    
    # Build hover text
    plot_df$hover_text <- paste0(
      "<b>Patient:</b> ",                    plot_df$patient,
      "<br><b>", gsub("_", " ", x_var), ":</b> ", round(plot_df$x, 3),
      "<br><b>", gsub("_", " ", y_var), ":</b> ", round(plot_df$y, 3)
    )
    if (has_colour) {
      plot_df$hover_text <- paste0(
        plot_df$hover_text,
        "<br><b>", gsub("_", " ", color_var), ":</b> ", plot_df$colour
      )
    }
    
    # Build plotly directly
    if (has_colour) {
      p <- plot_ly(
        data       = plot_df,
        x          = ~x,
        y          = ~y,
        color      = ~colour,
        type       = "scatter",
        mode       = "markers",
        marker     = list(size = 8, opacity = 0.7),
        text       = ~hover_text,
        hoverinfo  = "text"
      )
    } else {
      p <- plot_ly(
        data      = plot_df,
        x         = ~x,
        y         = ~y,
        type      = "scatter",
        mode      = "markers",
        marker    = list(size = 8, opacity = 0.7, color = "#13D4D4"),
        text      = ~hover_text,
        hoverinfo = "text",
        name      = "Observations"
      )
    }
    
    # Optional smoothing line (lm only)
    if (isTRUE(input$scatter_smooth)) {
      lm_fit  <- lm(y ~ x, data = plot_df)
      x_seq   <- seq(min(plot_df$x, na.rm = TRUE), max(plot_df$x, na.rm = TRUE), length.out = 100)
      y_pred  <- predict(lm_fit, newdata = data.frame(x = x_seq), interval = "confidence")
      smooth_df <- data.frame(x = x_seq, fit = y_pred[, "fit"], lo = y_pred[, "lwr"], hi = y_pred[, "upr"])
      
      p <- p %>%
        add_ribbons(
          data        = smooth_df,
          x           = ~x, ymin = ~lo, ymax = ~hi,
          fillcolor   = "rgba(231,76,60,0.15)",
          line        = list(color = "transparent"),
          name        = "95% CI",
          hoverinfo   = "none",
          showlegend  = TRUE,
          inherit     = FALSE
        ) %>%
        add_lines(
          data       = smooth_df,
          x          = ~x, y = ~fit,
          line       = list(color = "#e74c3c", width = 2, dash = "dash"),
          name       = "Linear fit",
          hoverinfo  = "none",
          inherit    = FALSE
        )
    }
    
    p %>% layout(
      title = list(
        text = paste(gsub("_", " ", y_var), "vs", gsub("_", " ", x_var)),
        font = list(size = 16, color = "#2C3E50")
      ),
      xaxis = list(title = gsub("_", " ", x_var), gridcolor = "#e0e0e0"),
      yaxis = list(title = gsub("_", " ", y_var), gridcolor = "#e0e0e0"),
      plot_bgcolor  = "#f8f9fa",
      paper_bgcolor = "#ffffff",
      hovermode     = "closest",
      legend = list(orientation = "h", yanchor = "bottom", y = -0.15, xanchor = "center", x = 0.5)
    )
  })
  
  # ------------------------------------------------------------------------
  # PART 3.6.3: Scatter statistics
  # ------------------------------------------------------------------------
  
  output$scatter_stats <- renderPrint({
    req(input$scatter_x, input$scatter_y)
    data  <- getData()
    x_var <- input$scatter_x
    y_var <- input$scatter_y
    req(x_var %in% names(data), y_var %in% names(data))
    
    x            <- as.numeric(data[[x_var]])
    y            <- as.numeric(data[[y_var]])
    complete_idx <- complete.cases(x, y)
    xv           <- x[complete_idx]
    yv           <- y[complete_idx]
    
    W     <- 57
    inner <- W - 2
    rule  <- paste(rep("\u2500", inner), collapse = "")
    
    cat(paste0("\u250c", rule, "\u2510\n"))
    title <- "  SCATTER PLOT SUMMARY"
    cat(paste0("\u2502", formatC(title, width = -inner, flag = "-"), "\u2502\n"))
    cat(paste0("\u251c", rule, "\u2524\n"))
    
    row2 <- function(label, value) {
      content <- sprintf("  %-35s %s", label, as.character(value))
      cat(paste0("\u2502", formatC(content, width = -inner, flag = "-"), "\u2502\n"))
    }
    
    row2("X variable:",       gsub("_", " ", x_var))
    row2("Y variable:",       gsub("_", " ", y_var))
    if(input$scatter_color != "None")
      row2("Coloured by:", gsub("_", " ", input$scatter_color))
    row2("Complete cases:",   sum(complete_idx))
    row2("Excluded (missing):", length(x) - sum(complete_idx))
    
    if(sum(complete_idx) >= 3) {
      pear   <- cor(xv, yv, method = "pearson")
      spear  <- cor(xv, yv, method = "spearman")
      lm_fit <- lm(yv ~ xv)
      cf     <- coef(lm_fit)
      
      cat(paste0("\u251c", rule, "\u2524\n"))
      title2 <- "  Correlation"
      cat(paste0("\u2502", formatC(title2, width = -inner, flag = "-"), "\u2502\n"))
      cat(paste0("\u251c", rule, "\u2524\n"))
      row2("Pearson r:",    round(pear,   4))
      row2("Spearman rho:", round(spear,  4))
      row2("R-squared:",    round(pear^2, 4))
      
      cat(paste0("\u251c", rule, "\u2524\n"))
      title3 <- "  Linear Regression  (y ~ x)"
      cat(paste0("\u2502", formatC(title3, width = -inner, flag = "-"), "\u2502\n"))
      cat(paste0("\u251c", rule, "\u2524\n"))
      row2("Intercept:", round(cf[1], 4))
      row2("Slope:",     round(cf[2], 4))
    }
    
    cat(paste0("\u2514", rule, "\u2518\n"))
  })
  
  # ------------------------------------------------------------------------
  # PART 3.6.4: Scatter reset
  # ------------------------------------------------------------------------
  
  observeEvent(input$reset_scatter, {
    data     <- getData()
    num_vars <- names(data)[sapply(data, is.numeric)]
    updateSelectInput(session, "scatter_x",
                      selected = if (length(num_vars) >= 1) num_vars[1] else NULL)
    updateSelectInput(session, "scatter_y",
                      selected = if (length(num_vars) >= 2) num_vars[2] else num_vars[1])
    updateSelectInput(session, "scatter_color",  selected = "None")
    updateCheckboxInput(session, "scatter_smooth", value = FALSE)
  })
  
  
  
  # ========================================================================
  # SUBSECTION 3.7: GGPAIRS PLOT MODULE
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # PART 3.7.1: GGpairs - Update UI inputs
  # ------------------------------------------------------------------------
  
  observe({
    data <- getData()
    num_vars <- names(data)[sapply(data, is.numeric)]
    cat_vars <- names(data)[sapply(data, function(x) is.factor(x) | is.character(x))]
    
    updateSelectizeInput(session, "ggpairs_numeric",
                         choices = num_vars,
                         selected = num_vars[1:min(5, length(num_vars))])
    
    updateSelectInput(session, "ggpairs_color",
                      choices = c("None", cat_vars),
                      selected = "None")
  })
  
  # ------------------------------------------------------------------------
  # PART 3.7.2: GGpairs - Render plot
  # ------------------------------------------------------------------------
  
  output$ggpairs_plot <- renderPlotly({
    vars <- input$ggpairs_numeric
    req(length(vars) >= 2)
    
    # Guard: too many variables makes an unreadable / crashing plot
    if (length(vars) > 10) {
      return(
        plot_ly() %>%
          add_annotations(
            text = paste0("Too many variables selected (", length(vars), ").\n",
                          "Please choose 10 or fewer."),
            x = 0.5, y = 0.5, showarrow = FALSE,
            font = list(size = 14, color = "#e74c3c")
          ) %>%
          layout(xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
      )
    }
    
    data        <- getData()
    patient_ids <- rownames(data)
    if (is.null(patient_ids)) patient_ids <- as.character(seq_len(nrow(data)))
    
    valid_vars <- vars[vars %in% names(data)]
    req(length(valid_vars) >= 2)
    
    # Subset and coerce to numeric
    plot_df <- data[, valid_vars, drop = FALSE]
    for (col in names(plot_df)) {
      if (!is.numeric(plot_df[[col]]))
        plot_df[[col]] <- suppressWarnings(as.numeric(as.character(plot_df[[col]])))
    }
    
    # Drop incomplete rows
    keep        <- complete.cases(plot_df)
    plot_df     <- plot_df[keep, , drop = FALSE]
    patient_ids <- patient_ids[keep]
    
    if (nrow(plot_df) < 3) {
      return(
        plot_ly() %>%
          add_annotations(
            text = paste0("Only ", nrow(plot_df),
                          " complete cases found — need at least 3.\n",
                          "Try deselecting variables with heavy missingness."),
            x = 0.5, y = 0.5, showarrow = FALSE,
            font = list(size = 13, color = "#e74c3c")
          ) %>%
          layout(xaxis = list(visible = FALSE), yaxis = list(visible = FALSE))
      )
    }
    
    color_var  <- input$ggpairs_color
    color_vals <- NULL
    
    # Define a custom color palette for categorical variables
    custom_palette <- c("#13D4D4", "#e74c3c", "#2ecc71", "#f39c12", "#9b59b6", 
                        "#3498db", "#1abc9c", "#e67e22", "#2c3e50", "#c0392b",
                        "#16a085", "#27ae60", "#2980b9", "#8e44ad", "#f1c40f",
                        "#d35400", "#7f8c8d", "#34495e")
    
    if (color_var != "None" && color_var %in% names(data)) {
      color_vals <- as.factor(data[[color_var]][keep])
    }
    
    # Custom lower-panel scatter with patient IDs for hover
    make_lower_panel <- function(pid, colour_var = NULL, colour_values = NULL, colour_palette = custom_palette) {
      function(data, mapping, ...) {
        x_name <- rlang::as_name(mapping$x)
        y_name <- rlang::as_name(mapping$y)
        n      <- nrow(data)
        ids    <- pid[seq_len(n)]
        
        panel_df <- data.frame(
          px  = data[[x_name]],
          py  = data[[y_name]],
          pid = ids,
          stringsAsFactors = FALSE
        )
        
        # Add colour information if provided
        if (!is.null(colour_var) && !is.null(colour_values)) {
          panel_df$colour_group <- colour_values[seq_len(n)]
          panel_df$hover <- paste0(
            "<b>Patient:</b> ", panel_df$pid,
            "<br><b>", x_name, ":</b> ", round(panel_df$px, 3),
            "<br><b>", y_name, ":</b> ", round(panel_df$py, 3),
            "<br><b>", colour_var, ":</b> ", panel_df$colour_group
          )
          
          # Create plot with colours
          p <- ggplot(panel_df, aes(x = px, y = py, color = colour_group, text = hover)) +
            geom_point(size = 0.1, alpha = 0.7) +
            scale_color_manual(values = colour_palette, name = gsub("_", " ", colour_var)) +
            theme_minimal() +
            labs(x = x_name, y = y_name) +
            theme(legend.position = "none")
          
        } else {
          panel_df$hover <- paste0(
            "<b>Patient:</b> ", panel_df$pid,
            "<br><b>", x_name, ":</b> ", round(panel_df$px, 3),
            "<br><b>", y_name, ":</b> ", round(panel_df$py, 3)
          )
          
          # Create plot without colours
          p <- ggplot(panel_df, aes(x = px, y = py, text = hover)) +
            geom_point(size = 0.1, alpha = 0.6, colour = "#13D4D4") +
            theme_minimal() +
            labs(x = x_name, y = y_name)
        }
        
        return(p)
      }
    }
    
    # Create lower panel function with colouring support
    lower_fn <- make_lower_panel(patient_ids, color_var, color_vals, custom_palette)
    
    # Build ggpairs with appropriate colouring
    if (!is.null(color_vals)) {
      plot_df_c        <- plot_df
      plot_df_c$colour <- color_vals
      n_data_cols      <- ncol(plot_df_c) - 1
      
      # Custom upper panel to show correlation with colour
      make_upper_panel <- function(colour_var_name = NULL) {
        function(data, mapping, ...) {
          # Extract variable names
          x_name <- rlang::as_name(mapping$x)
          y_name <- rlang::as_name(mapping$y)
          
          # Calculate correlation
          cor_val <- cor(data[[x_name]], data[[y_name]], use = "complete.obs")
          cor_label <- round(cor_val, 2)
          
          # Create text for display
          if (!is.null(colour_var_name)) {
            label_text <- paste0("cor = ", cor_label, "\n(coloured by\n", gsub("_", " ", colour_var_name), ")")
          } else {
            label_text <- paste0("cor = ", cor_label)
          }
          
          # Create a simple plot with correlation text
          ggplot(data, aes(x = .data[[x_name]], y = .data[[y_name]])) +
            geom_blank() +
            annotate("text", x = mean(range(data[[x_name]], na.rm = TRUE)), 
                     y = mean(range(data[[y_name]], na.rm = TRUE)),
                     label = label_text, size = 4, fontface = "bold") +
            theme_void()
        }
      }
      
      ggp <- GGally::ggpairs(
        plot_df_c,
        columns  = seq_len(n_data_cols),
        mapping  = ggplot2::aes(colour = colour),
        title    = paste("GGpairs — coloured by", gsub("_", " ", color_var)),
        progress = FALSE,
        upper    = list(continuous = make_upper_panel(color_var)),
        lower    = list(continuous = GGally::wrap(lower_fn)),
        diag     = list(continuous = GGally::wrap("densityDiag", alpha = 0.6))
      )
      
      # Apply custom colour scale to the entire plot
      ggp <- ggp + scale_color_manual(values = custom_palette, name = gsub("_", " ", color_var))
      
    } else {
      ggp <- GGally::ggpairs(
        plot_df,
        columns  = seq_len(ncol(plot_df)),
        title    = "GGpairs Plot",
        progress = FALSE,
        upper    = list(continuous = GGally::wrap("cor", size = 0.1, colour = "black")),
        lower    = list(continuous = GGally::wrap(lower_fn)),
        diag     = list(continuous = GGally::wrap("densityDiag", alpha = 0.6, fill = "#13D4D4", colour = "white"))
      )
    }
    
    ggp <- ggp +
      theme_minimal() +
      theme(
        plot.title       = element_text(hjust = 0.5, face = "bold", colour = "#2C3E50", size = 14),
        strip.text       = element_text(face = "bold", size = 9),
        strip.background = element_rect(fill = "#ecf0f1", colour = NA)
      )
    
    # Convert to plotly with custom hover
    ggplotly(ggp, tooltip = "text", height = 800) %>%
      layout(
        plot_bgcolor  = "#f8f9fa",
        paper_bgcolor = "#ffffff",
        hoverlabel    = list(
          bgcolor = "white", 
          font = list(size = 10, family = "monospace", color = "black"),
          bordercolor = "#333",
          borderwidth = 1
        ),
        margin        = list(t = 80, l = 50, r = 50, b = 50)
      )
  })
  
  # ------------------------------------------------------------------------
  # PART 3.7.3: GGpairs summary
  # ------------------------------------------------------------------------
  
  output$ggpairs_summary <- renderPrint({
    vars <- input$ggpairs_numeric
    req(length(vars) >= 2)
    
    data       <- getData()
    valid_vars <- vars[vars %in% names(data)]
    plot_df    <- data[, valid_vars, drop = FALSE]
    
    for(col in names(plot_df)) {
      if(!is.numeric(plot_df[[col]]))
        plot_df[[col]] <- suppressWarnings(as.numeric(as.character(plot_df[[col]])))
    }
    
    n_complete <- sum(complete.cases(plot_df))
    
    W     <- 57
    inner <- W - 2
    rule  <- paste(rep("\u2500", inner), collapse = "")
    
    cat(paste0("\u250c", rule, "\u2510\n"))
    title <- "  GGPAIRS SUMMARY"
    cat(paste0("\u2502", formatC(title, width = -inner, flag = "-"), "\u2502\n"))
    cat(paste0("\u251c", rule, "\u2524\n"))
    
    row2 <- function(label, value) {
      content <- sprintf("  %-35s %s", label, as.character(value))
      cat(paste0("\u2502", formatC(content, width = -inner, flag = "-"), "\u2502\n"))
    }
    
    row2("Variables selected:",      length(valid_vars))
    row2("Complete cases used:",     n_complete)
    row2("Rows excluded (missing):", nrow(data) - n_complete)
    if(input$ggpairs_color != "None")
      row2("Coloured by:", gsub("_", " ", input$ggpairs_color))
    
    cat(paste0("\u251c", rule, "\u2524\n"))
    title2 <- "  Per-variable summary (complete cases only)"
    cat(paste0("\u2502", formatC(title2, width = -inner, flag = "-"), "\u2502\n"))
    cat(paste0("\u251c", rule, "\u2524\n"))
    
    complete_df <- plot_df[complete.cases(plot_df), , drop = FALSE]
    for(v in valid_vars) {
      vv      <- complete_df[[v]]
      content <- sprintf("  %-18s  mean=%8.3f  sd=%7.3f", gsub("_", " ", v), mean(vv), sd(vv))
      cat(paste0("\u2502", formatC(content, width = -inner, flag = "-"), "\u2502\n"))
      content2 <- sprintf("  %-18s  range=[%g, %g]", "", min(vv), max(vv))
      cat(paste0("\u2502", formatC(content2, width = -inner, flag = "-"), "\u2502\n"))
    }
    
    cat(paste0("\u2514", rule, "\u2518\n"))
  })
  
  # ------------------------------------------------------------------------
  # PART 3.7.4: GGpairs reset
  # ------------------------------------------------------------------------
  
  observeEvent(input$reset_ggpairs, {
    data <- isolate(getData())
    num_vars <- names(data)[sapply(data, is.numeric)]
    cat_vars <- names(data)[sapply(data, function(x) is.factor(x) | is.character(x))]
    
    updateSelectizeInput(session, "ggpairs_numeric",
                         choices = num_vars,
                         selected = num_vars[1:min(5, length(num_vars))])
    
    updateSelectInput(session, "ggpairs_color",
                      choices = c("None", cat_vars),
                      selected = "None")
    
    showNotification("GGpairs reset to default settings", type = "message", duration = 2)
  })
  
  
  
  # ========================================================================
  # SUBSECTION 3.8: RAW DATA TABLE MODULE
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # PART 3.8.1: Data table - Update picker inputs
  # ------------------------------------------------------------------------
  
  observe({
    data <- getData()
    all_vars <- names(data)
    numeric_vars <- names(data)[sapply(data, is.numeric)]
    categorical_vars <- names(data)[sapply(data, function(x) is.factor(x) | is.character(x))]
    
    # Update row range slider max
    updateSliderInput(session, "dt_row_range", max = nrow(data), value = c(1, min(969, nrow(data))))
    updateSelectizeInput(session, "dt_all_columns", choices = all_vars, selected = all_vars)
    updateSelectizeInput(session, "dt_numeric_columns", choices = numeric_vars, selected = numeric_vars)  # ALL numeric columns
    updateSelectizeInput(session, "dt_categorical_columns", choices = categorical_vars, selected = categorical_vars[1:min(3, length(categorical_vars))])
  })
  
  # ------------------------------------------------------------------------
  # PART 3.8.2: Data table - Column selection buttons
  # ------------------------------------------------------------------------
  
  observeEvent(input$dt_all_select_all, { updatePickerInput(session, "dt_all_columns", selected = names(getData())) })
  observeEvent(input$dt_all_deselect_all, { updatePickerInput(session, "dt_all_columns", selected = character(0)) })
  observeEvent(input$dt_num_select_all, { updatePickerInput(session, "dt_numeric_columns", selected = names(getData())[sapply(getData(), is.numeric)]) })
  observeEvent(input$dt_num_deselect_all, { updatePickerInput(session, "dt_numeric_columns", selected = character(0)) })
  observeEvent(input$dt_cat_select_all, { updatePickerInput(session, "dt_categorical_columns", selected = names(getData())[sapply(getData(), function(x) is.factor(x) | is.character(x))]) })
  observeEvent(input$dt_cat_deselect_all, { updatePickerInput(session, "dt_categorical_columns", selected = character(0)) })
  
  # ------------------------------------------------------------------------
  # PART 3.8.3: Data table - Dynamic column selection based on active tab
  # ------------------------------------------------------------------------
  
  selected_columns <- reactive({
    active_tab <- input$dt_column_tabs
    
    if(active_tab == "All Columns") {
      input$dt_all_columns
    } else if(active_tab == "Numeric Columns") {
      input$dt_numeric_columns
    } else if(active_tab == "Categorical Columns") {
      input$dt_categorical_columns
    } else {
      names(getData())
    }
  })
  
  # ------------------------------------------------------------------------
  # PART 3.8.4: Data table - Row range info output
  # ------------------------------------------------------------------------
  
  output$dt_row_info <- renderText({
    data <- getData_filtered()
    start_row <- input$dt_row_range[1]
    end_row <- min(input$dt_row_range[2], nrow(data))
    total_rows <- nrow(data)
    paste("Showing rows", start_row, "to", end_row, "of", total_rows, "total rows")
  })
  
  # ------------------------------------------------------------------------
  # PART 3.8.5: Data table - Filtered data reactive
  # ------------------------------------------------------------------------
  
  getData_filtered <- reactive({
    data <- getData()
    selected_cols <- selected_columns()
    selected_cols <- selected_cols[selected_cols %in% names(data)]
    if(length(selected_cols) == 0) {
      return(data.frame(Message = "No columns selected"))
    }
    
    start_row <- input$dt_row_range[1]
    end_row <- min(input$dt_row_range[2], nrow(data))
    
    data[start_row:end_row, selected_cols, drop = FALSE]
  })
  
  # ------------------------------------------------------------------------
  # PART 3.8.6: Data table - Render DT output
  # ------------------------------------------------------------------------
  
  output$raw_data_table <- DT::renderDT({
    data <- getData_filtered()
    
    datatable(data,
              extensions = c('Buttons', 'Scroller'),
              options = list(
                dom = 'Bfrtip',
                buttons = c('copy', 'csv', 'excel', 'pdf', 'print'),
                pageLength = if(input$dt_page_length == -1) nrow(data) else input$dt_page_length,
                scrollX = TRUE,
                scrollY = if(input$dt_page_length == -1) "600px" else "400px",
                scroller = if(input$dt_page_length == -1) TRUE else FALSE,
                deferRender = TRUE
              ),
              filter = 'top',
              rownames = TRUE,
              class = 'display compact stripe hover'
    ) %>%
      formatRound(columns = names(data)[sapply(data, is.numeric)], digits = 3)
  })
  
  # ------------------------------------------------------------------------
  # PART 3.8.7: Data table - Reset button observer
  # ------------------------------------------------------------------------
  
  observeEvent(input$reset_datatable, {
    data <- getData()
    all_vars <- names(data)
    numeric_vars <- names(data)[sapply(data, is.numeric)]
    categorical_vars <- names(data)[sapply(data, function(x) is.factor(x) | is.character(x))]
    
    # Reset row range
    updateSliderInput(session, "dt_row_range", min = 1, max = nrow(data), value = c(1, min(20, nrow(data))))
    
    # Reset page length
    updateSelectInput(session, "dt_page_length", selected = 25)
    
    # Reset column selections based on active tab
    active_tab <- input$dt_column_tabs
    if(active_tab == "All Columns") {
      updatePickerInput(session, "dt_all_columns", selected = all_vars)
    } else if(active_tab == "Numeric Columns") {
      updatePickerInput(session, "dt_numeric_columns", selected = numeric_vars)  # ALL numeric columns
    } else if(active_tab == "Categorical Columns") {
      updatePickerInput(session, "dt_categorical_columns", selected = categorical_vars)
    }
    
    showNotification("Data table reset to defaults", type = "message", duration = 2)
  })
  
  
  
  
  
  # ========================================================================
  # ========================================================================
  # SECTION 4: AVAILABLE METHODS TABLE
  # ========================================================================
  # ========================================================================
  
  getMethods <- reactive({
    mi <- caret::getModelInfo()
    Label <- Package <- Hyperparams <- Tags <- ClassProbs <- vector(mode = "character", length = length(mi))
    Regression <- Classification <- vector(mode = "logical", length = length(mi))
    
    for (row in 1:length(mi)) {
      Label[row] <- mi[[row]]$label
      libs <- na.omit(mi[[row]]$library[mi[[row]]$library != ""])
      if (length(libs) > 0) {
        present <- sapply(libs, require, warn.conflicts = FALSE, character.only = TRUE, quietly = TRUE)
        Package[row] <- paste(collapse = "<br/>", paste(mi[[row]]$library, ifelse(present, "", as.character(icon("ban")))))
      }
      d <- mi[[row]]$parameters
      Hyperparams[row] <- paste(collapse = "<br/>", paste0(d$parameter, " - ", d$label, " [", d$class,"]"))
      Regression[row] <- "Regression" %in% mi[[row]]$type
      Classification[row] <- "Classification" %in% mi[[row]]$type
      Tags[row] <- paste(collapse = "<br/>", mi[[row]]$tags)
      ClassProbs[row] <- ifelse(is.function(mi[[row]]$prob), as.character(icon("check-square")), "")
    }
    data.frame(Model = names(mi), Label, Package, Regression, Classification, Tags, Hyperparams, ClassProbs, stringsAsFactors = FALSE)
  })
  
  output$Available <- DT::renderDataTable({
    m <- getMethods()
    m <- m[m$Regression != "", !colnames(m) %in% c("Regression", "Classification", "ClassProbs")]
    DT::datatable(m, escape = FALSE, options = list(pageLength = 5, lengthMenu = c(5,10,15,-1)), rownames = FALSE, selection = "none")
  })
  
  
 
  
  
  # ========================================================================
  # ========================================================================
  # SECTION 5: MODEL TRAINING FAMILIES
  # ========================================================================
  # ========================================================================
  
  # ========================================================================
  # 5.0 RECIPE DEFINITIONS
  # ========================================================================
  
  # NULL Model Recipe
  getNullRecipe <- reactive({ 
    recipes::recipe(Response ~ ., data = getTrainData()) 
  })
  
  # Family 1: Linear Models
  getLmRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$lm_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getGlmnetRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$glmnet_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getRlmRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$rlm_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Family 2: PLS Models
  getPlsRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$pls_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getPcrRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$pcr_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Family 3: Tree Models
  getRpartRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$rpart_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getCubistRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$cubist_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Family 4: Random Forest
  getRangerRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$ranger_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getqrfRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$qrf_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Family 5: Gradient Boosting
  getbstTreeRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$bstTree_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getglmboostRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$glmboost_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getblackboostRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$blackboost_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Family 6: SVM
  getsvmRadialRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$svmRadial_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getsvmPolyRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$svmPoly_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getsvmLinearRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$svmLinear_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Family 7: Neural Networks
  getavNNetRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$avNNet_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getmlpWeightDecayMLRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$mlpWeightDecayML_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getbrnnRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$brnn_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getneuralnetRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$neuralnet_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Family 8: Gaussian Processes
  getgaussprRadialRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$gaussprRadial_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getgaussprPolyRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$gaussprPoly_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Family 9: GAM/MARS
  getearthRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$earth_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getgamRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$gam_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getpprRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$ppr_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Family 10: Bayesian
  getspikeslabRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$spikeslab_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getrvmRadialRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$rvmRadial_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Family 11: KNN
  getKknnRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$kknn_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Optimised Models
  getbrnn_optimRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$brnn_optim_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getgaussprPoly_optimRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$gaussprPoly_optim_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getsvmPoly_optimRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$svmPoly_optim_Preprocess) %>% step_rm(has_type("date"))
  })
  
  getsvmRadial_optimRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$svmRadial_optim_Preprocess) %>% step_rm(has_type("date"))
  })
  
  # Transparent Model
  getGlmnetInteractRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$glmnet_interact_Preprocess) %>%
      step_rm(has_type("date")) %>%
      step_interact(terms = ~ (all_numeric_predictors())^2) %>%
      step_zv(all_predictors()) %>%
      step_nzv(all_predictors())
  })
  
  
  # ========================================================================
  # 5.1 NULL MODEL (BASELINE)
  # ========================================================================
  
  observeEvent(input$null_Go, {
    method <- "null"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method, "model"), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getNullRecipe(), data = getTrainData(), method = method, metric = "RMSE", trControl = getTrControl())
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$null_Load, { 
    method <- "null"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$null_Delete, { models[["null"]] <- NULL; gc() })
  
  output$null_Metrics <- renderTable({ mod <- models[["null"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$null_RecipePrint <- renderUI({ mod <- models[["null"]]; req(mod); recipePrintHTML(mod) })
  output$null_RecipeOutput <- renderTable({ mod <- models[["null"]]; req(mod); recipeOutputTable(mod) })
  output$null_TrainSummary <- renderPrint({ mod <- models[["null"]]; req(mod); print(mod) })
  
  
  # ========================================================================
  # 5.2 FAMILY 1 - LINEAR MODELS (Models 01-03)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 01: lm - Linear Regression
  # ------------------------------------------------------------------------
  observeEvent(input$lm_Go, {
    method <- "lm"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getLmRecipe(), data = getTrainData(), method = method,
                            metric = "RMSE", trControl = getTrControl(), na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$lm_Load, { 
    method <- "lm"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$lm_Delete, { models[["lm"]] <- NULL; gc() })
  output$lm_Metrics <- renderTable({ mod <- models[["lm"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$lm_RecipePrint <- renderUI({ mod <- models[["lm"]]; req(mod); recipePrintHTML(mod) })
  output$lm_RecipeOutput <- renderTable({ mod <- models[["lm"]]; req(mod); recipeOutputTable(mod) })
  output$lm_TrainSummary <- renderPrint({ mod <- models[["lm"]]; req(mod); print(mod) })
  output$lm_Coef <- renderTable({ req(models$lm); co <- coef(models$lm$finalModel); as.data.frame(co, row.names = names(co)) }, rownames = TRUE, colnames = FALSE)
  output$lm_MethodSummary <- renderText({ description("lm") })
  
  
  # ------------------------------------------------------------------------
  # Model 02: glmnet - Elastic Net
  # ------------------------------------------------------------------------
  observeEvent(input$glmnet_Go, {
    method <- "glmnet"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getGlmnetRecipe(), data = getTrainData(), method = method,
                            metric = "RMSE", trControl = getTrControl(), tuneLength = 5, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$glmnet_Load, { 
    method <- "glmnet"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$glmnet_Delete, { models[["glmnet"]] <- NULL; gc() })
  output$glmnet_MethodSummary <- renderText({ description("glmnet") })
  output$glmnet_Metrics <- renderTable({ mod <- models[["glmnet"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$glmnet_ModelTune <- renderPlot({ mod <- models[["glmnet"]]; req(mod); plot(mod) })
  output$glmnet_RecipePrint <- renderUI({ mod <- models[["glmnet"]]; req(mod); recipePrintHTML(mod) })
  output$glmnet_RecipeOutput <- renderTable({ mod <- models[["glmnet"]]; req(mod); recipeOutputTable(mod) })
  output$glmnet_TrainSummary <- renderPrint({ mod <- models[["glmnet"]]; req(mod); print(mod) })
  output$glmnet_Coef <- renderTable({
    req(models$glmnet)
    co <- as.matrix(coef(models$glmnet$finalModel, s = models$glmnet$bestTune$lambda))
    df <- as.data.frame(co, row.names = rownames(co))
    df[df$s1 != 0, , drop = FALSE]
  }, rownames = TRUE, colnames = FALSE)
  
  
  # ------------------------------------------------------------------------
  # Model 03: rlm - Robust Linear Model
  # ------------------------------------------------------------------------
  observeEvent(input$rlm_Go, {
    method <- "rlm"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getRlmRecipe(), data = getTrainData(), method = method,
                            metric = "RMSE", trControl = getTrControl(), tuneLength = 5, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$rlm_Load, { 
    method <- "rlm"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$rlm_Delete, { models[["rlm"]] <- NULL; gc() })
  output$rlm_Metrics <- renderTable({ mod <- models[["rlm"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$rlm_ModelTune <- renderPlot({ mod <- models[["rlm"]]; req(mod); plot(mod) })
  output$rlm_RecipePrint <- renderUI({ mod <- models[["rlm"]]; req(mod); recipePrintHTML(mod) })
  output$rlm_RecipeOutput <- renderTable({ mod <- models[["rlm"]]; req(mod); recipeOutputTable(mod) })
  output$rlm_TrainSummary <- renderPrint({ mod <- models[["rlm"]]; req(mod); print(mod) })
  output$rlm_Coef <- renderTable({ req(models$rlm); co <- coef(models$rlm$finalModel); as.data.frame(co, row.names = names(co)) }, rownames = TRUE, colnames = FALSE)
  output$rlm_MethodSummary <- renderText({ description("rlm") })
  
  
  # ========================================================================
  # 5.3 FAMILY 2 - PLS MODELS (Models 04-05)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 04: pls - Partial Least Squares
  # ------------------------------------------------------------------------
  observeEvent(input$pls_Go, {
    method <- "pls"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getPlsRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), tuneLength = 25, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$pls_Load, { 
    method <- "pls"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$pls_Delete, { models[["pls"]] <- NULL; gc() })
  output$pls_MethodSummary <- renderText({ description("pls") })
  output$pls_Metrics <- renderTable({ mod <- models[["pls"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$pls_ModelTune <- renderPlot({ mod <- models[["pls"]]; req(mod); plot(mod) })
  output$pls_RecipePrint <- renderUI({ mod <- models[["pls"]]; req(mod); recipePrintHTML(mod) })
  output$pls_RecipeOutput <- renderTable({ mod <- models[["pls"]]; req(mod); recipeOutputTable(mod) })
  output$pls_TrainSummary <- renderPrint({ mod <- models[["pls"]]; req(mod); print(mod) })
  output$pls_Coef <- renderTable({ req(models$pls); co <- coef(models$pls$finalModel); as.data.frame(co, row.names = rownames(co)) }, rownames = TRUE, colnames = FALSE)
  
  
  # ------------------------------------------------------------------------
  # Model 05: pcr - Principal Component Regression
  # ------------------------------------------------------------------------
  observeEvent(input$pcr_Go, {
    method <- "pcr"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getPcrRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), tuneLength = 25, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$pcr_Load, { 
    method <- "pcr"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$pcr_Delete, { models[["pcr"]] <- NULL; gc() })
  output$pcr_MethodSummary <- renderText({ description("pcr") })
  output$pcr_Metrics <- renderTable({ mod <- models[["pcr"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$pcr_ModelTune <- renderPlot({ mod <- models[["pcr"]]; req(mod); plot(mod) })
  output$pcr_RecipePrint <- renderUI({ mod <- models[["pcr"]]; req(mod); recipePrintHTML(mod) })
  output$pcr_RecipeOutput <- renderTable({ mod <- models[["pcr"]]; req(mod); recipeOutputTable(mod) })
  output$pcr_TrainSummary <- renderPrint({ mod <- models[["pcr"]]; req(mod); print(mod) })
  output$pcr_Coef <- renderTable({ req(models$pcr); co <- coef(models$pcr$finalModel); as.data.frame(co, row.names = rownames(co)) }, rownames = TRUE, colnames = FALSE)
  
  
  # ========================================================================
  # 5.4 FAMILY 3 - TREE MODELS (Models 06-07)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 06: rpart - CART Decision Tree
  # ------------------------------------------------------------------------
  observeEvent(input$rpart_Go, {
    method <- "rpart"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getRpartRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), tuneLength = 5, na.action = na.rpart)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$rpart_Load, { 
    method <- "rpart"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$rpart_Delete, { models[["rpart"]] <- NULL; gc() })
  output$rpart_MethodSummary <- renderText({ description("rpart") })
  output$rpart_Metrics <- renderTable({ mod <- models[["rpart"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$rpart_ModelTune <- renderPlot({ mod <- models[["rpart"]]; req(mod); plot(mod) })
  output$rpart_ModelTree <- renderPlot({ mod <- models[["rpart"]]; req(mod); rpart.plot::rpart.plot(mod$finalModel, roundint = FALSE) })
  output$rpart_RecipePrint <- renderUI({ mod <- models[["rpart"]]; req(mod); recipePrintHTML(mod) })
  output$rpart_RecipeOutput <- renderTable({ mod <- models[["rpart"]]; req(mod); recipeOutputTable(mod) })
  output$rpart_TrainSummary <- renderPrint({ mod <- models[["rpart"]]; req(mod); print(mod) })
  
  
  # ------------------------------------------------------------------------
  # Model 07: cubist - Rule-Based Model
  # ------------------------------------------------------------------------
  observeEvent(input$cubist_Go, {
    method <- "cubist"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getCubistRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), na.action = na.pass, tuneLength = 5)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$cubist_Load, { 
    method <- "cubist"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$cubist_Delete, { models[["cubist"]] <- NULL; gc() })
  output$cubist_Metrics <- renderTable({ mod <- models[["cubist"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$cubist_ModelTune <- renderPlot({ mod <- models[["cubist"]]; req(mod); plot(mod) })
  output$cubist_RecipePrint <- renderUI({ mod <- models[["cubist"]]; req(mod); recipePrintHTML(mod) })
  output$cubist_RecipeOutput <- renderTable({ mod <- models[["cubist"]]; req(mod); recipeOutputTable(mod) })
  output$cubist_TrainSummary <- renderPrint({ mod <- models[["cubist"]]; req(mod); print(mod) })
  output$cubist_MethodSummary <- renderText({ description("cubist") })
  
  
  # ========================================================================
  # 5.5 FAMILY 4 - RANDOM FOREST MODELS (Models 08-09)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 08: ranger - Random Forest
  # ------------------------------------------------------------------------
  observeEvent(input$ranger_Go, {
    method <- "ranger"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getRangerRecipe(), data = getTrainData(), method = method,
                            metric = "RMSE", trControl = getTrControl(),
                            tuneLength = 5, num.trees = 500, importance = "permutation")
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, error = function(e) {
      showNotification(paste("ranger error:", e$message), session = session, type = "error", duration = 15)
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$ranger_Load, { 
    method <- "ranger"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$ranger_Delete, { models[["ranger"]] <- NULL; gc() })
  
  output$ranger_Metrics <- renderTable({ mod <- models[["ranger"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$ranger_ModelTune <- renderPlot({ mod <- models[["ranger"]]; req(mod); plot(mod) })
  output$ranger_VarImp <- renderPlot({ mod <- models[["ranger"]]; req(mod); importance <- varImp(mod, scale = TRUE); plot(importance, main = "ranger Variable Importance") })
  output$ranger_RecipePrint <- renderUI({ mod <- models[["ranger"]]; req(mod); recipePrintHTML(mod) })
  output$ranger_RecipeOutput <- renderTable({ mod <- models[["ranger"]]; req(mod); recipeOutputTable(mod) })
  output$ranger_TrainSummary <- renderPrint({ mod <- models[["ranger"]]; req(mod); print(mod) })
  output$ranger_MethodSummary <- renderText({ description("ranger") })
  
  
  # ------------------------------------------------------------------------
  # Model 09: qrf - Quantile Random Forest
  # ------------------------------------------------------------------------
  observeEvent(input$qrf_Go, {
    method <- "qrf"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      if (!requireNamespace("quantregForest", quietly = TRUE)) install.packages("quantregForest")
      model <- caret::train(getqrfRecipe(), data = getTrainData(), method = method,
                            metric = "RMSE", trControl = getTrControl(), tuneLength = 5)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, error = function(e) {
      showNotification(paste("qrf error:", e$message), session = session, type = "error", duration = 15)
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$qrf_Load, { 
    method <- "qrf"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$qrf_Delete, { models[["qrf"]] <- NULL; gc() })
  
  output$qrf_Metrics <- renderTable({ mod <- models[["qrf"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$qrf_ModelTune <- renderPlot({ mod <- models[["qrf"]]; req(mod); plot(mod) })
  output$qrf_RecipePrint <- renderUI({ mod <- models[["qrf"]]; req(mod); recipePrintHTML(mod) })
  output$qrf_RecipeOutput <- renderTable({ mod <- models[["qrf"]]; req(mod); recipeOutputTable(mod) })
  output$qrf_TrainSummary <- renderPrint({ mod <- models[["qrf"]]; req(mod); print(mod) })
  output$qrf_MethodSummary <- renderText({ description("qrf") })
  
  
  # ========================================================================
  # 5.6 FAMILY 5 - GRADIENT BOOSTING MODELS (Models 10-12)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 10: bstTree - Boosted Trees
  # ------------------------------------------------------------------------
  observeEvent(input$bstTree_Go, {
    method <- "bstTree"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      tuneGrid_bstTree <- expand.grid(mstop = c(50, 100, 200), maxdepth = c(1, 2, 3), nu = 0.1)
      model <- caret::train(getbstTreeRecipe(), data = getTrainData(), method = method,
                            metric = "RMSE", trControl = getTrControl(),
                            tuneGrid = tuneGrid_bstTree)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, error = function(e) {
      showNotification(paste("bstTree error:", e$message), session = session, type = "error", duration = 15)
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$bstTree_Load, { 
    method <- "bstTree"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$bstTree_Delete, { models[["bstTree"]] <- NULL; gc() })
  
  output$bstTree_Metrics <- renderTable({ mod <- models[["bstTree"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$bstTree_ModelTune <- renderPlot({ mod <- models[["bstTree"]]; req(mod); plot(mod) })
  output$bstTree_RecipePrint <- renderUI({ mod <- models[["bstTree"]]; req(mod); recipePrintHTML(mod) })
  output$bstTree_RecipeOutput <- renderTable({ mod <- models[["bstTree"]]; req(mod); recipeOutputTable(mod) })
  output$bstTree_TrainSummary <- renderPrint({ mod <- models[["bstTree"]]; req(mod); print(mod) })
  output$bstTree_MethodSummary <- renderText({ description("bstTree") })
  
  
  # ------------------------------------------------------------------------
  # Model 11: glmboost - Boosted Linear Models
  # ------------------------------------------------------------------------

  getglmboostRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$glmboost_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$glmboost_Go, {
    method <- "glmboost"
    models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method, "model..."), session = session, duration = NULL)
    obj <- startMode(FALSE)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      tuneGrid_glmboost <- expand.grid(mstop = c(50, 100, 200, 500), prune = "no")
      model <- caret::train(getglmboostRecipe(), data = getTrainData(), method = "glmboost", metric = "RMSE",
                            trControl = getTrControl(), tuneGrid = tuneGrid_glmboost, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
      showNotification(paste(method, "completed!"), session = session, type = "message")
    }, error = function(e) { 
      showNotification(paste("glmboost error:", e$message), session = session, type = "error", duration = 15) 
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$glmboost_Load, { 
    method <- "glmboost"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$glmboost_Delete, { method <- "glmboost"; models[[method]] <- NULL; gc() })
  output$glmboost_MethodSummary <- renderText({ description("glmboost") })
  output$glmboost_Metrics <- renderTable({ mod <- models[["glmboost"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$glmboost_ModelTune <- renderPlot({ mod <- models[["glmboost"]]; req(mod); plot(mod) })
  output$glmboost_RecipePrint <- renderUI({ mod <- models[["glmboost"]]; req(mod); recipePrintHTML(mod) })
  output$glmboost_RecipeOutput <- renderTable({ mod <- models[["glmboost"]]; req(mod); recipeOutputTable(mod) })
  output$glmboost_TrainSummary <- renderPrint({ mod <- models[["glmboost"]]; req(mod); print(mod) })
  output$glmboost_Coef <- renderTable({ req(models$glmboost); if(!is.null(models$glmboost$finalModel)) { co <- coef(models$glmboost$finalModel); as.data.frame(co, row.names = names(co)) } else data.frame(Message = "Coefficients not available") }, rownames = TRUE, colnames = FALSE)
  
  
  # ------------------------------------------------------------------------
  # Model 12: blackboost - Black Box Boosting
  # ------------------------------------------------------------------------
  getblackboostRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$blackboost_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$blackboost_Go, {
    method <- "blackboost"
    models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method, "model..."), session = session, duration = NULL)
    obj <- startMode(FALSE)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      tuneGrid_blackboost <- expand.grid(mstop = c(50, 100, 200), maxdepth = c(1, 2, 3))
      model <- caret::train(getblackboostRecipe(), data = getTrainData(), method = "blackboost", metric = "RMSE",
                            trControl = getTrControl(), tuneGrid = tuneGrid_blackboost, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
      showNotification(paste(method, "completed!"), session = session, type = "message")
    }, error = function(e) { 
      showNotification(paste("blackboost error:", e$message), session = session, type = "error", duration = 15) 
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$blackboost_Load, { 
    method <- "blackboost"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$blackboost_Delete, { method <- "blackboost"; models[[method]] <- NULL; gc() })
  output$blackboost_MethodSummary <- renderText({ description("blackboost") })
  output$blackboost_Metrics <- renderTable({ mod <- models[["blackboost"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$blackboost_ModelTune <- renderPlot({ mod <- models[["blackboost"]]; req(mod); plot(mod) })
  output$blackboost_RecipePrint <- renderUI({ mod <- models[["blackboost"]]; req(mod); recipePrintHTML(mod) })
  output$blackboost_RecipeOutput <- renderTable({ mod <- models[["blackboost"]]; req(mod); recipeOutputTable(mod) })
  output$blackboost_TrainSummary <- renderPrint({ mod <- models[["blackboost"]]; req(mod); print(mod) })
  output$blackboost_VarImp <- renderPlot({ mod <- models[["blackboost"]]; req(mod); tryCatch({ importance <- varImp(mod, scale = TRUE); plot(importance, main = "blackboost Variable Importance") }, error = function(e) { plot.new(); text(0.5, 0.5, "Variable importance not available", cex = 0.8) }) })
  
  
  # ========================================================================
  # 5.7 FAMILY 6 - SVM MODELS (Models 13-15)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 13: svmRadial - SVM with RBF Kernel
  # ------------------------------------------------------------------------
  getsvmRadialRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$svmRadial_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$svmRadial_Go, {
    method <- "svmRadial"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getsvmRadialRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), na.action = na.pass, tuneLength = 5)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$svmRadial_Load, { 
    method <- "svmRadial"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$svmRadial_Delete, { models[["svmRadial"]] <- NULL; gc() })
  output$svmRadial_Metrics <- renderTable({ mod <- models[["svmRadial"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$svmRadial_ModelTune <- renderPlot({ mod <- models[["svmRadial"]]; req(mod); plot(mod) })
  output$svmRadial_RecipePrint <- renderUI({ mod <- models[["svmRadial"]]; req(mod); recipePrintHTML(mod) })
  output$svmRadial_RecipeOutput <- renderTable({ mod <- models[["svmRadial"]]; req(mod); recipeOutputTable(mod) })
  output$svmRadial_TrainSummary <- renderPrint({ mod <- models[["svmRadial"]]; req(mod); print(mod) })
  output$svmRadial_MethodSummary <- renderText({ description("svmRadial") })
  
  
  # ------------------------------------------------------------------------
  # Model 14: svmPoly - SVM with Polynomial Kernel
  # ------------------------------------------------------------------------
  getsvmPolyRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$svmPoly_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$svmPoly_Go, {
    method <- "svmPoly"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getsvmPolyRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), na.action = na.pass, tuneLength = 3)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$svmPoly_Load, { 
    method <- "svmPoly"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$svmPoly_Delete, { models[["svmPoly"]] <- NULL; gc() })
  output$svmPoly_Metrics <- renderTable({ mod <- models[["svmPoly"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$svmPoly_ModelTune <- renderPlot({
    mod <- models[["svmPoly"]]
    req(mod)
    old_digits <- options("digits")
    options(digits = 4)
    on.exit(options(old_digits), add = TRUE)
    tryCatch({
      plot(mod)
    }, error = function(e) {
      if(!is.null(mod$results) && nrow(mod$results) > 0) {
        results <- mod$results
        rmse_col <- which(names(results) == "RMSE")[1]
        if(!is.na(rmse_col)) {
          plot(seq_len(nrow(results)), results[[rmse_col]], 
               type = "b", xlab = "Tuning combination", ylab = "RMSE",
               main = "Hyperparameter Tuning Results")
          points(which.min(results[[rmse_col]]), min(results[[rmse_col]], na.rm = TRUE), 
                 col = "red", pch = 16, cex = 1.5)
        } else {
          plot.new()
          text(0.5, 0.5, "Cannot display tuning plot", cex = 0.8)
        }
      } else {
        plot.new()
        text(0.5, 0.5, "No tuning results available", cex = 0.8)
      }
    })
  })
  output$svmPoly_RecipePrint <- renderUI({ mod <- models[["svmPoly"]]; req(mod); recipePrintHTML(mod) })
  output$svmPoly_RecipeOutput <- renderTable({ mod <- models[["svmPoly"]]; req(mod); recipeOutputTable(mod) })
  output$svmPoly_TrainSummary <- renderPrint({ mod <- models[["svmPoly"]]; req(mod); print(mod) })
  output$svmPoly_MethodSummary <- renderText({ description("svmPoly") })
  
  
  # ------------------------------------------------------------------------
  # Model 15: svmLinear - SVM with Linear Kernel
  # ------------------------------------------------------------------------
  getsvmLinearRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$svmLinear_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$svmLinear_Go, {
    method <- "svmLinear"
    models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method, "model..."), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      tuneGrid_svmLinear <- expand.grid(C = c(0.01, 0.1, 1, 5, 10))
      model <- caret::train(getsvmLinearRecipe(), data = getTrainData(), method = "svmLinear", metric = "RMSE",
                            trControl = getTrControl(), tuneGrid = tuneGrid_svmLinear, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
      showNotification(paste(method, "completed!"), session = session, type = "message")
    }, error = function(e) { 
      showNotification(paste("svmLinear error:", e$message), session = session, type = "error", duration = 15) 
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$svmLinear_Load, { 
    method <- "svmLinear"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$svmLinear_Delete, { method <- "svmLinear"; models[[method]] <- NULL; gc() })
  output$svmLinear_MethodSummary <- renderText({ description("svmLinear") })
  output$svmLinear_Metrics <- renderTable({ mod <- models[["svmLinear"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$svmLinear_ModelTune <- renderPlot({ mod <- models[["svmLinear"]]; req(mod); plot(mod) })
  output$svmLinear_RecipePrint <- renderUI({ mod <- models[["svmLinear"]]; req(mod); recipePrintHTML(mod) })
  output$svmLinear_RecipeOutput <- renderTable({ mod <- models[["svmLinear"]]; req(mod); recipeOutputTable(mod) })
  output$svmLinear_TrainSummary <- renderPrint({ mod <- models[["svmLinear"]]; req(mod); print(mod) })
  output$svmLinear_BestTune <- renderTable({ mod <- models[["svmLinear"]]; req(mod); as.data.frame(mod$bestTune) }, rownames = FALSE)
  
  
  # ========================================================================
  # 5.8 FAMILY 7 - NEURAL NETWORK MODELS (Models 16-19)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 16: avNNet - Model Averaged Neural Network
  # ------------------------------------------------------------------------
  getavNNetRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$avNNet_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$avNNet_Go, {
    method <- "avNNet"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getavNNetRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), na.action = na.pass, tuneLength = 5)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$avNNet_Load, { 
    method <- "avNNet"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$avNNet_Delete, { models[["avNNet"]] <- NULL; gc() })
  output$avNNet_Metrics <- renderTable({ mod <- models[["avNNet"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$avNNet_ModelTune <- renderPlot({ mod <- models[["avNNet"]]; req(mod); plot(mod) })
  output$avNNet_RecipePrint <- renderUI({ mod <- models[["avNNet"]]; req(mod); recipePrintHTML(mod) })
  output$avNNet_RecipeOutput <- renderTable({ mod <- models[["avNNet"]]; req(mod); recipeOutputTable(mod) })
  output$avNNet_TrainSummary <- renderPrint({ mod <- models[["avNNet"]]; req(mod); print(mod) })
  output$avNNet_MethodSummary <- renderText({ description("avNNet") })
  
  
  # ------------------------------------------------------------------------
  # Model 17: mlpWeightDecayML - Multi-Layer Perceptron
  # ------------------------------------------------------------------------
  getmlpWeightDecayMLRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$mlpWeightDecayML_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$mlpWeightDecayML_Go, {
    method <- "mlpWeightDecayML"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getmlpWeightDecayMLRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), na.action = na.pass, tuneLength = 5)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$mlpWeightDecayML_Load, { 
    method <- "mlpWeightDecayML"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$mlpWeightDecayML_Delete, { models[["mlpWeightDecayML"]] <- NULL; gc() })
  output$mlpWeightDecayML_Metrics <- renderTable({ mod <- models[["mlpWeightDecayML"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$mlpWeightDecayML_ModelTune <- renderPlot({ mod <- models[["mlpWeightDecayML"]]; req(mod); plot(mod) })
  output$mlpWeightDecayML_RecipePrint <- renderUI({ mod <- models[["mlpWeightDecayML"]]; req(mod); recipePrintHTML(mod) })
  output$mlpWeightDecayML_RecipeOutput <- renderTable({ mod <- models[["mlpWeightDecayML"]]; req(mod); recipeOutputTable(mod) })
  output$mlpWeightDecayML_TrainSummary <- renderPrint({ mod <- models[["mlpWeightDecayML"]]; req(mod); print(mod) })
  output$mlpWeightDecayML_MethodSummary <- renderText({ description("mlpWeightDecayML") })
  
  
  # ------------------------------------------------------------------------
  # Model 18: brnn - Bayesian Regularized Neural Network
  # ------------------------------------------------------------------------
  getbrnnRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$brnn_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$brnn_Go, {
    method <- "brnn"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getbrnnRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), na.action = na.pass, tuneLength = 5)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$brnn_Load, { 
    method <- "brnn"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$brnn_Delete, { models[["brnn"]] <- NULL; gc() })
  output$brnn_Metrics <- renderTable({ mod <- models[["brnn"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$brnn_ModelTune <- renderPlot({ mod <- models[["brnn"]]; req(mod); plot(mod) })
  output$brnn_RecipePrint <- renderUI({ mod <- models[["brnn"]]; req(mod); recipePrintHTML(mod) })
  output$brnn_RecipeOutput <- renderTable({ mod <- models[["brnn"]]; req(mod); recipeOutputTable(mod) })
  output$brnn_TrainSummary <- renderPrint({ mod <- models[["brnn"]]; req(mod); print(mod) })
  output$brnn_MethodSummary <- renderText({ description("brnn") })
  
  
  # ------------------------------------------------------------------------
  # Model 19: neuralnet - Neural Network with Backpropagation
  # ------------------------------------------------------------------------

  getneuralnetRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$neuralnet_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$neuralnet_Go, {
    method <- "neuralnet"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      tuneGrid_neuralnet <- expand.grid(layer1 = c(3, 5, 7), layer2 = c(0, 3), layer3 = 0)
      model <- caret::train(getneuralnetRecipe(), data = getTrainData(), method = method,
                            metric = "RMSE", trControl = getTrControl(),
                            tuneGrid = tuneGrid_neuralnet,
                            linear.output = TRUE, threshold = 0.01, stepmax = 1e5, rep = 1)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, error = function(e) {
      showNotification(paste("neuralnet error:", e$message), session = session, type = "error", duration = 15)
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$neuralnet_Load, { 
    method <- "neuralnet"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$neuralnet_Delete, { models[["neuralnet"]] <- NULL; gc() })
  output$neuralnet_Metrics <- renderTable({ mod <- models[["neuralnet"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$neuralnet_ModelTune <- renderPlot({ mod <- models[["neuralnet"]]; req(mod); plot(mod) })
  output$neuralnet_RecipePrint <- renderUI({ mod <- models[["neuralnet"]]; req(mod); recipePrintHTML(mod) })
  output$neuralnet_RecipeOutput <- renderTable({ mod <- models[["neuralnet"]]; req(mod); recipeOutputTable(mod) })
  output$neuralnet_TrainSummary <- renderPrint({ mod <- models[["neuralnet"]]; req(mod); print(mod) })
  output$neuralnet_MethodSummary <- renderText({ description("neuralnet") })
  
  
  # ========================================================================
  # 5.9 FAMILY 8 - GAUSSIAN PROCESS MODELS (Models 20-22)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 20: gaussprRadial - Gaussian Process with RBF Kernel
  # ------------------------------------------------------------------------
  getgaussprRadialRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$gaussprRadial_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$gaussprRadial_Go, {
    method <- "gaussprRadial"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      tuneGrid_gausspr <- expand.grid(sigma = c(0.01, 0.05, 0.1, 0.5, 1))
      model <- caret::train(getgaussprRadialRecipe(), data = getTrainData(), method = "gaussprRadial",
                            metric = "RMSE", trControl = getTrControl(), tuneGrid = tuneGrid_gausspr, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$gaussprRadial_Load, { 
    method <- "gaussprRadial"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$gaussprRadial_Delete, { models[["gaussprRadial"]] <- NULL; gc() })
  output$gaussprRadial_Metrics <- renderTable({ mod <- models[["gaussprRadial"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$gaussprRadial_ModelTune <- renderPlot({ mod <- models[["gaussprRadial"]]; req(mod); plot(mod) })
  output$gaussprRadial_RecipePrint <- renderUI({ mod <- models[["gaussprRadial"]]; req(mod); recipePrintHTML(mod) })
  output$gaussprRadial_RecipeOutput <- renderTable({ mod <- models[["gaussprRadial"]]; req(mod); recipeOutputTable(mod) })
  output$gaussprRadial_TrainSummary <- renderPrint({ mod <- models[["gaussprRadial"]]; req(mod); print(mod) })
  output$gaussprRadial_MethodSummary <- renderText({ description("gaussprRadial") })
  
  
  # ------------------------------------------------------------------------
  # Model 21: gaussprPoly - Gaussian Process with Polynomial Kernel
  # ------------------------------------------------------------------------
  getgaussprPolyRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$gaussprPoly_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$gaussprPoly_Go, {
    method <- "gaussprPoly"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getgaussprPolyRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), na.action = na.pass, tuneLength = 5)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
      showNotification(paste(method, "completed!"), session = session, type = "message")
    }, error = function(e) { 
      showNotification(paste("gaussprPoly error:", e$message), session = session, type = "error", duration = 15) 
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$gaussprPoly_Load, { 
    method <- "gaussprPoly"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$gaussprPoly_Delete, { models[["gaussprPoly"]] <- NULL; gc() })
  output$gaussprPoly_MethodSummary <- renderText({ description("gaussprPoly") })
  output$gaussprPoly_Metrics <- renderTable({ mod <- models[["gaussprPoly"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$gaussprPoly_ModelTune <- renderPlot({ mod <- models[["gaussprPoly"]]; req(mod); if(nrow(mod$results) > 1) plot(mod) else { plot.new(); text(0.5, 0.5, "Only one tuning combination tested", cex = 0.8) } })
  output$gaussprPoly_RecipePrint <- renderUI({ mod <- models[["gaussprPoly"]]; req(mod); recipePrintHTML(mod) })
  output$gaussprPoly_RecipeOutput <- renderTable({ mod <- models[["gaussprPoly"]]; req(mod); recipeOutputTable(mod) })
  output$gaussprPoly_TrainSummary <- renderPrint({ mod <- models[["gaussprPoly"]]; req(mod); print(mod) })
  
  
  # ========================================================================
  # 5.10 FAMILY 9 - GAM / MARS MODELS (Models 22-24)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 22: earth - MARS
  # ------------------------------------------------------------------------
  getearthRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$earth_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$earth_Go, {
    method <- "earth"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      tuneGrid_earth <- expand.grid(degree = c(1, 2), nprune = c(5, 10, 15, 20))
      model <- caret::train(getearthRecipe(), data = getTrainData(), method = method,
                            metric = "RMSE", trControl = getTrControl(), tuneGrid = tuneGrid_earth)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, error = function(e) {
      showNotification(paste("earth error:", e$message), session = session, type = "error", duration = 15)
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$earth_Load, { 
    method <- "earth"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$earth_Delete, { models[["earth"]] <- NULL; gc() })
  output$earth_Metrics <- renderTable({ mod <- models[["earth"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$earth_ModelTune <- renderPlot({ mod <- models[["earth"]]; req(mod); plot(mod) })
  output$earth_RecipePrint <- renderUI({ mod <- models[["earth"]]; req(mod); recipePrintHTML(mod) })
  output$earth_RecipeOutput <- renderTable({ mod <- models[["earth"]]; req(mod); recipeOutputTable(mod) })
  output$earth_TrainSummary <- renderPrint({ mod <- models[["earth"]]; req(mod); print(mod) })
  output$earth_MethodSummary <- renderText({ description("earth") })
  
  
  # ------------------------------------------------------------------------
  # Model 23: gam - GAM with Splines
  # ------------------------------------------------------------------------
  getgamRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$gam_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$gam_Go, {
    method <- "gam"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      tuneGrid_gam <- expand.grid(select = c(TRUE, FALSE), method = "GCV.Cp")
      model <- caret::train(getgamRecipe(), data = getTrainData(), method = method,
                            metric = "RMSE", trControl = getTrControl(),
                            tuneGrid = tuneGrid_gam, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, error = function(e) {
      showNotification(paste("gam error:", e$message), session = session, type = "error", duration = 15)
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$gam_Load, { 
    method <- "gam"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$gam_Delete, { models[["gam"]] <- NULL; gc() })
  output$gam_Metrics <- renderTable({ mod <- models[["gam"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$gam_ModelTune <- renderPlot({ mod <- models[["gam"]]; req(mod); plot(mod) })
  output$gam_RecipePrint <- renderUI({ mod <- models[["gam"]]; req(mod); recipePrintHTML(mod) })
  output$gam_RecipeOutput <- renderTable({ mod <- models[["gam"]]; req(mod); recipeOutputTable(mod) })
  output$gam_TrainSummary <- renderPrint({ mod <- models[["gam"]]; req(mod); print(mod) })
  output$gam_MethodSummary <- renderText({ description("gam") })
  
  
  # ------------------------------------------------------------------------
  # Model 24: ppr - Projection Pursuit Regression
  # ------------------------------------------------------------------------
  getpprRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$ppr_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$ppr_Go, {
    method <- "ppr"
    models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method, "model..."), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      tuneGrid_ppr <- expand.grid(nterms = c(1, 2, 3, 4, 5, 6, 8, 10))
      model <- caret::train(getpprRecipe(), data = getTrainData(), method = "ppr", metric = "RMSE",
                            trControl = getTrControl(), tuneGrid = tuneGrid_ppr, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
      showNotification(paste(method, "completed!"), session = session, type = "message")
    }, error = function(e) {
      showNotification(paste("ppr error:", e$message), session = session, type = "error", duration = 15)
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$ppr_Load, { 
    method <- "ppr"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$ppr_Delete, { method <- "ppr"; models[[method]] <- NULL; gc() })
  output$ppr_MethodSummary <- renderText({ description("ppr") })
  output$ppr_Metrics <- renderTable({ mod <- models[["ppr"]]; req(mod); mod$results[which.min(mod$results[, "RMSE"]), ] })
  output$ppr_ModelTune <- renderPlot({ mod <- models[["ppr"]]; req(mod); plot(mod) })
  output$ppr_RecipePrint <- renderUI({ mod <- models[["ppr"]]; req(mod); recipePrintHTML(mod) })
  output$ppr_RecipeOutput <- renderTable({ mod <- models[["ppr"]]; req(mod); recipeOutputTable(mod) })
  output$ppr_TrainSummary <- renderPrint({ mod <- models[["ppr"]]; req(mod); print(mod) })
  output$ppr_Coef <- renderTable({ req(models$ppr); if(!is.null(models$ppr$bestTune)) { data.frame(Parameter = "Number of terms (nterms)", Value = models$ppr$bestTune$nterms) } else data.frame(Message = "PPR uses projection pursuit - see model summary") }, rownames = TRUE, colnames = FALSE)
  
  
  # ========================================================================
  # 5.11 FAMILY 10 - BAYESIAN / SPARSE MODELS (Models 25-26)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 25: spikeslab - Spike and Slab Regression
  # ------------------------------------------------------------------------
  getspikeslabRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$spikeslab_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$spikeslab_Go, {
    method <- "spikeslab"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getspikeslabRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), na.action = na.pass, tuneLength = 5)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$spikeslab_Load, { 
    method <- "spikeslab"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$spikeslab_Delete, { models[["spikeslab"]] <- NULL; gc() })
  output$spikeslab_Metrics <- renderTable({ mod <- models[["spikeslab"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$spikeslab_ModelTune <- renderPlot({ mod <- models[["spikeslab"]]; req(mod); plot(mod) })
  output$spikeslab_RecipePrint <- renderUI({ mod <- models[["spikeslab"]]; req(mod); recipePrintHTML(mod) })
  output$spikeslab_RecipeOutput <- renderTable({ mod <- models[["spikeslab"]]; req(mod); recipeOutputTable(mod) })
  output$spikeslab_TrainSummary <- renderPrint({ mod <- models[["spikeslab"]]; req(mod); print(mod) })
  output$spikeslab_MethodSummary <- renderText({ description("spikeslab") })
  
  
  # ------------------------------------------------------------------------
  # Model 26: rvmRadial - Relevance Vector Machine
  # ------------------------------------------------------------------------
  getrvmRadialRecipe <- reactive({
    form <- formula(Response ~ .)
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$rvmRadial_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$rvmRadial_Go, {
    method <- "rvmRadial"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      tuneGrid_rvm <- expand.grid(sigma = c(0.001, 0.01, 0.05, 0.1, 0.5, 1))
      model <- caret::train(getrvmRadialRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), tuneGrid = tuneGrid_rvm, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$rvmRadial_Load, { 
    method <- "rvmRadial"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$rvmRadial_Delete, { models[["rvmRadial"]] <- NULL; gc() })
  output$rvmRadial_Metrics <- renderTable({ mod <- models[["rvmRadial"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$rvmRadial_ModelTune <- renderPlot({ mod <- models[["rvmRadial"]]; req(mod); plot(mod) })
  output$rvmRadial_RecipePrint <- renderUI({ mod <- models[["rvmRadial"]]; req(mod); recipePrintHTML(mod) })
  output$rvmRadial_RecipeOutput <- renderTable({ mod <- models[["rvmRadial"]]; req(mod); recipeOutputTable(mod) })
  output$rvmRadial_TrainSummary <- renderPrint({ mod <- models[["rvmRadial"]]; req(mod); print(mod) })
  output$rvmRadial_MethodSummary <- renderText({ description("rvmRadial") })
  
  
  # ========================================================================
  # 5.12 FAMILY 11 - K-NEAREST NEIGHBORS (Model 27)
  # ========================================================================
  
  # ------------------------------------------------------------------------
  # Model 27: kknn - Weighted k-Nearest Neighbors
  # ------------------------------------------------------------------------
  getKknnRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$kknn_Preprocess) %>% step_rm(has_type("date"))
  })
  
  observeEvent(input$kknn_Go, {
    method <- "kknn"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      model <- caret::train(getKknnRecipe(), data = getTrainData(), method = method, metric = "RMSE",
                            trControl = getTrControl(), tuneLength = 5, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$kknn_Load, { 
    method <- "kknn"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$kknn_Delete, { models[["kknn"]] <- NULL; gc() })
  output$kknn_MethodSummary <- renderText({ description("kknn") })
  output$kknn_Metrics <- renderTable({ mod <- models[["kknn"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$kknn_ModelTune <- renderPlot({ mod <- models[["kknn"]]; req(mod); plot(mod) })
  output$kknn_RecipePrint <- renderUI({ mod <- models[["kknn"]]; req(mod); recipePrintHTML(mod) })
  output$kknn_RecipeOutput <- renderTable({ mod <- models[["kknn"]]; req(mod); recipeOutputTable(mod) })
  output$kknn_TrainSummary <- renderPrint({ mod <- models[["kknn"]]; req(mod); print(mod) })
  
  
  # ========================================================================
  # ========================================================================
  # 5.13 FAMILY 13: MODEL OPTIMIZATION (Top 4 Models - Intensive Tuning)
  # ========================================================================
  # ========================================================================
  
  # Helper function to get neuron grid based on user selection
  getNeuronGrid <- function(input) {
    if(input$brnn_optim_neurons == "small") return(1:5)
    if(input$brnn_optim_neurons == "medium") return(1:10)
    if(input$brnn_optim_neurons == "large") return(1:15)
    if(input$brnn_optim_neurons == "xlarge") return(1:20)
    if(input$brnn_optim_neurons == "custom") {
      vals <- as.numeric(unlist(strsplit(input$brnn_optim_neurons_custom, ",")))
      return(vals[!is.na(vals)])
    }
    return(1:10)
  }
  
  # Helper function to get grid values from comma-separated string
  parseGridValues <- function(input_string) {
    vals <- as.numeric(unlist(strsplit(input_string, ",")))
    return(vals[!is.na(vals) & vals > 0])
  }
  
  # ------------------------------------------------------------------------
  # Model O1: brnn_optim - Optimized brnn
  # ------------------------------------------------------------------------
  
  getbrnn_optimRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$brnn_optim_Preprocess) %>%
      step_rm(has_type("date"))
  })
  
  observeEvent(input$brnn_optim_Go, {
    method <- "brnn_optim"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method, "with expanded tuning..."), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      neurons_vals <- getNeuronGrid(input)
      tuneGrid_brnn <- expand.grid(neurons = neurons_vals)
      model <- caret::train(getbrnn_optimRecipe(), data = getTrainData(), method = "brnn",
                            metric = "RMSE", trControl = getTrControl(), tuneGrid = tuneGrid_brnn)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
      showNotification(paste(method, "completed! Best neurons:", model$bestTune$neurons), 
                       session = session, type = "message")
    }, error = function(e) {
      showNotification(paste("brnn_optim error:", e$message), session = session, type = "error", duration = 15)
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$brnn_optim_Load, { 
    method <- "brnn_optim"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$brnn_optim_Delete, { models[["brnn_optim"]] <- NULL; gc() })
  output$brnn_optim_MethodSummary <- renderText({ description("brnn") })
  output$brnn_optim_Metrics <- renderTable({ mod <- models[["brnn_optim"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$brnn_optim_ModelTune <- renderPlot({ mod <- models[["brnn_optim"]]; req(mod); plot(mod) })
  output$brnn_optim_RecipePrint <- renderUI({ mod <- models[["brnn_optim"]]; req(mod); recipePrintHTML(mod) })
  output$brnn_optim_RecipeOutput <- renderTable({ mod <- models[["brnn_optim"]]; req(mod); recipeOutputTable(mod) })
  output$brnn_optim_TrainSummary <- renderPrint({ mod <- models[["brnn_optim"]]; req(mod); print(mod) })
  output$brnn_optim_BestTune <- renderPrint({ mod <- models[["brnn_optim"]]; req(mod); cat("Best neurons:", mod$bestTune$neurons) })
  
  
  # ------------------------------------------------------------------------
  # Model O2: gaussprPoly_optim - Optimized gaussprPoly
  # ------------------------------------------------------------------------
  
  getgaussprPoly_optimRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$gaussprPoly_optim_Preprocess) %>%
      step_rm(has_type("date"))
  })
  
  observeEvent(input$gaussprPoly_optim_Go, {
    method <- "gaussprPoly_optim"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method, "with expanded tuning..."), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      if(input$gaussprPoly_optim_degree == "small") degree_vals <- 1:3
      else if(input$gaussprPoly_optim_degree == "medium") degree_vals <- 1:5
      else if(input$gaussprPoly_optim_degree == "large") degree_vals <- 1:7
      else degree_vals <- parseGridValues(gsub(".*degree:", "", strsplit(input$gaussprPoly_optim_custom, "\\|")[[1]][1]))
      
      if(input$gaussprPoly_optim_scale == "small") scale_vals <- c(0.01, 0.05, 0.1)
      else if(input$gaussprPoly_optim_scale == "medium") scale_vals <- c(0.01, 0.05, 0.1, 0.5, 1)
      else if(input$gaussprPoly_optim_scale == "large") scale_vals <- c(0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10)
      else scale_vals <- parseGridValues(gsub(".*scale:", "", strsplit(input$gaussprPoly_optim_custom, "\\|")[[1]][2]))
      
      tuneGrid_gaussprPoly <- expand.grid(degree = degree_vals, scale = scale_vals)
      model <- caret::train(getgaussprPoly_optimRecipe(), data = getTrainData(), method = "gaussprPoly",
                            metric = "RMSE", trControl = getTrControl(), tuneGrid = tuneGrid_gaussprPoly)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
      showNotification(paste(method, "completed!"), session = session, type = "message")
    }, error = function(e) { 
      showNotification(paste("gaussprPoly_optim error:", e$message), session = session, type = "error", duration = 15) 
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$gaussprPoly_optim_Load, { 
    method <- "gaussprPoly_optim"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$gaussprPoly_optim_Delete, { models[["gaussprPoly_optim"]] <- NULL; gc() })
  output$gaussprPoly_optim_MethodSummary <- renderText({ description("gaussprPoly") })
  output$gaussprPoly_optim_Metrics <- renderTable({ mod <- models[["gaussprPoly_optim"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$gaussprPoly_optim_ModelTune <- renderPlot({ mod <- models[["gaussprPoly_optim"]]; req(mod); plot(mod) })
  output$gaussprPoly_optim_RecipePrint <- renderUI({ mod <- models[["gaussprPoly_optim"]]; req(mod); recipePrintHTML(mod) })
  output$gaussprPoly_optim_RecipeOutput <- renderTable({ mod <- models[["gaussprPoly_optim"]]; req(mod); recipeOutputTable(mod) })
  output$gaussprPoly_optim_TrainSummary <- renderPrint({ mod <- models[["gaussprPoly_optim"]]; req(mod); print(mod) })
  output$gaussprPoly_optim_BestTune <- renderPrint({ mod <- models[["gaussprPoly_optim"]]; req(mod); print(mod$bestTune) })
  
  
  # ------------------------------------------------------------------------
  # Model O3: svmPoly_optim - Optimized svmPoly
  # ------------------------------------------------------------------------
  
  getsvmPoly_optimRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$svmPoly_optim_Preprocess) %>%
      step_rm(has_type("date"))
  })
  
  observeEvent(input$svmPoly_optim_Go, {
    method <- "svmPoly_optim"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method, "with expanded tuning..."), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      if(input$svmPoly_optim_degree == "small") degree_vals <- 1:3
      else if(input$svmPoly_optim_degree == "medium") degree_vals <- 1:4
      else if(input$svmPoly_optim_degree == "large") degree_vals <- 1:5
      else degree_vals <- parseGridValues(gsub(".*degree:", "", strsplit(input$svmPoly_optim_custom, "\\|")[[1]][1]))
      
      if(input$svmPoly_optim_scale == "small") scale_vals <- c(0.001, 0.01, 0.1)
      else if(input$svmPoly_optim_scale == "medium") scale_vals <- c(0.001, 0.01, 0.1, 1)
      else if(input$svmPoly_optim_scale == "large") scale_vals <- c(0.001, 0.01, 0.1, 1, 10)
      else scale_vals <- parseGridValues(gsub(".*scale:", "", strsplit(input$svmPoly_optim_custom, "\\|")[[1]][2]))
      
      if(input$svmPoly_optim_C == "small") C_vals <- c(0.1, 0.5, 1, 2, 5)
      else if(input$svmPoly_optim_C == "medium") C_vals <- c(0.1, 0.5, 1, 2, 5, 10, 20)
      else if(input$svmPoly_optim_C == "large") C_vals <- c(0.1, 0.5, 1, 2, 5, 10, 20, 50, 100)
      else C_vals <- parseGridValues(gsub(".*C:", "", strsplit(input$svmPoly_optim_custom, "\\|")[[1]][3]))
      
      tuneGrid_svmPoly <- expand.grid(degree = degree_vals, scale = scale_vals, C = C_vals)
      model <- caret::train(getsvmPoly_optimRecipe(), data = getTrainData(), method = "svmPoly",
                            metric = "RMSE", trControl = getTrControl(), tuneGrid = tuneGrid_svmPoly)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
      showNotification(paste(method, "completed!"), session = session, type = "message")
    }, error = function(e) { 
      showNotification(paste("svmPoly_optim error:", e$message), session = session, type = "error", duration = 15) 
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$svmPoly_optim_Load, { 
    method <- "svmPoly_optim"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$svmPoly_optim_Delete, { models[["svmPoly_optim"]] <- NULL; gc() })
  
  output$svmPoly_optim_MethodSummary <- renderText({ description("svmPoly") })
  output$svmPoly_optim_Metrics <- renderTable({ 
    mod <- models[["svmPoly_optim"]]; req(mod); 
    mod$results[which.min(mod$results[,"RMSE"]),] 
  })
  
  output$svmPoly_optim_ModelTune <- renderPlot({
    mod <- models[["svmPoly_optim"]]
    req(mod)
    
    # Save original options and set digits to avoid formatting errors
    old_digits <- options("digits")
    options(digits = 4)
    on.exit(options(old_digits), add = TRUE)
    
    # Try to plot with error handling - same structure as non-optimised svmPoly
    tryCatch({
      plot(mod)
    }, error = function(e) {
      # If plot fails, create a simple alternative
      if(!is.null(mod$results) && nrow(mod$results) > 0) {
        results <- mod$results
        rmse_col <- which(names(results) == "RMSE")[1]
        if(!is.na(rmse_col)) {
          # Create a basic tuning plot
          plot(seq_len(nrow(results)), results[[rmse_col]], 
               type = "b", 
               xlab = "Tuning combination", 
               ylab = "RMSE",
               main = "Hyperparameter Tuning Results - svmPoly_optim",
               col = "steelblue", 
               pch = 16,
               cex = 1.2)
          
          # Highlight the best point
          best_idx <- which.min(results[[rmse_col]])
          points(best_idx, results[[rmse_col]][best_idx], 
                 col = "red", pch = 16, cex = 1.5)
          
          # Add grid
          grid(col = "lightgray", lty = "dotted")
          
          # Add best value annotation
          text(best_idx, results[[rmse_col]][best_idx], 
               labels = round(results[[rmse_col]][best_idx], 4), 
               pos = 3, cex = 0.8, col = "red")
          
          # Add best tune info in subtitle
          if(!is.null(mod$bestTune)) {
            best_info <- paste(names(mod$bestTune), "=", 
                               sapply(mod$bestTune, function(x) round(x, 4)), 
                               collapse = ", ")
            mtext(best_info, side = 3, line = 0.5, cex = 0.9, col = "darkgreen")
          }
        } else {
          plot.new()
          text(0.5, 0.5, "Cannot display tuning plot - RMSE column not found", cex = 0.8)
        }
      } else {
        plot.new()
        text(0.5, 0.5, "No tuning results available", cex = 0.8)
      }
    })
  })
  
  output$svmPoly_optim_RecipePrint <- renderUI({ 
    mod <- models[["svmPoly_optim"]]; req(mod); recipePrintHTML(mod) 
  })
  output$svmPoly_optim_RecipeOutput <- renderTable({ 
    mod <- models[["svmPoly_optim"]]; req(mod); recipeOutputTable(mod) 
  })
  output$svmPoly_optim_TrainSummary <- renderPrint({ 
    mod <- models[["svmPoly_optim"]]; req(mod); print(mod) 
  })
  output$svmPoly_optim_BestTune <- renderPrint({ 
    mod <- models[["svmPoly_optim"]]; req(mod); 
    cat("Best tuning parameters:\n")
    if(!is.null(mod$bestTune)) {
      for(param in names(mod$bestTune)) {
        val <- mod$bestTune[[param]]
        if(is.numeric(val)) {
          cat(sprintf("  %s = %s\n", param, round(val, 6)))
        } else {
          cat(sprintf("  %s = %s\n", param, as.character(val)))
        }
      }
    } else {
      cat("  No tuning parameters found\n")
    }
    if(!is.null(mod$results)) {
      cat(sprintf("\nBest RMSE: %.4f", min(mod$results$RMSE, na.rm = TRUE)))
    }
  })
  
  # ------------------------------------------------------------------------
  # Model O4: svmRadial_optim - Optimized svmRadial
  # ------------------------------------------------------------------------
  
  getsvmRadial_optimRecipe <- reactive({
    recipes::recipe(Response ~ ., data = getTrainData()) %>%
      dynamicSteps(input$svmRadial_optim_Preprocess) %>%
      step_rm(has_type("date"))
  })
  
  observeEvent(input$svmRadial_optim_Go, {
    method <- "svmRadial_optim"; models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method, "with expanded tuning..."), session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    tryCatch({
      t0 <- proc.time()["elapsed"]
      if(input$svmRadial_optim_sigma == "small") sigma_vals <- c(0.001, 0.005, 0.01, 0.05, 0.1)
      else if(input$svmRadial_optim_sigma == "medium") sigma_vals <- c(0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1)
      else if(input$svmRadial_optim_sigma == "large") sigma_vals <- c(0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10)
      else sigma_vals <- parseGridValues(gsub(".*sigma:", "", strsplit(input$svmRadial_optim_custom, "\\|")[[1]][1]))
      
      if(input$svmRadial_optim_C == "small") C_vals <- c(0.1, 0.5, 1, 2, 5, 10)
      else if(input$svmRadial_optim_C == "medium") C_vals <- c(0.1, 0.5, 1, 2, 5, 10, 25, 50)
      else if(input$svmRadial_optim_C == "large") C_vals <- c(0.1, 0.5, 1, 2, 5, 10, 25, 50, 100)
      else C_vals <- parseGridValues(gsub(".*C:", "", strsplit(input$svmRadial_optim_custom, "\\|")[[1]][2]))
      
      tuneGrid_svmRadial <- expand.grid(sigma = sigma_vals, C = C_vals)
      model <- caret::train(getsvmRadial_optimRecipe(), data = getTrainData(), method = "svmRadial",
                            metric = "RMSE", trControl = getTrControl(), tuneGrid = tuneGrid_svmRadial)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
      showNotification(paste(method, "completed! Best sigma:", round(model$bestTune$sigma, 4), "C:", model$bestTune$C), 
                       session = session, type = "message")
    }, error = function(e) { 
      showNotification(paste("svmRadial_optim error:", e$message), session = session, type = "error", duration = 15) 
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$svmRadial_optim_Load, { 
    method <- "svmRadial_optim"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$svmRadial_optim_Delete, { models[["svmRadial_optim"]] <- NULL; gc() })
  output$svmRadial_optim_MethodSummary <- renderText({ description("svmRadial") })
  output$svmRadial_optim_Metrics <- renderTable({ mod <- models[["svmRadial_optim"]]; req(mod); mod$results[which.min(mod$results[,"RMSE"]),] })
  output$svmRadial_optim_ModelTune <- renderPlot({
    mod <- models[["svmRadial_optim"]]
    req(mod)
    tryCatch({
      plot(mod)
    }, error = function(e) {
      plot.new()
      text(0.5, 0.5, "Tuning plot not available", cex = 0.8)
    })
  })
  output$svmRadial_optim_RecipePrint <- renderUI({ mod <- models[["svmRadial_optim"]]; req(mod); recipePrintHTML(mod) })
  output$svmRadial_optim_RecipeOutput <- renderTable({ mod <- models[["svmRadial_optim"]]; req(mod); recipeOutputTable(mod) })
  output$svmRadial_optim_TrainSummary <- renderPrint({ mod <- models[["svmRadial_optim"]]; req(mod); print(mod) })
  output$svmRadial_optim_BestTune <- renderPrint({ mod <- models[["svmRadial_optim"]]; req(mod); cat("Best sigma:", mod$bestTune$sigma, "\nBest C:", mod$bestTune$C) })
  
  
  # ========================================================================
  # 5.14 FAMILY 13: TRANSPARENT MODEL OPTIMIZATION (Elastic Net with Interactions)
  # ========================================================================
  
  getGlmnetInteractRecipe <- reactive({
    form <- formula(Response ~ .)
    
    recipes::recipe(form, data = getTrainData()) %>%
      dynamicSteps(input$glmnet_interact_Preprocess) %>%
      step_rm(has_type("date")) %>%
      step_interact(terms = ~ (all_numeric_predictors())^2) %>%
      step_zv(all_predictors()) %>%
      step_nzv(all_predictors())
  })
  
  observeEvent(input$glmnet_interact_Go, {
    method <- "glmnet_interact"
    models[[method]] <- NULL
    showNotification(id = method, paste("Processing", method, "model with 2-way interactions..."), 
                     session = session, duration = NULL)
    obj <- startMode(input$Parallel)
    
    tryCatch({
      t0 <- proc.time()["elapsed"]
      recipe_obj <- getGlmnetInteractRecipe()
      prepped <- recipe_obj %>% prep(training = getTrainData(), retain = TRUE)
      baked_data <- juice(prepped)
      
      n_predictors <- ncol(baked_data) - 1
      n_observations <- nrow(baked_data)
      showNotification(paste("Created", n_predictors, "predictors (including 2-way interactions)"), session = session, duration = 5)
      
      y <- baked_data$Response
      x <- as.matrix(baked_data[, !names(baked_data) %in% "Response"])
      
      quick_fit <- tryCatch({ glmnet(x, y, alpha = 0.5, nlambda = 20) }, error = function(e) { NULL })
      
      if(!is.null(quick_fit)) {
        lambda_seq <- quick_fit$lambda
        lambda_seq <- lambda_seq[lambda_seq > 0.001 & lambda_seq < 1]
        if(length(lambda_seq) < 5) {
          lambda_seq <- c(0.001, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1)
        }
      } else {
        lambda_seq <- c(0.001, 0.005, 0.01, 0.02, 0.03, 0.05, 0.07, 0.1, 0.2, 0.3, 0.5, 0.7, 1)
      }
      
      showNotification(paste("Testing", length(lambda_seq), "lambda values per alpha"), session = session, duration = 5)
      
      tuneGrid_glmnet_interact <- expand.grid(
        alpha = c(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1),
        lambda = lambda_seq
      )
      
      model <- caret::train(recipe_obj, data = getTrainData(), method = "glmnet", metric = "RMSE",
                            trControl = getTrControl(), tuneGrid = tuneGrid_glmnet_interact, na.action = na.pass)
      t1 <- proc.time()["elapsed"]
      elapsed <- as.numeric(t1 - t0)
      
      training_times[[method]] <- elapsed
      deleteRds(method)
      saveToRds(model, method, elapsed_sec = elapsed)
      models[[method]] <- model
      training_metrics[[method]] <- extract_all_metrics(model, method)
      
      best_alpha <- model$bestTune$alpha
      best_lambda <- model$bestTune$lambda
      if(best_lambda < 0.001) {
        showNotification(paste("Warning: Best lambda (", round(best_lambda, 6), ") is very small."), session = session, type = "warning", duration = 10)
      }
      
      final_coef <- as.matrix(coef(model$finalModel, s = best_lambda))
      n_zero <- sum(abs(final_coef) < 1e-6)
      n_total <- length(final_coef)
      sparsity <- round(100 * n_zero / n_total, 1)
      coef_names <- rownames(final_coef)
      interaction_count <- sum(grepl(":", coef_names) & abs(final_coef) > 1e-6)
      main_effect_count <- (n_total - n_zero) - interaction_count - 1
      
      model_type <- if(best_alpha == 0) { "Ridge Regression (L2 penalty)"
      } else if(best_alpha == 1) { "Lasso Regression (L1 penalty)"
      } else { paste0("Elastic Net (alpha = ", best_alpha, ")") }
      
      showNotification(paste(method, "completed!\n", model_type, "\nBest lambda:", round(best_lambda, 5), 
                             "\nSelected:", main_effect_count, "main effects,", interaction_count, "interactions\nSparsity:", sparsity, "%"), 
                       session = session, type = "message", duration = 10)
    }, error = function(e) {
      showNotification(paste("glmnet_interact error:", e$message), session = session, type = "error", duration = 15)
    }, finally = { removeNotification(id = method); stopMode(obj) })
  })
  
  observeEvent(input$glmnet_interact_Load, { 
    method <- "glmnet_interact"
    result <- loadRds(method, session)
    if(!is.null(result)) {
      models[[method]] <- result$model
      if(!is.null(result$elapsed_sec)) training_times[[method]] <- result$elapsed_sec
      training_metrics[[method]] <- extract_all_metrics(result$model, method)
    }
  })
  observeEvent(input$glmnet_interact_Delete, { method <- "glmnet_interact"; models[[method]] <- NULL; gc() })
  
  output$glmnet_interact_MethodSummary <- renderText({
    paste0("Elastic Net Regression with 2-Way Interaction Terms\n==================================================\n\n",
           "This model automatically creates all 2-way interactions between numeric predictors.\n",
           "The tuning process searches over BOTH alpha (elastic net mix) and lambda (regularization).\n\n",
           "Interpretation of alpha:\n  • alpha = 0: Ridge Regression (L2 penalty)\n  • alpha = 0.5: Elastic Net\n  • alpha = 1: Lasso Regression (L1 penalty)")
  })
  
  output$glmnet_interact_Metrics <- renderTable({ mod <- models[["glmnet_interact"]]; req(mod); mod$results[which.min(mod$results[, "RMSE"]), ] })
  output$glmnet_interact_ModelTune <- renderPlot({ mod <- models[["glmnet_interact"]]; req(mod); plot(mod) })
  output$glmnet_interact_Coef <- renderTable({
    req(models$glmnet_interact)
    co <- as.matrix(coef(models$glmnet_interact$finalModel, s = models$glmnet_interact$bestTune$lambda))
    df <- as.data.frame(co, row.names = rownames(co))
    colnames(df) <- c("Coefficient")
    nonzero <- df[abs(df$Coefficient) > 1e-6, , drop = FALSE]
    nonzero <- nonzero[order(-abs(nonzero$Coefficient)), , drop = FALSE]
    nonzero$Type <- ifelse(grepl(":", rownames(nonzero)), "Interaction", "Main Effect")
    nonzero$Type[1] <- "Intercept"
    n_interactions <- sum(nonzero$Type == "Interaction" & rownames(nonzero) != "(Intercept)")
    n_main <- sum(nonzero$Type == "Main Effect")
    summary_df <- data.frame(Coefficient = c(n_main, n_interactions, nrow(nonzero) - 1),
                             Type = c("Main Effects", "Interactions", "Total Features Selected"),
                             row.names = c("main_count", "interaction_count", "total_count"))
    result <- rbind(summary_df, nonzero)
    result$Coefficient <- round(result$Coefficient, 4)
    result <- result[, c("Coefficient", "Type"), drop = FALSE]
    result
  }, rownames = TRUE, colnames = TRUE)
  
  output$glmnet_interact_RecipePrint <- renderUI({
    mod <- models[["glmnet_interact"]]
    req(mod)
    interaction_info <- paste0("\n# ========================================\n# 2-WAY INTERACTIONS INCLUDED\n# All numeric predictors are interacted using: (all_numeric_predictors())^2\n# ========================================\n\n")
    html <- mod$recipe %>% print() %>% cli::cli_fmt() %>% cli::ansi_collapse(sep = "<br>", last = "<br>") %>%
      cli::ansi_html(escape_reserved = FALSE) %>% gsub(pattern = "──────", replacement = "─", x = ., fixed = TRUE)
    full_html <- paste0("<pre>", interaction_info, "</pre>", html)
    css <- paste(format(ansi_html_style()), collapse = "\n")
    tagList(tags$head(tags$style(css)), HTML(full_html))
  })
  
  output$glmnet_interact_RecipeOutput <- renderTable({ 
    mod <- models[["glmnet_interact"]]; req(mod); 
    if(!is.null(mod$recipe)) { 
      terms <- as.data.frame(mod$recipe$term_info); n <- dim(terms)[1]; types <- vector(mode = "character", length = n); 
      for (row in 1:n) { types[row] <- paste(collapse = " ", unlist(terms$type[row])) }; terms$type <- types; 
      terms %>% dplyr::filter(role == "predictor") %>% dplyr::select(type, source) %>% dplyr::group_by(type, source) %>% dplyr::summarise(count = n()) 
    } else { data.frame(Message = "Recipe summary not available") } 
  })
  
  output$glmnet_interact_TrainSummary <- renderPrint({ 
    mod <- models[["glmnet_interact"]]; req(mod); 
    cat("GLMNET with 2-Way Interactions - Model Summary\n===============================================\n\n"); 
    print(mod); 
    cat("\n\nOptimal Configuration:\n======================\n"); 
    if(!is.null(mod$bestTune)) { 
      best_alpha <- mod$bestTune$alpha; best_lambda <- mod$bestTune$lambda; 
      cat("  Best alpha (Elastic Net mix):", best_alpha, "\n"); 
      cat("  Best lambda (regularization):", round(best_lambda, 6), "\n\n"); 
      if(best_alpha == 0) { cat("  → Ridge Regression selected (L2 penalty)\n") 
      } else if(best_alpha == 1) { cat("  → Lasso Regression selected (L1 penalty)\n") 
      } else { cat("  → Elastic Net selected (mix of L1 and L2)\n") } 
    }; 
    cat("\n  Interaction terms: 2-way interactions included\n"); 
    if(!is.null(mod$finalModel)) { 
      co <- as.matrix(coef(mod$finalModel, s = mod$bestTune$lambda)); 
      co_names <- rownames(co); 
      n_zero <- sum(abs(co) < 1e-6); n_total <- length(co); 
      n_nonzero <- n_total - n_zero; 
      n_interactions <- sum(grepl(":", co_names) & abs(co) > 1e-6); 
      n_main <- n_nonzero - n_interactions - 1; 
      sparsity <- round(100 * n_zero / n_total, 1); 
      cat("\nFeature Selection Results:\n==========================\n"); 
      cat("  Total features considered:", n_total - 1, "\n"); 
      cat("  Main effects selected:", n_main, "\n"); 
      cat("  Interaction terms selected:", n_interactions, "\n"); 
      cat("  Total features selected:", n_nonzero - 1, "\n"); 
      cat("  Sparsity (zero coefficients):", sparsity, "%\n") 
    } 
  })
  
  
  
  
  
  # ========================================================================
  # ========================================================================
  # SECTION 6: MODEL SELECTION & COMPARISON
  # ========================================================================
  # ========================================================================
  
  # ========================================================================
  # SECTION 6.1: MODEL DISPLAY NAMES
  # ========================================================================
  
  # Define model name mappings (complete list - 27 models + optimised versions)
  model_display_names <- c(
    # Baseline Model
    "null" = "Null Model (Intercept Only)",
    
    # Family 1: Linear Models (01-03)
    "lm" = "Linear Regression (lm)",
    "glmnet" = "Elastic Net (glmnet)",
    "rlm" = "Robust Linear Model (rlm)",
    
    # Family 2: PLS Models (04-05)
    "pls" = "Partial Least Squares (pls)",
    "pcr" = "Principal Component Regression (pcr)",
    
    # Family 3: Tree Models (06-07)
    "rpart" = "CART Decision Tree (rpart)",
    "cubist" = "Cubist Rule-Based Model",
    
    # Family 4: Random Forest Models (08-09)
    "ranger" = "Random Forest (ranger)",
    "qrf" = "Quantile Random Forest (qrf)",
    
    # Family 5: Gradient Boosting Models (10-12)
    "bstTree" = "Boosted Trees (bstTree)",
    "glmboost" = "Boosted Linear Model (glmboost)",
    "blackboost" = "Black Box Boosting (blackboost)",
    
    # Family 6: SVM Models (13-15)
    "svmRadial" = "SVM with Radial Kernel",
    "svmPoly" = "SVM with Polynomial Kernel",
    "svmLinear" = "SVM with Linear Kernel",
    
    # Family 7: Neural Network Models (16-19)
    "avNNet" = "Model Averaged Neural Network (avNNet)",
    "mlpWeightDecayML" = "Multi-Layer Perceptron (mlpWeightDecayML)",
    "brnn" = "Bayesian Regularized Neural Network (brnn)",
    "neuralnet" = "Neural Network with Backpropagation",
    
    # Family 8: Gaussian Process Models (20-21)
    "gaussprRadial" = "Gaussian Process with Radial Kernel",
    "gaussprPoly" = "Gaussian Process with Polynomial Kernel",
    
    # Family 9: GAM/MARS Models (22-24)
    "earth" = "MARS - Multivariate Adaptive Regression Splines",
    "gam" = "GAM - Generalized Additive Model",
    "ppr" = "Projection Pursuit Regression (ppr)",
    
    # Family 10: Bayesian/Sparse Models (25-26)
    "spikeslab" = "Spike and Slab Regression",
    "rvmRadial" = "Relevance Vector Machine (rvmRadial)",
    
    # Family 11: K-Nearest Neighbors (27)
    "kknn" = "Weighted K-Nearest Neighbors (kknn)",
    
    # Optimised Models (Family 12)
    "glmnet_interact" = "Elastic Net with 2-Way Interactions",
    "brnn_optim" = "BRNN (Optimised) - Bayesian Neural Network",
    "gaussprPoly_optim" = "Gaussian Process Poly (Optimised)",
    "svmPoly_optim" = "SVM Polynomial (Optimised)",
    "svmRadial_optim" = "SVM Radial (Optimised)"
  )
  
  # ========================================================================
  # SECTION 6.2: MODEL SELECTION & COMPARISON
  # ========================================================================
  
  getResamples <- reactive({
    models2 <- reactiveValuesToList(models) %>% rlist::list.clean(fun = is.null, recursive = FALSE)
    req(length(models2) >= 1)
    
    # caret::resamples() requires 2+ models - handle single model case
    if (length(models2) < 2) {
      model_name <- names(models2)[1]
      display_name <- if (model_name %in% names(model_display_names)) {
        model_display_names[[model_name]]
      } else {
        model_name
      }
      display_names <- setNames(display_name, display_name)
      
      updateRadioButtons(session, "Choice",
                         choices  = display_names,
                         selected = display_name)
      updateSelectInput(session, "perf_model_choice",
                        choices  = setNames(model_name, display_name),
                        selected = model_name)
      return(NULL)
    }
    
    # 2+ models: run full resamples comparison
    results <- caret::resamples(models2)
    
    NullModel <- "null"
    if (input$NullNormalise & NullModel %in% results$models) {
      actualNames <- colnames(results$values)
      
      null_rmse <- NULL
      null_mae  <- NULL
      
      rmse_col <- paste(sep = "~", NullModel, "RMSE")
      if (rmse_col %in% actualNames) {
        null_rmse <- mean(results$values[, rmse_col], na.rm = TRUE)
      }
      
      mae_col <- paste(sep = "~", NullModel, "MAE")
      if (mae_col %in% actualNames) {
        null_mae <- mean(results$values[, mae_col], na.rm = TRUE)
      }
      
      for (metric in c("RMSE", "MAE")) {
        col <- paste(sep = "~", NullModel, metric)
        if (col %in% actualNames) {
          null_metric <- if (metric == "RMSE") null_rmse else null_mae
          if (!is.na(null_metric) & null_metric != 0) {
            for (model in results$models) {
              mcol <- paste(sep = "~", model, metric)
              if (mcol %in% actualNames) {
                results$values[, mcol] <- results$values[, mcol] / null_metric
              }
            }
          }
        }
      }
    }
    
    subset <- rep(TRUE, length(models2))
    if (input$HideWorse & NullModel %in% names(models2)) {
      actualNames <- colnames(results$values)
      col <- paste(sep = "~", "null", "RMSE")
      if (col %in% actualNames) {
        nullMetric <- mean(results$values[, col], na.rm = TRUE)
        if (!is.na(nullMetric)) {
          m <- 0
          for (model3 in results$models) {
            m <- m + 1
            mcol <- paste(sep = "~", model3, "RMSE")
            if (mcol %in% actualNames) {
              subset[m] <- mean(results$values[, mcol], na.rm = TRUE) <= nullMetric
            }
          }
        }
      }
      results$models <- results$models[subset]
    }
    
    # Create display names — names and values both set to display string
    # so input$Choice returns the display name consistently
    display_names <- sapply(results$models, function(m) {
      if (m %in% names(model_display_names)) model_display_names[[m]] else m
    })
    names(display_names) <- display_names
    
    # Determine preferred selection: brnn_optim first, then current, then first
    brnn_display <- if ("brnn_optim" %in% names(model_display_names)) {
      model_display_names[["brnn_optim"]]
    } else {
      "brnn_optim"
    }
    
    current_choice <- isolate(input$Choice)
    
    preferred <- if ("brnn_optim" %in% results$models) {
      brnn_display
    } else if (!is.null(current_choice) &&
               current_choice != "" &&
               current_choice %in% display_names) {
      current_choice
    } else if (length(display_names) > 0) {
      display_names[1]
    } else {
      ""
    }
    
    updateRadioButtons(session = session, inputId = "Choice",
                       choices  = display_names,
                       selected = preferred)
    
    results
  })
  
  output$SelectionBoxPlot <- renderPlot({
    mod <- getResamples()
    
    if (is.null(mod)) {
      plot.new()
      text(0.5, 0.5,
           "Load at least 2 models to see the comparison boxplot.",
           cex = 1.1, col = "#666666")
      return()
    }
    
    bwplot(mod, notch = input$Notch)
  })
  
  # ========================================================================
  # SECTION 6.3: SELECTED MODEL SUMMARY OUTPUTS
  # ========================================================================
  
  # Get the currently selected model key from the display name
  get_selected_model_key <- reactive({
    req(input$Choice)
    selected_display <- input$Choice
    
    # Find the model key that matches this display name
    for(key in names(model_display_names)) {
      if(model_display_names[[key]] == selected_display) {
        return(key)
      }
    }
    return(NULL)
  })
  
  # Helper function to get null model value for normalisation
  get_null_model_value <- reactive({
    if(!input$NullNormalise) return(1)
    
    null_model <- models[["null"]]
    if(is.null(null_model)) return(1)
    if(is.null(null_model$results) || nrow(null_model$results) == 0) return(1)
    
    best_row <- which.min(null_model$results[, "RMSE"])
    null_rmse <- null_model$results[best_row, "RMSE"]
    if(is.na(null_rmse) || null_rmse == 0) return(1)
    
    return(null_rmse)
  })
  
  # Get full bootstrap results for the selected model (all resamples)
  get_selected_model_bootstrap_values <- reactive({
    model_key <- get_selected_model_key()
    req(model_key)
    req(!is.null(models[[model_key]]))
    
    # Get the trained model
    model <- models[[model_key]]
    
    # Extract all bootstrap results from the model's resamples
    if(!is.null(model$resample) && nrow(model$resample) > 0) {
      # Get the best tuning parameters (if tuning was used)
      if(!is.null(model$bestTune) && nrow(model$bestTune) > 0) {
        # For tuned models, we need to filter resamples that used the best parameters
        # This is complex - different model types store this differently
        # Alternative: use the model$pred data which contains predictions from all resamples
        
        if(!is.null(model$pred) && nrow(model$pred) > 0) {
          # Calculate metrics per resample from predictions
          resample_metrics <- model$pred %>%
            group_by(Resample) %>%
            summarise(
              RMSE = sqrt(mean((obs - pred)^2)),
              Rsquared = cor(obs, pred)^2,
              MAE = mean(abs(obs - pred))
            )
          
          return(list(
            rmse = resample_metrics$RMSE,
            rsquared = resample_metrics$Rsquared,
            mae = resample_metrics$MAE
          ))
        }
      }
      
      # If no tuning or can't filter, use all resamples
      return(list(
        rmse = model$resample$RMSE,
        rsquared = model$resample$Rsquared,
        mae = if("MAE" %in% names(model$resample)) model$resample$MAE else NULL
      ))
    }
    
    return(NULL)
  })
  
  # Get bootstrap summary for the selected model (best tuning row stats)
  get_selected_model_bootstrap_stats <- reactive({
    model_key <- get_selected_model_key()
    req(model_key)
    req(!is.null(models[[model_key]]))
    
    model <- models[[model_key]]
    
    if(!is.null(model$results) && nrow(model$results) > 0) {
      best_row <- which.min(model$results[, "RMSE"])
      best_results <- model$results[best_row, ]
      
      rmse_val <- if("RMSE" %in% names(best_results)) best_results$RMSE else NA
      rmse_sd <- if("RMSESD" %in% names(best_results)) best_results$RMSESD else NA
      r2_val <- if("Rsquared" %in% names(best_results)) best_results$Rsquared else NA
      r2_sd <- if("RsquaredSD" %in% names(best_results)) best_results$RsquaredSD else NA
      mae_val <- if("MAE" %in% names(best_results)) best_results$MAE else NA
      mae_sd <- if("MAESD" %in% names(best_results)) best_results$MAESD else NA
      
      return(list(
        rmse = rmse_val,
        rmse_sd = rmse_sd,
        rsquared = r2_val,
        rsquared_sd = r2_sd,
        mae = mae_val,
        mae_sd = mae_sd,
        best_tune = model$bestTune
      ))
    }
    return(NULL)
  })
  
  output$selected_model_rmse <- renderText({
    stats <- get_selected_model_bootstrap_stats()
    if(is.null(stats) || is.na(stats$rmse)) return("N/A")
    
    val <- stats$rmse
    null_val <- get_null_model_value()
    if(null_val != 1) {
      val <- val / null_val
    }
    sprintf("%.4f", val)
  })
  
  output$selected_model_rmse_sd <- renderText({
    stats <- get_selected_model_bootstrap_stats()
    if(is.null(stats) || is.na(stats$rmse_sd)) return("")
    
    sd_val <- stats$rmse_sd
    null_val <- get_null_model_value()
    if(null_val != 1 && !is.na(null_val)) {
      sd_val <- sd_val / null_val
    }
    sprintf("± %.4f", sd_val)
  })
  
  output$selected_model_rsquared <- renderText({
    stats <- get_selected_model_bootstrap_stats()
    if(is.null(stats) || is.na(stats$rsquared)) return("N/A")
    sprintf("%.4f", stats$rsquared)
  })
  
  output$selected_model_rsquared_sd <- renderText({
    stats <- get_selected_model_bootstrap_stats()
    if(is.null(stats) || is.na(stats$rsquared_sd)) return("")
    sprintf("± %.4f", stats$rsquared_sd)
  })
  
  output$selected_model_mae <- renderText({
    stats <- get_selected_model_bootstrap_stats()
    if(is.null(stats) || is.na(stats$mae)) return("N/A")
    
    val <- stats$mae
    null_val <- get_null_model_value()
    if(null_val != 1) {
      val <- val / null_val
    }
    sprintf("%.4f", val)
  })
  
  output$selected_model_mae_sd <- renderText({
    stats <- get_selected_model_bootstrap_stats()
    if(is.null(stats) || is.na(stats$mae_sd)) return("")
    
    sd_val <- stats$mae_sd
    null_val <- get_null_model_value()
    if(null_val != 1 && !is.na(null_val)) {
      sd_val <- sd_val / null_val
    }
    sprintf("± %.4f", sd_val)
  })
  
  # Helper function to calculate boxplot statistics
  calculate_boxplot_stats <- function(values, iqr_multiplier = 1.5) {
    if(is.null(values) || length(values) == 0) return(NULL)
    
    values <- values[!is.na(values)]
    if(length(values) == 0) return(NULL)
    
    q1 <- quantile(values, 0.25)
    q3 <- quantile(values, 0.75)
    iqr <- q3 - q1
    lower_bound <- q1 - iqr_multiplier * iqr
    upper_bound <- q3 + iqr_multiplier * iqr
    outliers <- values[values < lower_bound | values > upper_bound]
    
    list(
      min = min(values),
      q1 = q1,
      median = median(values),
      mean = mean(values),
      q3 = q3,
      max = max(values),
      iqr = iqr,
      lower_bound = lower_bound,
      upper_bound = upper_bound,
      n = length(values),
      n_outliers = length(outliers),
      outlier_values = outliers,
      outlier_pct = round(100 * length(outliers) / length(values), 1)
    )
  }
  
  # Boxplot statistics outputs
  output$selected_model_rmse_boxplot_stats <- renderPrint({
    bootstrap_vals <- get_selected_model_bootstrap_values()
    if(is.null(bootstrap_vals) || is.null(bootstrap_vals$rmse)) {
      cat("No bootstrap distribution data available.\n")
      cat("Note: Bootstrap values are extracted from model$resample or model$pred.\n")
      return()
    }
    
    # Use ACTUAL values, NOT normalised for boxplot stats
    vals <- bootstrap_vals$rmse
    
    stats <- calculate_boxplot_stats(vals)
    if(is.null(stats)) {
      cat("Unable to calculate statistics.\n")
      return()
    }
    
    cat(sprintf("  Min:     %10.4f\n", stats$min))
    cat(sprintf("  Q1:      %10.4f\n", stats$q1))
    cat(sprintf("  Median:  %10.4f\n", stats$median))
    cat(sprintf("  Mean:    %10.4f\n", stats$mean))
    cat(sprintf("  Q3:      %10.4f\n", stats$q3))
    cat(sprintf("  Max:     %10.4f\n", stats$max))
    cat(sprintf("  IQR:     %10.4f\n", stats$iqr))
    cat(sprintf("  Lower:   %10.4f\n", stats$lower_bound))
    cat(sprintf("  Upper:   %10.4f\n", stats$upper_bound))
    cat(paste(rep("─", 28), collapse = ""), "\n")
    cat(sprintf("  N:        %10d\n", stats$n))
    cat(sprintf("  Outliers: %10d (%.1f%%)", stats$n_outliers, stats$outlier_pct))
  })
  
  output$selected_model_rsquared_boxplot_stats <- renderPrint({
    bootstrap_vals <- get_selected_model_bootstrap_values()
    if(is.null(bootstrap_vals) || is.null(bootstrap_vals$rsquared)) {
      cat("No bootstrap distribution data available.\n")
      return()
    }
    
    vals <- bootstrap_vals$rsquared
    
    stats <- calculate_boxplot_stats(vals)
    if(is.null(stats)) {
      cat("Unable to calculate statistics.\n")
      return()
    }
    
    cat(sprintf("  Min:     %10.4f\n", stats$min))
    cat(sprintf("  Q1:      %10.4f\n", stats$q1))
    cat(sprintf("  Median:  %10.4f\n", stats$median))
    cat(sprintf("  Mean:    %10.4f\n", stats$mean))
    cat(sprintf("  Q3:      %10.4f\n", stats$q3))
    cat(sprintf("  Max:     %10.4f\n", stats$max))
    cat(sprintf("  IQR:     %10.4f\n", stats$iqr))
    cat(sprintf("  Lower:   %10.4f\n", stats$lower_bound))
    cat(sprintf("  Upper:   %10.4f\n", stats$upper_bound))
    cat(paste(rep("─", 28), collapse = ""), "\n")
    cat(sprintf("  N:        %10d\n", stats$n))
    cat(sprintf("  Outliers: %10d (%.1f%%)", stats$n_outliers, stats$outlier_pct))
  })
  
  output$selected_model_mae_boxplot_stats <- renderPrint({
    bootstrap_vals <- get_selected_model_bootstrap_values()
    if(is.null(bootstrap_vals) || is.null(bootstrap_vals$mae)) {
      cat("MAE distribution data not available for this model.\n")
      return()
    }
    
    vals <- bootstrap_vals$mae
    
    stats <- calculate_boxplot_stats(vals)
    if(is.null(stats)) {
      cat("Unable to calculate statistics.\n")
      return()
    }
    
    cat(sprintf("  Min:     %10.4f\n", stats$min))
    cat(sprintf("  Q1:      %10.4f\n", stats$q1))
    cat(sprintf("  Median:  %10.4f\n", stats$median))
    cat(sprintf("  Mean:    %10.4f\n", stats$mean))
    cat(sprintf("  Q3:      %10.4f\n", stats$q3))
    cat(sprintf("  Max:     %10.4f\n", stats$max))
    cat(sprintf("  IQR:     %10.4f\n", stats$iqr))
    cat(sprintf("  Lower:   %10.4f\n", stats$lower_bound))
    cat(sprintf("  Upper:   %10.4f\n", stats$upper_bound))
    cat(paste(rep("─", 28), collapse = ""), "\n")
    cat(sprintf("  N:        %10d\n", stats$n))
    cat(sprintf("  Outliers: %10d (%.1f%%)", stats$n_outliers, stats$outlier_pct))
  })
  
  output$selected_model_outlier_warning <- renderUI({
    bootstrap_vals <- get_selected_model_bootstrap_values()
    if(is.null(bootstrap_vals)) return(NULL)
    
    # Calculate outliers using the same IQR method as the boxplot
    rmse_stats <- if(!is.null(bootstrap_vals$rmse)) calculate_boxplot_stats(bootstrap_vals$rmse) else NULL
    r2_stats <- if(!is.null(bootstrap_vals$rsquared)) calculate_boxplot_stats(bootstrap_vals$rsquared) else NULL
    mae_stats <- if(!is.null(bootstrap_vals$mae)) calculate_boxplot_stats(bootstrap_vals$mae) else NULL
    
    # Only report metrics that ACTUALLY have outliers
    outlier_metrics <- c()
    outlier_counts <- c()
    
    if(!is.null(rmse_stats) && rmse_stats$n_outliers > 0) {
      outlier_metrics <- c(outlier_metrics, "RMSE")
      outlier_counts <- c(outlier_counts, sprintf("%d (%.1f%%)", rmse_stats$n_outliers, rmse_stats$outlier_pct))
    }
    if(!is.null(r2_stats) && r2_stats$n_outliers > 0) {
      outlier_metrics <- c(outlier_metrics, "R²")
      outlier_counts <- c(outlier_counts, sprintf("%d (%.1f%%)", r2_stats$n_outliers, r2_stats$outlier_pct))
    }
    if(!is.null(mae_stats) && mae_stats$n_outliers > 0) {
      outlier_metrics <- c(outlier_metrics, "MAE")
      outlier_counts <- c(outlier_counts, sprintf("%d (%.1f%%)", mae_stats$n_outliers, mae_stats$outlier_pct))
    }
    
    if(length(outlier_metrics) > 0) {
      # Build the message
      if(length(outlier_metrics) == 1) {
        msg <- sprintf("%s has %s outlier(s)", outlier_metrics[1], outlier_counts[1])
      } else if(length(outlier_metrics) == 2) {
        msg <- sprintf("%s has %s and %s has %s outlier(s)", 
                       outlier_metrics[1], outlier_counts[1], 
                       outlier_metrics[2], outlier_counts[2])
      } else {
        msg <- sprintf("%s has %s, %s has %s, and %s has %s outlier(s)", 
                       outlier_metrics[1], outlier_counts[1],
                       outlier_metrics[2], outlier_counts[2],
                       outlier_metrics[3], outlier_counts[3])
      }
      
      warning_color <- "#e67e22"  # Orange warning
      
      # Check if any metric has >20% outliers for stronger warning
      if((!is.null(rmse_stats) && rmse_stats$outlier_pct > 20) || 
         (!is.null(r2_stats) && r2_stats$outlier_pct > 20) || 
         (!is.null(mae_stats) && mae_stats$outlier_pct > 20)) {
        warning_color <- "#c0392b"  # Red for severe
      }
      
      return(div(
        class = "alert alert-warning", 
        style = paste0("background-color: #fef3e8; border-left: 4px solid ", warning_color, "; padding: 10px; margin-bottom: 10px;"),
        icon("exclamation-triangle"),
        strong("Outliers Detected on Boxplot: "),
        msg,
        tags$br(),
        tags$small("Points shown in red on the boxplot above are outliers identified using the IQR method (multiplier = 1.5).")
      ))
    } else {
      return(div(
        class = "alert alert-success",
        style = "background-color: #e8f5e9; border-left: 4px solid #27ae60; padding: 10px; margin-bottom: 10px;",
        icon("check-circle"),
        strong("No Outliers: "),
        "No outliers detected in the bootstrap distribution using the IQR method (multiplier = 1.5). The boxplot shows no red points."
      ))
    }
  })
  
  output$selected_model_outlier_stats <- renderPrint({
    bootstrap_vals <- get_selected_model_bootstrap_values()
    if(is.null(bootstrap_vals)) {
      cat("No bootstrap data available.\n")
      return()
    }
    
    rmse_stats <- if(!is.null(bootstrap_vals$rmse)) calculate_boxplot_stats(bootstrap_vals$rmse) else NULL
    r2_stats <- if(!is.null(bootstrap_vals$rsquared)) calculate_boxplot_stats(bootstrap_vals$rsquared) else NULL
    mae_stats <- if(!is.null(bootstrap_vals$mae)) calculate_boxplot_stats(bootstrap_vals$mae) else NULL
    
    has_any_outliers <- (!is.null(rmse_stats) && rmse_stats$n_outliers > 0) ||
      (!is.null(r2_stats) && r2_stats$n_outliers > 0) ||
      (!is.null(mae_stats) && mae_stats$n_outliers > 0)
    
    if(!has_any_outliers) {
      cat("No outliers detected in any metric.\n")
      cat("The boxplot shows no red points.\n")
      cat("\n")
      cat("IQR Method Details:\n")
      cat(paste(rep("─", 40), collapse = ""), "\n")
      cat("Outliers are defined as values outside [Q1 - 1.5*IQR, Q3 + 1.5*IQR]\n")
      cat("All bootstrap values fall within these bounds.")
      return()
    }
    
    cat("OUTLIER DETAILS (Points shown in red on the boxplot)\n")
    cat(paste(rep("═", 50), collapse = ""), "\n\n")
    
    if(!is.null(rmse_stats) && rmse_stats$n_outliers > 0) {
      cat("RMSE Outliers:\n")
      cat(paste(rep("─", 40), collapse = ""), "\n")
      cat(sprintf("  Lower bound: %10.4f\n", rmse_stats$lower_bound))
      cat(sprintf("  Upper bound: %10.4f\n", rmse_stats$upper_bound))
      cat(paste(rep("─", 40), collapse = ""), "\n")
      for(i in seq_along(rmse_stats$outlier_values)) {
        outlier_type <- if(rmse_stats$outlier_values[i] < rmse_stats$lower_bound) "Below Lower Bound" else "Above Upper Bound"
        cat(sprintf("  Outlier %2d: %10.4f  (%s)\n", 
                    i, rmse_stats$outlier_values[i], outlier_type))
      }
      cat("\n")
    }
    
    if(!is.null(r2_stats) && r2_stats$n_outliers > 0) {
      cat("R² Outliers:\n")
      cat(paste(rep("─", 40), collapse = ""), "\n")
      cat(sprintf("  Lower bound: %10.4f\n", r2_stats$lower_bound))
      cat(sprintf("  Upper bound: %10.4f\n", r2_stats$upper_bound))
      cat(paste(rep("─", 40), collapse = ""), "\n")
      for(i in seq_along(r2_stats$outlier_values)) {
        outlier_type <- if(r2_stats$outlier_values[i] < r2_stats$lower_bound) "Below Lower Bound" else "Above Upper Bound"
        cat(sprintf("  Outlier %2d: %10.4f  (%s)\n", 
                    i, r2_stats$outlier_values[i], outlier_type))
      }
      cat("\n")
    }
    
    if(!is.null(mae_stats) && mae_stats$n_outliers > 0) {
      cat("MAE Outliers:\n")
      cat(paste(rep("─", 40), collapse = ""), "\n")
      cat(sprintf("  Lower bound: %10.4f\n", mae_stats$lower_bound))
      cat(sprintf("  Upper bound: %10.4f\n", mae_stats$upper_bound))
      cat(paste(rep("─", 40), collapse = ""), "\n")
      for(i in seq_along(mae_stats$outlier_values)) {
        outlier_type <- if(mae_stats$outlier_values[i] < mae_stats$lower_bound) "Below Lower Bound" else "Above Upper Bound"
        cat(sprintf("  Outlier %2d: %10.4f  (%s)\n", 
                    i, mae_stats$outlier_values[i], outlier_type))
      }
    }
  })
  
  
  # ========================================================================
  # SECTION 6.4: SELECT brnn_optim as default when available
  # ========================================================================
  
  brnn_optim_set_as_default <- reactiveVal(FALSE)
  
  # When brnn_optim is first loaded, set it as the selected model
  # in both the Model Selection radio buttons and Performance dropdown.
  # The delay allows the UI choices to render before selecting.
  observeEvent(models[["brnn_optim"]], {
    req(!is.null(models[["brnn_optim"]]))
    brnn_optim_set_as_default(TRUE)
    
    brnn_display <- if ("brnn_optim" %in% names(model_display_names)) {
      model_display_names[["brnn_optim"]]
    } else {
      "brnn_optim"
    }
    
    shinyjs::delay(800, {
      updateRadioButtons(session, "Choice", selected = brnn_display)
      updateSelectInput(session, "perf_model_choice", selected = "brnn_optim")
    })
  })
  
  
  # ========================================================================
  # ========================================================================
  # SECTION 7: PERFORMANCE EVALUATION
  # ========================================================================
  # ========================================================================
  
  get_resampled_metrics <- function(model) {
    if(is.null(model) || is.null(model$results) || nrow(model$results) == 0) return(NULL)
    best_row <- which.min(model$results[, "RMSE"])
    best_results <- model$results[best_row, ]
    if(is.null(best_results) || length(best_results) == 0) return(NULL)
    resampled_df <- data.frame(Metric = character(), Value = numeric(), stringsAsFactors = FALSE)
    if("RMSE" %in% names(best_results) && !is.na(best_results$RMSE)) resampled_df <- rbind(resampled_df, data.frame(Metric = "RMSE (Bootstrap)", Value = best_results$RMSE))
    if("Rsquared" %in% names(best_results) && !is.na(best_results$Rsquared)) resampled_df <- rbind(resampled_df, data.frame(Metric = "Rsquared (Bootstrap)", Value = best_results$Rsquared))
    if("MAE" %in% names(best_results) && !is.na(best_results$MAE)) resampled_df <- rbind(resampled_df, data.frame(Metric = "MAE (Bootstrap)", Value = best_results$MAE))
    if("RMSESD" %in% names(best_results) && !is.na(best_results$RMSESD)) resampled_df <- rbind(resampled_df, data.frame(Metric = "RMSE Bootstrap SD", Value = best_results$RMSESD))
    if("RsquaredSD" %in% names(best_results) && !is.na(best_results$RsquaredSD)) resampled_df <- rbind(resampled_df, data.frame(Metric = "Rsquared Bootstrap SD", Value = best_results$RsquaredSD))
    if(nrow(resampled_df) == 0) return(NULL)
    return(resampled_df)
  }
  
  observe({
    trained_models <- names(reactiveValuesToList(models))
    trained_models <- trained_models[!sapply(trained_models, function(x) is.null(models[[x]]))]
    if(length(trained_models) > 0) {
      display_choices <- sapply(trained_models, function(m) { if(m %in% names(model_display_names)) return(model_display_names[[m]]) else return(m) })
      names(display_choices) <- trained_models
      updateSelectInput(session, "perf_model_choice", choices = display_choices, selected = isolate(input$perf_model_choice))
    }
  })
  
  observeEvent(input$perf_model_choice, { if(!is.null(input$perf_model_choice) && input$perf_model_choice != "") updateRadioButtons(session, "Choice", selected = input$perf_model_choice) })
  observeEvent(input$Choice, { if(!is.null(input$Choice) && input$Choice != "") updateSelectInput(session, "perf_model_choice", selected = input$Choice) })
  
  getCurrentModel <- reactive({ if(!is.null(input$perf_model_choice) && input$perf_model_choice != "") return(input$perf_model_choice) else if(!is.null(input$Choice) && input$Choice != "") return(input$Choice) else return(NULL) })
  
  get_model_key <- function(display_name) {
    if(is.null(display_name) || display_name == "") return(NULL)
    if(display_name %in% names(models)) return(display_name)
    for(key in names(model_display_names)) { if(!is.null(model_display_names[[key]]) && model_display_names[[key]] == display_name) return(key) }
    return(display_name)
  }
  
  getModelPredictions <- reactive({
    current_model <- getCurrentModel(); req(current_model)
    model_key <- get_model_key(current_model); mod <- models[[model_key]]; req(mod)
    train_data <- getTrainData()
    train_pred <- predict(mod, newdata = train_data)
    train_results <- data.frame(Patient = rownames(train_data), Actual = train_data$Response, Predicted = train_pred, Residual = train_data$Response - train_pred, Dataset = "Train", stringsAsFactors = FALSE)
    test_data <- getTestData()
    test_pred <- predict(mod, newdata = test_data)
    test_results <- data.frame(Patient = rownames(test_data), Actual = test_data$Response, Predicted = test_pred, Residual = test_data$Response - test_pred, Dataset = "Test", stringsAsFactors = FALSE)
    rbind(train_results, test_results)
  })
  
  identify_residual_outliers <- function(values, iqr_multiplier = 1.5) {
    q1 <- quantile(values, 0.25, na.rm = TRUE); q3 <- quantile(values, 0.75, na.rm = TRUE)
    iqr <- q3 - q1; lower_bound <- q1 - iqr_multiplier * iqr; upper_bound <- q3 + iqr_multiplier * iqr
    outliers <- which(values < lower_bound | values > upper_bound)
    return(list(indices = outliers, lower = lower_bound, upper = upper_bound, q1 = q1, q3 = q3, iqr = iqr))
  }
  
  
  # ------------------------------------------------------------------------
  # 7.1 Performance Summary Tab Outputs
  # ------------------------------------------------------------------------
  
  output$perf_metrics_table <- renderUI({
    predictions <- getModelPredictions(); req(nrow(predictions) > 0)
    current_model <- getCurrentModel()
    if(is.null(current_model)) return(HTML('<div class="alert alert-warning">No model selected.</div>'))
    model_key <- get_model_key(current_model)
    if(is.null(model_key) || !(model_key %in% names(models))) return(HTML('<div class="alert alert-warning">Selected model not found.</div>'))
    trained_model <- models[[model_key]]
    if(is.null(trained_model)) return(HTML('<div class="alert alert-warning">Model object is NULL.</div>'))
    
    train_df <- predictions[predictions$Dataset == "Train", ]; test_df <- predictions[predictions$Dataset == "Test", ]
    if(nrow(train_df) == 0 || nrow(test_df) == 0) return(HTML('<div class="alert alert-danger">Insufficient data for evaluation.</div>'))
    
    train_rmse <- sqrt(mean(train_df$Residual^2, na.rm = TRUE)); train_mae <- mean(abs(train_df$Residual), na.rm = TRUE)
    train_r2 <- 1 - sum(train_df$Residual^2, na.rm = TRUE) / sum((train_df$Actual - mean(train_df$Actual, na.rm = TRUE))^2, na.rm = TRUE)
    test_rmse <- sqrt(mean(test_df$Residual^2, na.rm = TRUE)); test_mae <- mean(abs(test_df$Residual), na.rm = TRUE)
    test_r2 <- 1 - sum(test_df$Residual^2, na.rm = TRUE) / sum((test_df$Actual - mean(test_df$Actual, na.rm = TRUE))^2, na.rm = TRUE)
    
    bootstrap_df <- get_resampled_metrics(trained_model)
    boot_rmse <- boot_r2 <- boot_mae <- NA; boot_rmse_sd <- boot_r2_sd <- NA
    if(!is.null(bootstrap_df) && nrow(bootstrap_df) > 0) {
      rmse_row <- which(bootstrap_df$Metric == "RMSE (Bootstrap)"); if(length(rmse_row) > 0) boot_rmse <- bootstrap_df$Value[rmse_row[1]]
      r2_row <- which(bootstrap_df$Metric == "Rsquared (Bootstrap)"); if(length(r2_row) > 0) boot_r2 <- bootstrap_df$Value[r2_row[1]]
      mae_row <- which(bootstrap_df$Metric == "MAE (Bootstrap)"); if(length(mae_row) > 0) boot_mae <- bootstrap_df$Value[mae_row[1]]
      rmse_sd_row <- which(bootstrap_df$Metric == "RMSE Bootstrap SD"); if(length(rmse_sd_row) > 0) boot_rmse_sd <- bootstrap_df$Value[rmse_sd_row[1]]
      r2_sd_row <- which(bootstrap_df$Metric == "Rsquared Bootstrap SD"); if(length(r2_sd_row) > 0) boot_r2_sd <- bootstrap_df$Value[r2_sd_row[1]]
    }
    
    boot_rmse_display <- if(is.na(boot_rmse)) "N/A" else { if(!is.na(boot_rmse_sd)) sprintf("%.4f (±%.4f)", boot_rmse, boot_rmse_sd) else sprintf("%.4f", boot_rmse) }
    boot_r2_display <- if(is.na(boot_r2)) "N/A" else { if(!is.na(boot_r2_sd)) sprintf("%.4f (±%.4f)", boot_r2, boot_r2_sd) else sprintf("%.4f", boot_r2) }
    boot_mae_display <- if(is.na(boot_mae)) "N/A" else sprintf("%.4f", boot_mae)
    
    HTML(paste0('<div class="table-responsive"><table class="table table-striped table-hover table-bordered" style="width:100%;"><thead><tr style="background-color: #2C3E50; color: white;"><th style="text-align: center;">Metric</th><th style="text-align: center;">Training</th><th style="text-align: center;">Bootstrap Training<br><span style="font-size:11px;">(25 iterations)</span></th><th style="text-align: center;">Testing</th></tr></thead><tbody>',
                sprintf('<tr><td style="font-weight: bold;">RMSE</td><td style="text-align: center;">%.4f</td><td style="text-align: center;">%s</td><td style="text-align: center;">%.4f</td></tr>', train_rmse, boot_rmse_display, test_rmse),
                sprintf('<tr><td style="font-weight: bold;">MAE</td><td style="text-align: center;">%.4f</td><td style="text-align: center;">%s</td><td style="text-align: center;">%.4f</td></tr>', train_mae, boot_mae_display, test_mae),
                sprintf('<tr><td style="font-weight: bold;">R²</td><td style="text-align: center;">%.4f</td><td style="text-align: center;">%s</td><td style="text-align: center;">%.4f</td></tr>', train_r2, boot_r2_display, test_r2),
                sprintf('<tr><td style="font-weight: bold;">Observations</td><td style="text-align: center;">%d</td><td style="text-align: center;">Boot25</td><td style="text-align: center;">%d</td></tr>', nrow(train_df), nrow(test_df)),
                '</tbody></table></div>'))
  })
  
  output$perf_comparison_report <- renderUI({
    predictions <- getModelPredictions(); req(nrow(predictions) > 0)
    current_model <- getCurrentModel(); model_key <- get_model_key(current_model); trained_model <- models[[model_key]]
    train_df <- predictions[predictions$Dataset == "Train", ]; test_df <- predictions[predictions$Dataset == "Test", ]
    train_rmse <- sqrt(mean(train_df$Residual^2, na.rm = TRUE)); test_rmse <- sqrt(mean(test_df$Residual^2, na.rm = TRUE))
    train_r2 <- 1 - sum(train_df$Residual^2, na.rm = TRUE) / sum((train_df$Actual - mean(train_df$Actual, na.rm = TRUE))^2, na.rm = TRUE)
    test_r2 <- 1 - sum(test_df$Residual^2, na.rm = TRUE) / sum((test_df$Actual - mean(test_df$Actual, na.rm = TRUE))^2, na.rm = TRUE)
    train_mae <- mean(abs(train_df$Residual), na.rm = TRUE); test_mae <- mean(abs(test_df$Residual), na.rm = TRUE)
    rmse_diff <- test_rmse - train_rmse; r2_diff <- test_r2 - train_r2; mae_diff <- test_mae - train_mae; rmse_pct <- 100 * rmse_diff / train_rmse
    bootstrap_df <- get_resampled_metrics(trained_model); boot_rmse <- boot_rmse_sd <- NA
    if (!is.null(bootstrap_df) && nrow(bootstrap_df) > 0) { r <- which(bootstrap_df$Metric == "RMSE (Bootstrap)"); if (length(r) > 0) boot_rmse <- bootstrap_df$Value[r[1]]; r <- which(bootstrap_df$Metric == "RMSE Bootstrap SD"); if (length(r) > 0) boot_rmse_sd <- bootstrap_df$Value[r[1]] }
    fmt <- function(x, d = 4) if (is.na(x)) "N/A" else sprintf(paste0("%.", d, "f"), x)
    diff_cell <- function(val, positive_is_bad = TRUE) { if (is.na(val)) return('<td style="text-align:right;">N/A</td>'); colour <- if ((positive_is_bad && val > 0) || (!positive_is_bad && val < 0)) "#c0392b" else "#27ae60"; sprintf('<td style="text-align:right; color:%s; font-weight:bold;">%+.4f</td>', colour, val) }
    verdict_colour <- if (abs(rmse_pct) < 10) "#27ae60" else if (rmse_pct > 15) "#c0392b" else if (rmse_pct < -5) "#2980b9" else "#e67e22"
    verdict_text <- if (abs(rmse_pct) < 10) "Good generalisation — model performs consistently across train/test." else if (rmse_pct > 15) "Overfitting warning — test RMSE is >15% higher than training." else if (rmse_pct < -5) "Better on test — model generalises very well to unseen data." else "Acceptable — minor performance drop on test set."
    
    tagList(tags$div(class = "panel panel-default", tags$div(class = "panel-heading", style = "background-color:#2C3E50; color:white; font-weight:bold;", "Train vs Test Comparison"),
                     tags$table(class = "table table-condensed table-bordered", style = "margin-bottom:0; font-size:13px;",
                                tags$thead(tags$tr(style = "background-color:#ecf0f1;", tags$th("Metric"), tags$th(style = "text-align:right;", "Train"), tags$th(style = "text-align:right;", "Test"), tags$th(style = "text-align:right;", "Difference"))),
                                tags$tbody(HTML(paste0(sprintf('<tr><td style="font-weight:bold;">RMSE</td><td style="text-align:right;">%s</td><td style="text-align:right;">%s</td>%s</tr>', fmt(train_rmse), fmt(test_rmse), diff_cell(rmse_diff, TRUE)),
                                                       sprintf('<tr><td style="font-weight:bold;">MAE</td><td style="text-align:right;">%s</td><td style="text-align:right;">%s</td>%s</tr>', fmt(train_mae), fmt(test_mae), diff_cell(mae_diff, TRUE)),
                                                       sprintf('<tr><td style="font-weight:bold;">R²</td><td style="text-align:right;">%s</td><td style="text-align:right;">%s</td>%s</tr>', fmt(train_r2), fmt(test_r2), diff_cell(r2_diff, FALSE)),
                                                       sprintf('<tr><td style="font-weight:bold;">RMSE change (%%)</td><td colspan="2" style="text-align:right;">—</td><td style="text-align:right; color:%s; font-weight:bold;">%+.2f %%</td></tr>', verdict_colour, rmse_pct))))),
                     if (!is.na(boot_rmse)) { tags$div(class = "panel-body", style = "background-color:#eaf4fb; padding:8px 15px; border-top:1px solid #ddd; font-size:12px;", tags$strong("Bootstrap RMSE reference: "), fmt(boot_rmse), if (!is.na(boot_rmse_sd)) paste0(" ± ", fmt(boot_rmse_sd)) else "", tags$span(" (25 iterations)", style = "color:#7f8c8d;")) },
                     tags$div(class = "panel-footer", style = paste0("font-weight:bold; color:", verdict_colour, ";"), verdict_text)))
  })
  
  
  # ------------------------------------------------------------------------
  # 7.2 Sub-tab: Predictions vs Actual
  # ------------------------------------------------------------------------
  
  output$pred_plot <- renderPlotly({
    predictions <- getModelPredictions(); req(nrow(predictions) > 0)
    dataset_choice <- input$pred_display_dataset
    if(dataset_choice == "train") plot_df <- predictions[predictions$Dataset == "Train", ]
    else if(dataset_choice == "test") plot_df <- predictions[predictions$Dataset == "Test", ]
    else plot_df <- predictions
    plot_df <- na.omit(plot_df); if(nrow(plot_df) == 0) return(plot_ly() %>% add_annotations(text = "No valid data"))
    plot_df$hover_text <- paste0("<b>Patient:</b> ", plot_df$Patient, "<br><b>Actual:</b> ", round(plot_df$Actual, 3),
                                 "<br><b>Predicted:</b> ", round(plot_df$Predicted, 3), "<br><b>Residual:</b> ", round(plot_df$Residual, 3))
    plot_ly() %>% add_trace(data = plot_df, x = ~Actual, y = ~Predicted, color = ~Dataset, type = "scatter", mode = "markers",
                            marker = list(size = 8, opacity = 0.7), text = ~hover_text, hoverinfo = "text",
                            colors = c("Train" = "#13D4D4", "Test" = "#e74c3c")) %>%
      add_trace(x = range(plot_df$Actual, na.rm = TRUE), y = range(plot_df$Actual, na.rm = TRUE), type = "scatter",
                mode = "lines", line = list(dash = "dash", color = "gray50", width = 2), name = "Perfect Prediction (y = x)",
                hoverinfo = "none", showlegend = TRUE) %>%
      layout(title = list(text = "Predicted vs Actual Values", font = list(size = 16, color = "#2C3E50")),
             xaxis = list(title = "Actual Values", gridcolor = "#e0e0e0"), yaxis = list(title = "Predicted Values", gridcolor = "#e0e0e0"),
             legend = list(orientation = "h", yanchor = "bottom", y = -0.15, xanchor = "center", x = 0.5),
             plot_bgcolor = "#f8f9fa", paper_bgcolor = "#ffffff", hovermode = "closest")
  })
  
  output$pred_stats <- renderPrint({
    predictions <- getModelPredictions(); req(nrow(predictions) > 0)
    dataset_choice <- input$pred_display_dataset %||% "both"
    stats_df <- switch(dataset_choice, train = predictions[predictions$Dataset == "Train", ], test = predictions[predictions$Dataset == "Test", ], predictions)
    stats_df <- na.omit(stats_df); if (nrow(stats_df) == 0) { cat("No valid data to display\n"); return() }
    ds_label <- switch(dataset_choice, train = "Train only", test = "Test only", "Train + Test")
    rmse <- sqrt(mean(stats_df$Residual^2)); mae <- mean(abs(stats_df$Residual)); r2 <- 1 - sum(stats_df$Residual^2) / sum((stats_df$Actual - mean(stats_df$Actual))^2); corr <- cor(stats_df$Actual, stats_df$Predicted)
    cat(paste(rep("─", 55), collapse = ""), "\n"); cat("  PREDICTION STATISTICS\n"); cat(paste(rep("─", 55), collapse = ""), "\n")
    stats_row <- function(label, value, width = 35) { lbl <- formatC(label, width = -width, flag = "-"); cat(sprintf("  %s %s\n", lbl, value)) }
    stats_row("Model:", input$Choice); stats_row("Dataset:", ds_label); stats_row("Observations:", nrow(stats_df))
    cat(paste(rep("─", 55), collapse = ""), "\n")
    stats_row("RMSE:", sprintf("%.4f", rmse)); stats_row("MAE:", sprintf("%.4f", mae)); stats_row("R²:", sprintf("%.4f", r2)); stats_row("Correlation (actual vs predicted):", sprintf("%.4f", corr))
    cat(paste(rep("─", 55), collapse = ""), "\n")
  })
  
  
  # ------------------------------------------------------------------------
  # 7.3 Sub-tab: Residual Scatter Plot
  # ------------------------------------------------------------------------
  
  output$residual_plot <- renderPlotly({
    predictions <- getModelPredictions(); req(nrow(predictions) > 0)
    iqr_mult <- input$residual_iqr_slider %||% 1.5; dataset_choice <- input$residual_display_dataset %||% "both"
    if(dataset_choice == "train") plot_df <- predictions[predictions$Dataset == "Train", ]
    else if(dataset_choice == "test") plot_df <- predictions[predictions$Dataset == "Test", ]
    else plot_df <- predictions
    plot_df <- na.omit(plot_df); if(nrow(plot_df) == 0) return(plot_ly() %>% add_annotations(text = "No valid data"))
    plot_df$Residual <- as.numeric(as.character(plot_df$Residual)); plot_df$Predicted <- as.numeric(as.character(plot_df$Predicted))
    plot_df <- plot_df[!is.na(plot_df$Residual) & !is.na(plot_df$Predicted), ]
    if(nrow(plot_df) == 0) return(plot_ly() %>% add_annotations(text = "No valid numeric data"))
    
    # FIXED: Calculate outliers separately for Train and Test even when combined
    plot_df$IsOutlier <- FALSE
    # Process Train set
    train_idx <- which(plot_df$Dataset == "Train")
    if(length(train_idx) > 0) {
      train_residuals <- plot_df$Residual[train_idx]
      q1_train <- quantile(train_residuals, 0.25, na.rm = TRUE)
      q3_train <- quantile(train_residuals, 0.75, na.rm = TRUE)
      iqr_train <- q3_train - q1_train
      lower_train <- q1_train - iqr_mult * iqr_train
      upper_train <- q3_train + iqr_mult * iqr_train
      train_outliers <- train_residuals < lower_train | train_residuals > upper_train
      plot_df$IsOutlier[train_idx[train_outliers]] <- TRUE
      # Store bounds for display (use Train bounds for the horizontal lines when both are shown)
      if(dataset_choice == "both") {
        lower_bound_display <- lower_train
        upper_bound_display <- upper_train
      }
    }
    # Process Test set
    test_idx <- which(plot_df$Dataset == "Test")
    if(length(test_idx) > 0) {
      test_residuals <- plot_df$Residual[test_idx]
      q1_test <- quantile(test_residuals, 0.25, na.rm = TRUE)
      q3_test <- quantile(test_residuals, 0.75, na.rm = TRUE)
      iqr_test <- q3_test - q1_test
      lower_test <- q1_test - iqr_mult * iqr_test
      upper_test <- q3_test + iqr_mult * iqr_test
      test_outliers <- test_residuals < lower_test | test_residuals > upper_test
      plot_df$IsOutlier[test_idx[test_outliers]] <- TRUE
      # Store bounds for display when only Test is shown
      if(dataset_choice == "test") {
        lower_bound_display <- lower_test
        upper_bound_display <- upper_test
      }
    }
    # Set display bounds
    if(dataset_choice == "train" && length(train_idx) > 0) {
      lower_bound_display <- lower_train
      upper_bound_display <- upper_train
    } else if(dataset_choice == "test" && length(test_idx) > 0) {
      lower_bound_display <- lower_test
      upper_bound_display <- upper_test
    } else if(dataset_choice == "both") {
      # For "both", we already set from Train (or could use Test - your choice)
      if(!exists("lower_bound_display")) lower_bound_display <- lower_test
      if(!exists("upper_bound_display")) upper_bound_display <- upper_test
    }
    
    plot_df$hover_text <- paste0("<b>Patient:</b> ", plot_df$Patient, "<br><b>Dataset:</b> ", plot_df$Dataset,
                                 "<br><b>Residual:</b> ", round(plot_df$Residual, 4), "<br><b>Predicted:</b> ", round(plot_df$Predicted, 3),
                                 "<br><b>Actual:</b> ", round(plot_df$Actual, 3), "<br><b>Outlier:</b> ", ifelse(plot_df$IsOutlier, "YES", "NO"))
    plot_ly() %>% add_trace(data = plot_df, x = ~Predicted, y = ~Residual, color = ~Dataset, type = "scatter", mode = "markers",
                            marker = list(size = 8, opacity = 0.7), text = ~hover_text, hoverinfo = "text",
                            colors = c("Train" = "#13D4D4", "Test" = "#e74c3c")) %>%
      add_trace(x = range(plot_df$Predicted, na.rm = TRUE), y = c(upper_bound_display, upper_bound_display), type = "scatter", mode = "lines",
                line = list(dash = "dot", color = "red", width = 1.5), name = paste("Upper Bound (IQR ×", sprintf("%.1f", iqr_mult), ")"),
                hoverinfo = "text", text = paste("Upper Bound:", round(upper_bound_display, 4))) %>%
      add_trace(x = range(plot_df$Predicted, na.rm = TRUE), y = c(lower_bound_display, lower_bound_display), type = "scatter", mode = "lines",
                line = list(dash = "dot", color = "red", width = 1.5), name = paste("Lower Bound (IQR ×", sprintf("%.1f", iqr_mult), ")"),
                hoverinfo = "text", text = paste("Lower Bound:", round(lower_bound_display, 4))) %>%
      add_trace(x = range(plot_df$Predicted, na.rm = TRUE), y = c(0, 0), type = "scatter", mode = "lines",
                line = list(dash = "dash", color = "gray50", width = 1), name = "Zero Residual Line", hoverinfo = "none") %>%
      layout(title = list(text = paste("Residual Analysis - IQR Multiplier:", sprintf("%.1f", iqr_mult)), font = list(size = 16, color = "#2C3E50")),
             xaxis = list(title = "Predicted Values", gridcolor = "#e0e0e0"), yaxis = list(title = "Residuals", gridcolor = "#e0e0e0"),
             legend = list(orientation = "h", yanchor = "bottom", y = -0.2, xanchor = "center", x = 0.5),
             plot_bgcolor = "#f8f9fa", paper_bgcolor = "#ffffff", hovermode = "closest")
  })
  
  output$residual_stats <- renderPrint({
    predictions <- getModelPredictions()
    req(nrow(predictions) > 0)
    
    iqr_mult      <- input$residual_iqr_slider %||% 1.5
    dataset_choice <- input$residual_display_dataset %||% "both"
    
    stats_df <- switch(dataset_choice,
                       train = predictions[predictions$Dataset == "Train", ],
                       test  = predictions[predictions$Dataset == "Test",  ],
                       predictions)
    stats_df <- na.omit(stats_df)
    if(nrow(stats_df) == 0) { cat("No valid data to display\n"); return() }
    
    stats_df$Residual <- as.numeric(as.character(stats_df$Residual))
    stats_df <- stats_df[!is.na(stats_df$Residual), ]
    
    W     <- 66
    inner <- W - 2
    
    pad <- function(label, value) {
      content <- paste0("  ", sprintf("%-28s", label), value)
      cat(paste0("\u2551", formatC(content, width = -inner, flag = "-"), "\u2551\n"))
    }
    
    cat(paste0("\u2554", paste(rep("\u2550", inner), collapse = ""), "\u2557\n"))
    title <- "RESIDUAL STATISTICS"
    cat(paste0("\u2551", formatC(title, width = -inner, flag = "-"), "\u2551\n"))
    cat(paste0("\u2560", paste(rep("\u2550", inner), collapse = ""), "\u2563\n"))
    
    ds_label <- switch(dataset_choice, train = "Train Only", test = "Test Only", "Train + Test")
    pad("Model:",           input$Choice)
    pad("Dataset:",         ds_label)
    pad("IQR Multiplier:",  sprintf("%.1f", iqr_mult))
    
    cat(paste0("\u2560", paste(rep("\u2550", inner), collapse = ""), "\u2563\n"))
    
    # FIXED: Always show per-dataset statistics when both datasets are present
    if(dataset_choice == "both") {
      # Show Train statistics
      train_df <- stats_df[stats_df$Dataset == "Train", ]
      if(nrow(train_df) > 0) {
        pad("--- TRAIN SET ---", "")
        q1_train <- quantile(train_df$Residual, 0.25, na.rm = TRUE)
        q3_train <- quantile(train_df$Residual, 0.75, na.rm = TRUE)
        iqr_train <- q3_train - q1_train
        lower_train <- q1_train - iqr_mult * iqr_train
        upper_train <- q3_train + iqr_mult * iqr_train
        train_outliers <- sum(train_df$Residual < lower_train | train_df$Residual > upper_train)
        
        pad("Mean Residual:",    sprintf("%.4f", mean(train_df$Residual)))
        pad("Median Residual:",  sprintf("%.4f", median(train_df$Residual)))
        pad("SD of Residuals:",  sprintf("%.4f", sd(train_df$Residual)))
        pad("Min Residual:",     sprintf("%.4f", min(train_df$Residual)))
        pad("Max Residual:",     sprintf("%.4f", max(train_df$Residual)))
        pad("Q1 (25th pct):",    sprintf("%.4f", q1_train))
        pad("Q3 (75th pct):",    sprintf("%.4f", q3_train))
        pad("IQR:",              sprintf("%.4f", iqr_train))
        pad("Lower Bound:",      sprintf("%.4f", lower_train))
        pad("Upper Bound:",      sprintf("%.4f", upper_train))
        pad("Number of Outliers:", train_outliers)
        cat(paste0("\u2560", paste(rep("\u2550", inner), collapse = ""), "\u2563\n"))
      }
      
      # Show Test statistics
      test_df <- stats_df[stats_df$Dataset == "Test", ]
      if(nrow(test_df) > 0) {
        pad("--- TEST SET ---", "")
        q1_test <- quantile(test_df$Residual, 0.25, na.rm = TRUE)
        q3_test <- quantile(test_df$Residual, 0.75, na.rm = TRUE)
        iqr_test <- q3_test - q1_test
        lower_test <- q1_test - iqr_mult * iqr_test
        upper_test <- q3_test + iqr_mult * iqr_test
        test_outliers <- sum(test_df$Residual < lower_test | test_df$Residual > upper_test)
        
        pad("Mean Residual:",    sprintf("%.4f", mean(test_df$Residual)))
        pad("Median Residual:",  sprintf("%.4f", median(test_df$Residual)))
        pad("SD of Residuals:",  sprintf("%.4f", sd(test_df$Residual)))
        pad("Min Residual:",     sprintf("%.4f", min(test_df$Residual)))
        pad("Max Residual:",     sprintf("%.4f", max(test_df$Residual)))
        pad("Q1 (25th pct):",    sprintf("%.4f", q1_test))
        pad("Q3 (75th pct):",    sprintf("%.4f", q3_test))
        pad("IQR:",              sprintf("%.4f", iqr_test))
        pad("Lower Bound:",      sprintf("%.4f", lower_test))
        pad("Upper Bound:",      sprintf("%.4f", upper_test))
        pad("Number of Outliers:", test_outliers)
      }
    } else {
      # Single dataset case (Train only or Test only)
      outlier_info <- identify_residual_outliers(stats_df$Residual, iqr_mult)
      pad("Mean Residual:",    sprintf("%.4f", mean(stats_df$Residual)))
      pad("Median Residual:",  sprintf("%.4f", median(stats_df$Residual)))
      pad("SD of Residuals:",  sprintf("%.4f", sd(stats_df$Residual)))
      pad("Min Residual:",     sprintf("%.4f", min(stats_df$Residual)))
      pad("Max Residual:",     sprintf("%.4f", max(stats_df$Residual)))
      pad("Q1 (25th pct):",    sprintf("%.4f", outlier_info$q1))
      pad("Q3 (75th pct):",    sprintf("%.4f", outlier_info$q3))
      pad("IQR:",              sprintf("%.4f", outlier_info$iqr))
      pad("Lower Bound:",      sprintf("%.4f", outlier_info$lower))
      pad("Upper Bound:",      sprintf("%.4f", outlier_info$upper))
      pad("Number of Outliers:", length(outlier_info$indices))
    }
    
    cat(paste0("\u255a", paste(rep("\u2550", inner), collapse = ""), "\u255d\n"))
  })
  
  
  # ------------------------------------------------------------------------
  # Residual Outliers Table for Residual Analysis Tab
  # ------------------------------------------------------------------------
  
  output$residual_outliers <- DT::renderDT({
    predictions <- getModelPredictions()
    req(nrow(predictions) > 0)
    
    iqr_mult <- input$residual_iqr_slider %||% 1.5
    dataset_choice <- input$residual_display_dataset %||% "both"
    
    # Filter by dataset choice
    if(dataset_choice == "train") {
      plot_df <- predictions[predictions$Dataset == "Train", ]
    } else if(dataset_choice == "test") {
      plot_df <- predictions[predictions$Dataset == "Test", ]
    } else {
      plot_df <- predictions
    }
    
    plot_df <- na.omit(plot_df)
    if(nrow(plot_df) == 0) {
      return(datatable(data.frame(Message = "No valid data available"), 
                       options = list(dom = 't'), rownames = FALSE))
    }
    
    # Convert to numeric
    plot_df$Residual <- as.numeric(as.character(plot_df$Residual))
    plot_df <- plot_df[!is.na(plot_df$Residual), ]
    
    if(nrow(plot_df) == 0) {
      return(datatable(data.frame(Message = "No valid residual data"), 
                       options = list(dom = 't'), rownames = FALSE))
    }
    
    # FIXED: Identify outliers separately for each dataset present
    plot_df$IsOutlier <- FALSE
    plot_df$LowerBound <- NA
    plot_df$UpperBound <- NA
    
    # Process Train if present
    if(any(plot_df$Dataset == "Train")) {
      train_idx <- which(plot_df$Dataset == "Train")
      train_residuals <- plot_df$Residual[train_idx]
      q1_train <- quantile(train_residuals, 0.25, na.rm = TRUE)
      q3_train <- quantile(train_residuals, 0.75, na.rm = TRUE)
      iqr_train <- q3_train - q1_train
      lower_train <- q1_train - iqr_mult * iqr_train
      upper_train <- q3_train + iqr_mult * iqr_train
      train_outliers <- train_residuals < lower_train | train_residuals > upper_train
      plot_df$IsOutlier[train_idx[train_outliers]] <- TRUE
      plot_df$LowerBound[train_idx] <- lower_train
      plot_df$UpperBound[train_idx] <- upper_train
    }
    
    # Process Test if present
    if(any(plot_df$Dataset == "Test")) {
      test_idx <- which(plot_df$Dataset == "Test")
      test_residuals <- plot_df$Residual[test_idx]
      q1_test <- quantile(test_residuals, 0.25, na.rm = TRUE)
      q3_test <- quantile(test_residuals, 0.75, na.rm = TRUE)
      iqr_test <- q3_test - q1_test
      lower_test <- q1_test - iqr_mult * iqr_test
      upper_test <- q3_test + iqr_mult * iqr_test
      test_outliers <- test_residuals < lower_test | test_residuals > upper_test
      plot_df$IsOutlier[test_idx[test_outliers]] <- TRUE
      plot_df$LowerBound[test_idx] <- lower_test
      plot_df$UpperBound[test_idx] <- upper_test
    }
    
    outliers_df <- plot_df[plot_df$IsOutlier == TRUE, ]
    
    if(nrow(outliers_df) == 0) {
      return(datatable(data.frame(Message = paste("No outliers detected with IQR multiplier =", iqr_mult)), 
                       options = list(dom = 't'), rownames = FALSE))
    }
    
    # Prepare outlier table
    outlier_table <- data.frame(
      Patient = outliers_df$Patient,
      Dataset = outliers_df$Dataset,
      Actual = round(outliers_df$Actual, 4),
      Predicted = round(outliers_df$Predicted, 4),
      Residual = round(outliers_df$Residual, 4),
      Direction = ifelse(outliers_df$Residual < outliers_df$LowerBound, "Below", "Above"),
      stringsAsFactors = FALSE
    )
    
    # Sort by absolute residual (largest first)
    outlier_table <- outlier_table[order(-abs(outlier_table$Residual)), ]
    
    datatable(outlier_table,
              extensions = 'Buttons',
              options = list(
                dom = 'Bfrtip',
                buttons = c('copy', 'csv', 'excel', 'print'),
                pageLength = 1000,
                scrollX = TRUE,
                order = list(list(4, 'desc'))
              ),
              rownames = FALSE,
              class = 'display compact stripe hover'
    ) %>%
      formatStyle("Residual",
                  background = styleColorBar(outlier_table$Residual, "#ffffff"),
                  backgroundSize = '100% 90%',
                  backgroundRepeat = 'no-repeat',
                  backgroundPosition = 'center') %>%
      formatStyle("Dataset",
                  backgroundColor = styleEqual(c("Train", "Test"), c("#13D4D4", "#e74c3c"))) %>%
      formatStyle("Direction",
                  backgroundColor = styleEqual(c("Below", "Above"), c("#E6E6FA", "#ffcccc"))) %>%
      formatRound(columns = c("Actual", "Predicted", "Residual"), digits = 4)
  })
  
  
  
  # ------------------------------------------------------------------------
  # 7.4 Sub-tab: Residual Boxplot
  # ------------------------------------------------------------------------
  
  output$residual_boxplot <- renderPlotly({
    predictions <- getModelPredictions(); req(nrow(predictions) > 0)
    iqr_mult <- input$residual_boxplot_iqr_slider %||% 1.5; dataset_choice <- input$residual_boxplot_dataset %||% "both"
    show_train_box <- input$residual_boxplot_show_train_box %||% TRUE; show_test_box <- input$residual_boxplot_show_test_box %||% TRUE
    show_train_points <- input$residual_boxplot_show_train_points %||% TRUE; show_test_points <- input$residual_boxplot_show_test_points %||% TRUE
    
    if(dataset_choice == "train") plot_df <- predictions[predictions$Dataset == "Train", ]
    else if(dataset_choice == "test") plot_df <- predictions[predictions$Dataset == "Test", ]
    else plot_df <- predictions
    
    plot_df <- na.omit(plot_df); if(nrow(plot_df) == 0) return(plot_ly() %>% add_annotations(text = "No valid data"))
    plot_df$Residual <- as.numeric(as.character(plot_df$Residual)); plot_df <- plot_df[!is.na(plot_df$Residual), ]
    
    # FIXED: Identify outliers separately for Train and Test (consistent with scatter plot)
    plot_df$IsOutlier <- FALSE
    
    # Process Train set separately
    train_idx <- which(plot_df$Dataset == "Train")
    if(length(train_idx) > 0) {
      train_residuals <- plot_df$Residual[train_idx]
      q1_train <- quantile(train_residuals, 0.25, na.rm = TRUE)
      q3_train <- quantile(train_residuals, 0.75, na.rm = TRUE)
      iqr_train <- q3_train - q1_train
      lower_train <- q1_train - iqr_mult * iqr_train
      upper_train <- q3_train + iqr_mult * iqr_train
      train_outliers <- train_residuals < lower_train | train_residuals > upper_train
      plot_df$IsOutlier[train_idx[train_outliers]] <- TRUE
    }
    
    # Process Test set separately
    test_idx <- which(plot_df$Dataset == "Test")
    if(length(test_idx) > 0) {
      test_residuals <- plot_df$Residual[test_idx]
      q1_test <- quantile(test_residuals, 0.25, na.rm = TRUE)
      q3_test <- quantile(test_residuals, 0.75, na.rm = TRUE)
      iqr_test <- q3_test - q1_test
      lower_test <- q1_test - iqr_mult * iqr_test
      upper_test <- q3_test + iqr_mult * iqr_test
      test_outliers <- test_residuals < lower_test | test_residuals > upper_test
      plot_df$IsOutlier[test_idx[test_outliers]] <- TRUE
    }
    
    plot_df$hover_text_points <- paste0(
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n  PATIENT OBSERVATION\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n  Patient ID:   ", plot_df$Patient, "\n  Dataset:      ", plot_df$Dataset, "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n  Actual Value:    ", round(plot_df$Actual, 3), "\n  Predicted Value: ", round(plot_df$Predicted, 3), "\n  Residual:        ", round(plot_df$Residual, 4), "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n  Outlier:      ", ifelse(plot_df$IsOutlier, "YES", "NO"), "\n", ifelse(plot_df$IsOutlier, paste0("  IQR Multiplier: ", sprintf("%.1f", iqr_mult), "\n"), ""), "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    )
    
    train_data <- plot_df[plot_df$Dataset == "Train", ]; test_data <- plot_df[plot_df$Dataset == "Test", ]
    
    p <- ggplot()
    if(show_train_box && nrow(train_data) > 0) { 
      p <- p + geom_boxplot(data = train_data, aes(x = 0, y = Residual, group = 1), 
                            fill = "#13D4D4", alpha = 0.4, color = "black", width = 0.35, outlier.shape = NA) 
    }
    if(show_test_box && nrow(test_data) > 0) { 
      p <- p + geom_boxplot(data = test_data, aes(x = 1, y = Residual, group = 1), 
                            fill = "#e74c3c", alpha = 0.4, color = "black", width = 0.35, outlier.shape = NA) 
    }
    if(show_train_points && nrow(train_data) > 0) { 
      train_non_outliers <- train_data[!train_data$IsOutlier, ]; 
      if(nrow(train_non_outliers) > 0) { 
        p <- p + geom_point(data = train_non_outliers, aes(x = 0.4, y = Residual, text = hover_text_points), 
                            color = "black", size = 2, alpha = 0.6, stroke = 0.5, shape = 21, fill = "#13D4D4") 
      }; 
      train_outliers_pts <- train_data[train_data$IsOutlier, ]; 
      if(nrow(train_outliers_pts) > 0) { 
        p <- p + geom_point(data = train_outliers_pts, aes(x = 0.4, y = Residual, text = hover_text_points), 
                            color = "#FF8C00", size = 2.5, alpha = 1, stroke = 1.0, shape = 21, fill = "#13D4D4") 
      } 
    }
    if(show_test_points && nrow(test_data) > 0) { 
      test_non_outliers <- test_data[!test_data$IsOutlier, ]; 
      if(nrow(test_non_outliers) > 0) { 
        p <- p + geom_point(data = test_non_outliers, aes(x = 1.4, y = Residual, text = hover_text_points), 
                            color = "black", size = 2, alpha = 0.6, stroke = 0.5, shape = 21, fill = "#e74c3c") 
      }; 
      test_outliers_pts <- test_data[test_data$IsOutlier, ]; 
      if(nrow(test_outliers_pts) > 0) { 
        p <- p + geom_point(data = test_outliers_pts, aes(x = 1.4, y = Residual, text = hover_text_points), 
                            color = "#FF8C00", size = 2.5, alpha = 1, stroke = 1.0, shape = 21, fill = "#e74c3c") 
      } 
    }
    
    p <- p + scale_x_continuous(breaks = c(0, 1), labels = c("Train", "Test"), limits = c(-0.6, 1.9)) +
      labs(title = paste("Residual Boxplot - IQR Multiplier:", sprintf("%.1f", iqr_mult)), x = NULL, y = "Residuals") +
      theme_minimal() + theme(plot.title = element_text(hjust = 0.5, size = 16, color = "#2C3E50", face = "bold"), axis.title = element_text(size = 12, color = "#2C3E50"), axis.text = element_text(size = 11, color = "#2C3E50"), panel.grid.major = element_line(color = "#e0e0e0", size = 0.5), panel.grid.minor = element_blank(), panel.background = element_rect(fill = "#f8f9fa", color = NA), plot.background = element_rect(fill = "#ffffff", color = NA), legend.position = "bottom")
    
    ggplotly(p, tooltip = "text") %>% layout(hoverlabel = list(bgcolor = "white", font = list(size = 11, family = "monospace", color = "black"), bordercolor = "#333", borderwidth = 1), legend = list(orientation = "h", yanchor = "bottom", y = -0.15, xanchor = "center", x = 0.5))
  })
  
  output$residual_boxplot_stats <- renderPrint({
    predictions <- getModelPredictions()
    req(nrow(predictions) > 0)
    
    iqr_mult       <- input$residual_boxplot_iqr_slider %||% 1.5
    dataset_choice  <- input$residual_boxplot_dataset %||% "both"
    
    stats_df <- switch(dataset_choice,
                       train = predictions[predictions$Dataset == "Train", ],
                       test  = predictions[predictions$Dataset == "Test",  ],
                       predictions)
    stats_df <- na.omit(stats_df)
    if(nrow(stats_df) == 0) { cat("No valid data.\n"); return() }
    
    stats_df$Residual <- as.numeric(as.character(stats_df$Residual))
    stats_df <- stats_df[!is.na(stats_df$Residual), ]
    
    get_box_stats <- function(vals, mult) {
      q1  <- quantile(vals, 0.25, na.rm = TRUE)
      q3  <- quantile(vals, 0.75, na.rm = TRUE)
      iqr <- q3 - q1
      lo  <- q1 - mult * iqr
      hi  <- q3 + mult * iqr
      out <- vals[vals < lo | vals > hi]
      list(min = min(vals, na.rm = TRUE), q1 = q1, med = median(vals, na.rm = TRUE),
           q3 = q3, max = max(vals, na.rm = TRUE), iqr = iqr,
           lo = lo, hi = hi, n = length(vals),
           n_out = length(out), outlier_values = head(out, 5))
    }
    
    W     <- 57
    inner <- W - 2
    rule  <- paste(rep("\u2500", inner), collapse = "")
    
    cat(paste0("\u250c", rule, "\u2510\n"))
    title <- "  RESIDUAL BOXPLOT STATISTICS"
    cat(paste0("\u2502", formatC(title, width = -inner, flag = "-"), "\u2502\n"))
    cat(paste0("\u251c", rule, "\u2524\n"))
    
    row2 <- function(label, value) {
      content <- sprintf("  %-28s %s", label, as.character(value))
      cat(paste0("\u2502", formatC(content, width = -inner, flag = "-"), "\u2502\n"))
    }
    
    row2("Model:",           input$Choice)
    row2("IQR Multiplier:",  sprintf("%.1f", iqr_mult))
    
    for(dset in c("Train", "Test")) {
      dd <- stats_df[stats_df$Dataset == dset, ]
      if(nrow(dd) == 0) next
      s <- get_box_stats(dd$Residual, iqr_mult)
      
      cat(paste0("\u251c", rule, "\u2524\n"))
      section <- paste0("  ", dset, " Set")
      cat(paste0("\u2502", formatC(section, width = -inner, flag = "-"), "\u2502\n"))
      cat(paste0("\u251c", rule, "\u2524\n"))
      
      row2("Min:",         sprintf("%.4f", s$min))
      row2("Q1:",          sprintf("%.4f", s$q1))
      row2("Median:",      sprintf("%.4f", s$med))
      row2("Q3:",          sprintf("%.4f", s$q3))
      row2("Max:",         sprintf("%.4f", s$max))
      row2("IQR:",         sprintf("%.4f", s$iqr))
      row2("Lower Bound:", sprintf("%.4f", s$lo))
      row2("Upper Bound:", sprintf("%.4f", s$hi))
      row2("Observations:",     s$n)
      row2("Outliers:",    s$n_out)
      
      if(s$n_out > 0 && length(s$outlier_values) > 0) {
        cat(paste0("\u2502", formatC("  Outlier values (first 5):", width = -inner, flag = "-"), "\u2502\n"))
        for(ov in s$outlier_values) {
          content <- sprintf("    %.4f", ov)
          cat(paste0("\u2502", formatC(content, width = -inner, flag = "-"), "\u2502\n"))
        }
      }
    }
    
    cat(paste0("\u2514", rule, "\u2518\n"))
  })
  
  # ------------------------------------------------------------------------
  # Residual Outliers Table for Residual Boxplot Tab
  # ------------------------------------------------------------------------
  
  output$residual_boxplot_outliers <- DT::renderDT({
    predictions <- getModelPredictions()
    req(nrow(predictions) > 0)
    
    iqr_mult <- input$residual_boxplot_iqr_slider %||% 1.5
    dataset_choice <- input$residual_boxplot_dataset %||% "both"
    
    # Filter by dataset choice
    if(dataset_choice == "train") {
      plot_df <- predictions[predictions$Dataset == "Train", ]
    } else if(dataset_choice == "test") {
      plot_df <- predictions[predictions$Dataset == "Test", ]
    } else {
      plot_df <- predictions
    }
    
    plot_df <- na.omit(plot_df)
    if(nrow(plot_df) == 0) {
      return(datatable(data.frame(Message = "No valid data available"), 
                       options = list(dom = 't'), rownames = FALSE))
    }
    
    # Convert to numeric
    plot_df$Residual <- as.numeric(as.character(plot_df$Residual))
    plot_df <- plot_df[!is.na(plot_df$Residual), ]
    
    if(nrow(plot_df) == 0) {
      return(datatable(data.frame(Message = "No valid residual data"), 
                       options = list(dom = 't'), rownames = FALSE))
    }
    
    # FIXED: Identify outliers separately for each dataset (matching boxplot logic)
    plot_df$IsOutlier <- FALSE
    plot_df$LowerBound <- NA
    plot_df$UpperBound <- NA
    
    # Process Train if present
    if(any(plot_df$Dataset == "Train")) {
      train_idx <- which(plot_df$Dataset == "Train")
      train_residuals <- plot_df$Residual[train_idx]
      q1_train <- quantile(train_residuals, 0.25, na.rm = TRUE)
      q3_train <- quantile(train_residuals, 0.75, na.rm = TRUE)
      iqr_train <- q3_train - q1_train
      lower_train <- q1_train - iqr_mult * iqr_train
      upper_train <- q3_train + iqr_mult * iqr_train
      train_outliers <- train_residuals < lower_train | train_residuals > upper_train
      plot_df$IsOutlier[train_idx[train_outliers]] <- TRUE
      plot_df$LowerBound[train_idx] <- lower_train
      plot_df$UpperBound[train_idx] <- upper_train
    }
    
    # Process Test if present
    if(any(plot_df$Dataset == "Test")) {
      test_idx <- which(plot_df$Dataset == "Test")
      test_residuals <- plot_df$Residual[test_idx]
      q1_test <- quantile(test_residuals, 0.25, na.rm = TRUE)
      q3_test <- quantile(test_residuals, 0.75, na.rm = TRUE)
      iqr_test <- q3_test - q1_test
      lower_test <- q1_test - iqr_mult * iqr_test
      upper_test <- q3_test + iqr_mult * iqr_test
      test_outliers <- test_residuals < lower_test | test_residuals > upper_test
      plot_df$IsOutlier[test_idx[test_outliers]] <- TRUE
      plot_df$LowerBound[test_idx] <- lower_test
      plot_df$UpperBound[test_idx] <- upper_test
    }
    
    all_outliers <- plot_df[plot_df$IsOutlier == TRUE, ]
    
    if(nrow(all_outliers) == 0) {
      return(datatable(data.frame(Message = paste("No outliers detected with IQR multiplier =", iqr_mult)), 
                       options = list(dom = 't'), rownames = FALSE))
    }
    
    # Add Direction column using dataset-specific bounds
    all_outliers$Direction <- ifelse(all_outliers$Residual < all_outliers$LowerBound, "Below", "Above")
    
    # Prepare outlier table
    outlier_table <- data.frame(
      Patient = all_outliers$Patient,
      Dataset = all_outliers$Dataset,
      Actual = round(as.numeric(all_outliers$Actual), 4),
      Predicted = round(as.numeric(all_outliers$Predicted), 4),
      Residual = round(as.numeric(all_outliers$Residual), 4),
      Direction = all_outliers$Direction,
      stringsAsFactors = FALSE
    )
    
    # Sort by absolute residual (largest first)
    outlier_table <- outlier_table[order(-abs(outlier_table$Residual)), ]
    
    # Create datatable
    datatable(outlier_table,
              extensions = 'Buttons',
              options = list(
                dom = 'Bfrtip',
                buttons = c('copy', 'csv', 'excel', 'print'),
                pageLength = 1000,
                scrollX = TRUE,
                order = list(list(4, 'desc'))
              ),
              rownames = FALSE,
              class = 'display compact stripe hover'
    ) %>%
      formatStyle("Residual",
                  background = styleColorBar(outlier_table$Residual, "#ffffff"),
                  backgroundSize = '100% 90%',
                  backgroundRepeat = 'no-repeat',
                  backgroundPosition = 'center') %>%
      formatStyle("Dataset",
                  backgroundColor = styleEqual(c("Train", "Test"), c("#13D4D4", "#e74c3c"))) %>%
      formatStyle("Direction",
                  backgroundColor = styleEqual(c("Below", "Above"), c("#E6E6FA", "#ffcccc"))) %>%
      formatRound(columns = c("Actual", "Predicted", "Residual"), digits = 4)
  })
  
  
  
  
  # ========================================================================
  # ========================================================================
  # SECTION 8: DOWNLOAD HANDLERS
  # ========================================================================
  # ========================================================================
  
  output$download_data <- downloadHandler(
    filename = function() { paste("dataset_", Sys.Date(), ".csv", sep = "") },
    content = function(file) { write.csv(getData(), file, row.names = TRUE) }
  )
  
  
  # ========================================================================
  # SECTION: METRICS EXTRACTION HELPER (FIXED - STANDARDIZED COLUMNS)
  # ========================================================================
  
  extract_all_metrics <- function(model, model_name) {
    if (is.null(model) || is.null(model$results) || nrow(model$results) == 0) {
      return(NULL)
    }
    
    best_row <- model$results[which.min(model$results[["RMSE"]]), , drop = FALSE]
    
    # Base metrics always present
    result <- data.frame(
      Model = model_name,
      Method = model$method %||% model_name,
      RMSE = if ("RMSE" %in% names(best_row)) round(best_row$RMSE, 4) else NA_real_,
      RMSESD = if ("RMSESD" %in% names(best_row)) round(best_row$RMSESD, 4) else NA_real_,
      Rsquared = if ("Rsquared" %in% names(best_row)) round(best_row$Rsquared, 4) else NA_real_,
      RsquaredSD = if ("RsquaredSD" %in% names(best_row)) round(best_row$RsquaredSD, 4) else NA_real_,
      MAE = if ("MAE" %in% names(best_row)) round(best_row$MAE, 4) else NA_real_,
      MAESD = if ("MAESD" %in% names(best_row)) round(best_row$MAESD, 4) else NA_real_,
      stringsAsFactors = FALSE
    )
    
    # Add tuning parameters as a SINGLE combined string column
    # This avoids column name mismatches between different model types
    if (!is.null(model$bestTune) && nrow(model$bestTune) > 0) {
      param_parts <- c()
      for (param_name in names(model$bestTune)) {
        param_value <- model$bestTune[[param_name]]
        if (is.numeric(param_value)) {
          param_parts <- c(param_parts, paste0(param_name, "=", round(param_value, 4)))
        } else {
          param_parts <- c(param_parts, paste0(param_name, "=", as.character(param_value)))
        }
      }
      result$BestTune <- paste(param_parts, collapse = ", ")
    } else {
      result$BestTune <- "(none)"
    }
    
    # Add training time if available
    if (!is.null(training_times[[model_name]])) {
      result$Train_Time_sec <- training_times[[model_name]]
    } else {
      result$Train_Time_sec <- NA_real_
    }
    
    result
  }
  
  
  # ========================================================================
  # SECTION: TRAINING SUMMARY TABLE (UPDATED)
  # ========================================================================
  
  getTrainingSummary <- reactive({
    all_models <- names(reactiveValuesToList(models))
    all_models <- all_models[!sapply(all_models, function(x) is.null(models[[x]]))]
    
    if (length(all_models) == 0) return(NULL)
    
    summary_list <- lapply(all_models, function(model_name) {
      training_metrics[[model_name]]
    })
    
    # Remove NULL entries
    summary_list <- summary_list[!sapply(summary_list, is.null)]
    
    if (length(summary_list) == 0) return(NULL)
    
    # Ensure all data frames have the same columns before binding
    # Get all unique column names across all models
    all_cols <- unique(unlist(lapply(summary_list, names)))
    
    # Standardize each data frame to have all columns
    summary_list_std <- lapply(summary_list, function(df) {
      for (col in all_cols) {
        if (!col %in% names(df)) {
          df[[col]] <- NA
        }
      }
      return(df[, all_cols, drop = FALSE])
    })
    
    # Now safe to rbind
    summary_df <- do.call(rbind, summary_list_std)
    
    if (!is.null(summary_df) && nrow(summary_df) > 0) {
      # Format time display
      if ("Train_Time_sec" %in% names(summary_df)) {
        summary_df$Train_Time <- sapply(summary_df$Train_Time_sec, function(sec) {
          if (is.na(sec)) return("N/A")
          if (sec < 60) return(paste0(round(sec, 1), "s"))
          return(paste0(floor(sec/60), "m ", round(sec %% 60, 1), "s"))
        })
      }
      
      # Order by RMSE
      if ("RMSE" %in% names(summary_df)) {
        summary_df <- summary_df[order(summary_df$RMSE, na.last = TRUE), ]
      }
    }
    
    summary_df
  })
  
  output$training_summary_table <- DT::renderDT({
    df <- getTrainingSummary()
    
    validate(need(!is.null(df) && nrow(df) > 0,
                  "No trained or loaded models yet. Train or load at least one model to see the summary."))
    
    # Define display columns (always present)
    base_display_cols <- c("Model", "Method", "RMSE", "RMSESD", "Rsquared", "RsquaredSD", "MAE", "MAESD", "BestTune")
    
    # Add time column if it exists and has any non-NA values
    display_cols <- base_display_cols
    if ("Train_Time" %in% names(df) && any(!is.na(df$Train_Time) & df$Train_Time != "N/A")) {
      display_cols <- c(display_cols, "Train_Time")
    }
    
    # Only keep columns that actually exist in the data frame
    display_cols <- display_cols[display_cols %in% names(df)]
    
    df_display <- df[, display_cols, drop = FALSE]
    
    # Rename columns for better display
    colnames(df_display) <- gsub("_", " ", colnames(df_display))
    colnames(df_display)[colnames(df_display) == "Rsquared"] <- "R²"
    colnames(df_display)[colnames(df_display) == "RsquaredSD"] <- "R² SD"
    
    DT::datatable(
      df_display,
      extensions = c("Buttons", "FixedHeader"),
      options = list(
        dom = "Bfrtip",
        buttons = c("copy", "csv", "excel", "print"),
        pageLength = 50,
        fixedHeader = TRUE,
        scrollX = TRUE,
        order = list(list(which(names(df_display) == "RMSE") - 1, "asc"))
      ),
      rownames = FALSE,
      class = "display compact stripe hover"
    ) %>%
      DT::formatRound(
        columns = intersect(names(df_display), c("RMSE", "RMSESD", "R²", "R² SD", "MAE", "MAESD")),
        digits = 4
      )
  })
  
  # ========================================================================
  # TRAINING TIME PLOT (UPDATED)
  # ========================================================================
  
  output$training_time_plot <- renderPlot({
    df <- getTrainingSummary()
    validate(need(!is.null(df) && nrow(df) > 0, "No trained models yet."))
    
    # Filter to models with timing data
    if ("Train_Time_sec" %in% names(df)) {
      timed_df <- df[!is.na(df$Train_Time_sec) & df$Train_Time_sec > 0, ]
    } else {
      timed_df <- data.frame()
    }
    
    validate(need(nrow(timed_df) > 0, "No timing data available for trained models."))
    
    timed_df <- timed_df[order(timed_df$Train_Time_sec, decreasing = TRUE), ]
    timed_df$Model <- factor(timed_df$Model, levels = timed_df$Model)
    
    # Use Method column for coloring, or Model if Method not available
    fill_col <- if ("Method" %in% names(timed_df)) "Method" else "Model"
    
    ggplot(timed_df, aes(x = Model, y = Train_Time_sec, fill = .data[[fill_col]])) +
      geom_col(alpha = 0.85, width = 0.7) +
      geom_text(aes(label = Train_Time), hjust = -0.1, size = 3) +
      coord_flip() +
      scale_y_continuous(expand = expansion(mult = c(0, 0.2))) +
      labs(
        title = "Training Time by Model",
        x = NULL,
        y = "Elapsed seconds",
        fill = "Method Family"
      ) +
      theme_minimal(base_size = 11) +
      theme(
        plot.title = element_text(hjust = 0, colour = "#2C3E50", face = "bold", size = 13),
        axis.text.y = element_text(size = 9),
        legend.position = "bottom",
        panel.grid.major.y = element_blank()
      )
  })
  
  
  
  
  
})  # FINAL CLOSING BRACKET FOR shinyServer
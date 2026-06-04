server <- function(input, output, session) {
  
  
  # ============================================================================
  # INITIALISATION
  # ============================================================================
  
  
  # Identify numeric and categorical variables
  get_variable_types <- function() {
    list(
      numeric = setdiff(names(df)[sapply(df, is.numeric)], "ID"),
      categorical = setdiff(names(df)[sapply(df, is.factor)], "ID")
    )
  }
  
  # Update all UI pickers when app starts
  observe({
    
    vars <- get_variable_types()
    
    # -------------------------------------------------------------------------
    # Boxplot pickers
    # -------------------------------------------------------------------------
   
    updatePickerInput(
      session, "numeric_vars",
      choices  = vars$numeric,
      selected = vars$numeric  # Select ALL numeric variables
    )
    
    updatePickerInput(
      session, "categorical_vars",
      choices  = vars$categorical,
      selected = vars$categorical  # Select ALL categorical variables
    )
    
    # -------------------------------------------------------------------------
    # Correlation pickers
    # -------------------------------------------------------------------------
    
    updatePickerInput(
      session, "corr_numeric_vars",
      choices  = vars$numeric,
      selected = vars$numeric  # Select ALL numeric variables
    )
    
    updatePickerInput(
      session, "corr_categorical_vars",
      choices  = vars$categorical,
      selected = vars$categorical  # Select ALL categorical variables
    )
    
    # -------------------------------------------------------------------------
    # Missing values pickers
    # -------------------------------------------------------------------------
    
    updatePickerInput(
      session, "mv_numeric_vars",
      choices  = vars$numeric,
      selected = vars$numeric  # Select ALL numeric variables
    )
    
    updatePickerInput(
      session, "mv_categorical_vars",
      choices  = vars$categorical,
      selected = vars$categorical  # Select ALL categorical variables
    )
    
    # -------------------------------------------------------------------------
    # Rising values pickers - y, sensors 4, 8, 11, 16, 22, 24, 28
    # -------------------------------------------------------------------------
    
    rising_defaults <- c("Y", "sensor4", "sensor8", "sensor11", "sensor16", "sensor22", "sensor24", "sensor28")
    
    rising_selected <- intersect(rising_defaults, vars$numeric)
    
    updatePickerInput(
      session, "rv_numeric_vars",
      choices  = vars$numeric,
      selected = rising_selected
    )
    
    updatePickerInput(
      session, "rv_categorical_vars",
      choices  = vars$categorical,
      selected = vars$categorical  # Select ALL categorical variables
    )
    
    # -------------------------------------------------------------------------
    # Time Series pickers 
    # -------------------------------------------------------------------------
    
    updatePickerInput(
      session, "ts_numeric_vars",
      choices  = vars$numeric,
      selected = NULL  # Empty - user selects
    )
    
    updatePickerInput(
      session, "ts_categorical_vars",
      choices  = vars$categorical,
      selected = NULL  # Empty - user selects
    )
    
    # -------------------------------------------------------------------------
    # Tabplot pickers - Y, sensors 1, 4, 6, and all categorical variables
    # -------------------------------------------------------------------------
    tabplot_numeric_defaults <- c("Y", "sensor1", "sensor4", "sensor6")
    tabplot_numeric_selected <- intersect(tabplot_numeric_defaults, vars$numeric)
    
    updatePickerInput(
      session, "tabplot_numeric_vars",
      choices = vars$numeric,
      selected = tabplot_numeric_selected
    )
    
    updatePickerInput(
      session, "tabplot_categorical_vars",
      choices = vars$categorical,
      selected = vars$categorical  # All categorical variables
    )
    
    # -------------------------------------------------------------------------
    # Mosaic pickers - location, price, operator
    # -------------------------------------------------------------------------

    categorical_vars <- vars$categorical
    
    # Default selections - check if they exist
    mosaic_x_default <- if("Location" %in% categorical_vars) "Location" else 
      if("location" %in% categorical_vars) "location" else
        categorical_vars[1]
    
    mosaic_y_default <- if("Price" %in% categorical_vars) "Price" else 
      if("price" %in% categorical_vars) "price" else
        if(length(categorical_vars) >= 2) categorical_vars[2] else categorical_vars[1]
    
    mosaic_z_default <- if("Operator" %in% categorical_vars) "Operator" else 
      if("operator" %in% categorical_vars) "operator" else "None"
    
    updateSelectInput(session, "mosaic_x",
                      choices = categorical_vars,
                      selected = mosaic_x_default)
    
    updateSelectInput(session, "mosaic_y",
                      choices = categorical_vars,
                      selected = mosaic_y_default)
    
    # Z and W optional variables
    all_cat <- c("None", categorical_vars)
    
    updateSelectInput(session, "mosaic_z",
                      choices = all_cat,
                      selected = mosaic_z_default)
    
    updateSelectInput(session, "mosaic_w",
                      choices = all_cat,
                      selected = "None")
    
    # -------------------------------------------------------------------------
    # GGpairs pickers - Y, sensors 1, 2, 4, 6, 11 coloured by operator
    # -------------------------------------------------------------------------
   
    ggpairs_numeric_defaults <- c("Y", "sensor1", "sensor2", "sensor4", "sensor6", "sensor11")
    ggpairs_numeric_selected <- intersect(ggpairs_numeric_defaults, vars$numeric)
    
    updatePickerInput(
      session, "ggpairs_numeric_vars",
      choices  = vars$numeric,
      selected = ggpairs_numeric_selected
    )
    
    # Keep categorical empty initially
    updatePickerInput(
      session, "ggpairs_categorical_vars",
      choices  = vars$categorical,
      selected = NULL
    )
    
    # Colour options for ggpairs - set operator as default 
    color_choices <- names(df)[
      sapply(df, function(x) is.factor(x) && nlevels(x) <= 10)
    ]
    
    operator_default <- if("Operator" %in% color_choices) "Operator" else
      if("operator" %in% color_choices) "operator" else "None"
    
    updateSelectInput(
      session, "ggpairs_color",
      choices  = c("None", color_choices),
      selected = operator_default
    )
  })
  
  
  # ============================================================================
  # GLOBAL SIDEBAR TOGGLE
  # ============================================================================
  
  
  sidebar_visible <- reactiveVal(TRUE)
  
  # Function to apply sidebar state to all wrappers
  apply_sidebar_state <- function(visible) {
    wrappers <- c(
      "boxplot_wrapper",
      "correlation_wrapper",
      "mv_wrapper",
      "rv_wrapper",
      "ts_wrapper",   
      "tabplot_wrapper",
      "mosaic_wrapper",
      "ggpairs_wrapper",
      "datatable_wrapper"
    )
    
    if (visible) {
      # Show sidebars - remove hidden class
      for (w in wrappers) {
        tryCatch({
          shinyjs::removeClass(id = w, class = "sidebar-hidden")
        }, error = function(e) {})
      }
      updateActionButton(session, "toggle_sidebar_all",
                         label = HTML('<i class="fa fa-sliders-h"></i> Hide Filters'))
    } else {
      # Hide sidebars - add hidden class
      for (w in wrappers) {
        tryCatch({
          shinyjs::addClass(id = w, class = "sidebar-hidden")
        }, error = function(e) {})
      }
      updateActionButton(session, "toggle_sidebar_all",
                         label = HTML('<i class="fa fa-sliders-h"></i> Show Filters'))
    }
  }
  
  # Toggle sidebar when button is clicked
  observeEvent(input$toggle_sidebar_all, {
    new_state <- !sidebar_visible()
    sidebar_visible(new_state)
    apply_sidebar_state(new_state)
  })
  
  # Reapply sidebar state when tab changes
  observeEvent(input$navbar, {
    # Small delay to ensure DOM is ready
    delay(100, {
      apply_sidebar_state(sidebar_visible())
    })
  })
  
  # Also reapply when any wrapper might be re-rendered
  observe({
    # This runs whenever any of these inputs change
    # It helps catch cases where modules re-render
    list(
      input$boxplot_wrapper,
      input$correlation_wrapper,
      input$mv_wrapper,
      input$rv_wrapper,
      input$ts_wrapper,
      input$tabplot_wrapper,
      input$mosaic_wrapper,
      input$ggpairs_wrapper,
      input$datatable_wrapper
    )
    
    # Small delay to ensure DOM updates
    delay(50, {
      apply_sidebar_state(sidebar_visible())
    })
  })
  
  
  # ============================================================================
  # UTILITY FUNCTIONS
  # ============================================================================
  
  
  # ---- General categorical filter function ----
  
  apply_categorical_filters <- function(data, vars,
                                        filter_prefix,
                                        include_null = FALSE) {
    
    for (var in vars) {
      sel <- input[[paste0(filter_prefix, var)]]
      if (!is.null(sel) && length(sel) > 0) {
        if ("NA" %in% sel) {
          sel_real <- setdiff(sel, "NA")

          if (include_null) {
            data <- data[
              data[[var]] %in% sel_real | is.na(data[[var]]), ]
          } else {
            data <- data[
              data[[var]] %in% sel_real, ]
          }
          
        } else {
          data <- data[data[[var]] %in% sel, ]
          if (!include_null) {
            data <- data[!is.na(data[[var]]), ]
          }
        }
      }
    }
    data
  }
  
  # ---- Simplified filter (Rising Values) ----
  
  apply_simple_categorical_filters <- function(data, vars) {
    for (var in vars) {
      sel <- input[[paste0("rv_filter_", var)]]
      if (!is.null(sel) && length(sel) > 0) {
        data <- data[
          data[[var]] %in% sel | is.na(data[[var]]), ]
      }
    }
    data
  }
  
  # ---- Date filter ----
  
  apply_date_filter <- function(data, date_range_input) {
    if (!is.null(input[[date_range_input]])) {
      data <- data[
        data$Date >= input[[date_range_input]][1] &
          data$Date <= input[[date_range_input]][2],
      ]
    }
    data
  }
  
  
  # ---- Format date range for titles ----
  
  get_date_range_text <- function(date_range) {
    paste(
      format(date_range[1], "%d-%m-%Y"),
      "to",
      format(date_range[2], "%d-%m-%Y")
    )
  }
  
  
  # ============================================================================
  # SUMMARY MODULE
  # ============================================================================
  
  # Row count
  output$summary_row_count <- renderText({
    format(nrow(df), big.mark = ",")
  })
  
  # Column count
  output$summary_col_count <- renderText({
    ncol(df)
  })
  
  # Total cells (rows × columns)
  output$summary_total_cells <- renderText({
    format(nrow(df) * ncol(df), big.mark = ",")
  })
  
  # Non-NA values (actual data points)
  output$summary_non_na_values <- renderText({
    non_na <- sum(!is.na(df))
    format(non_na, big.mark = ",")
  })
  
  # Missing values count
  output$summary_missing_count <- renderText({
    missing <- sum(is.na(df))
    format(missing, big.mark = ",")
  })
  
  # Complete cases
  output$summary_complete_cases <- renderUI({
    complete <- sum(complete.cases(df))
    total <- nrow(df)
    percent <- round(complete/total * 100, 1)
    
    div(
      div(class = "stat-value", format(complete, big.mark = ",")),
      div(class = "stat-label", paste0("Complete Rows (", percent, "%)"))
    )
  })
  
  # Incomplete cases
  output$summary_incomplete_cases <- renderUI({
    incomplete <- sum(!complete.cases(df))
    total <- nrow(df)
    percent <- round(incomplete/total * 100, 1)
    
    div(
      div(class = "stat-value", format(incomplete, big.mark = ",")),
      div(class = "stat-label", paste0("Rows with Missing Values (", percent, "%)"))
    )
  })
  
  # Missing cells summary
  output$summary_missing_cells <- renderUI({
    missing <- sum(is.na(df))
    total <- nrow(df) * ncol(df)
    percent <- round(missing/total * 100, 1)
    
    div(
      div(class = "stat-value", format(missing, big.mark = ",")),
      div(class = "stat-label", paste0("Missing Cells (", percent, "%)"))
    )
  })
  
  # Data completeness
  output$summary_data_completeness <- renderUI({
    non_na <- sum(!is.na(df))
    total <- nrow(df) * ncol(df)
    percent <- round(non_na/total * 100, 1)
    
    div(
      div(class = "stat-value", paste0(percent, "%")),
      div(class = "stat-label", "Data Completeness")
    )
  })
  
  # Quick date range
  output$summary_date_range_quick <- renderUI({
    date_min <- min(df$Date, na.rm = TRUE)
    date_max <- max(df$Date, na.rm = TRUE)
    days <- as.numeric(difftime(date_max, date_min, units = "days"))
    
    div(
      div(class = "stat-value", paste0(format(date_min, "%d/%m/%Y"), " - ", format(date_max, "%d/%m/%Y"))),
      div(class = "stat-label", paste0("Date Range (", days, " days)"))
    )
  })
  
  # Numeric variables count
  output$summary_numeric_count <- renderUI({
    num_count <- sum(sapply(df, is.numeric))
    total <- ncol(df)
    percent <- round(num_count/total * 100, 1)
    
    div(
      div(class = "stat-value", num_count),
      div(class = "stat-label", paste0("Numeric Variables (", percent, "%)"))
    )
  })
  
  # Categorical variables count
  output$summary_categorical_count <- renderUI({
    cat_count <- sum(sapply(df, is.factor))
    total <- ncol(df)
    percent <- round(cat_count/total * 100, 1)
    
    div(
      div(class = "stat-value", cat_count),
      div(class = "stat-label", paste0("Categorical Variables (", percent, "%)"))
    )
  })
  
  # -------------------------
  # Dataset Overview Table
  # -------------------------
  
  output$summary_overview_table <- renderDT({
    datatable(
      df,
      options = list(
        scrollX = TRUE,
        pageLength = 10,
        lengthMenu = list(
          c(5, 10, 15, 25, 50, 100, -1),
          c('5', '10', '15', '25', '50', '100', 'All')  
        ),
        dom = 'lftip',  # Controls: length menu, filter, table, info, pagination
        order = list(list(0, 'asc')), 
        columnDefs = list(
          list(className = 'dt-center', targets = '_all')
        )
      ),
      rownames = FALSE,
      class = 'cell-border stripe hover display nowrap',
      filter = 'top',
      selection = 'none'
    )
  })
  
  # -------------------------
  # Variable Types Table
  # -------------------------
  
  output$summary_variable_types_table <- renderDT({
    var_types <- data.frame(
      Variable = names(df),
      Type = sapply(df, function(x) {
        if(is.numeric(x)) "Numeric"
        else if(is.factor(x)) if(is.ordered(x)) "Ordered Factor" else "Factor"
        else if(inherits(x, "Date")) "Date"
        else class(x)[1]
      }),
      `Unique Values` = sapply(df, function(x) {
        if(is.factor(x)) nlevels(x)
        else if(is.character(x)) length(unique(x))
        else if(is.numeric(x)) length(unique(na.omit(x)))
        else NA
      }),
      `Sample Values` = sapply(df, function(x) {
        if(is.factor(x)) {
          n_lev <- nlevels(x)
          if(n_lev > 5) paste0(paste(head(levels(x),3), collapse=", "), "...")
          else paste(levels(x), collapse=", ")
        } else if(is.numeric(x)) paste(sort(unique(na.omit(head(x,3)))), collapse=", ")
        else if(inherits(x, "Date")) paste(format(unique(na.omit(head(x,2))), "%Y-%m-%d"), collapse=", ")
        else "-"
      }),
      check.names = FALSE
    )
    
    datatable(
      var_types,
      options = list(
        pageLength = 15,
        scrollX = TRUE,
        columnDefs = list(
          list(minWidth='150px', targets=0),
          list(minWidth='120px', targets=1),
          list(minWidth='100px', targets=2),
          list(minWidth='250px', targets=3)
        )
      ),
      rownames = FALSE,
      class = 'cell-border stripe hover display nowrap'
    ) %>%
      formatStyle(columns=1:4, fontSize='14px', padding='8px')
  })
  
  # -------------------------
  # Numeric Variables Table
  # -------------------------
  
  output$summary_numeric_table <- renderDT({
    numeric_vars <- names(df)[sapply(df, is.numeric)]
    if(length(numeric_vars)==0) return(
      datatable(data.frame(Message="No numeric variables found"), options=list(pageLength=1, dom='t'), rownames=FALSE)
    )
    
    num_summary <- data.frame(
      Variable = numeric_vars,
      Min = round(sapply(df[numeric_vars], min, na.rm=TRUE),2),
      Q1 = round(sapply(df[numeric_vars], function(x) quantile(x,0.25,na.rm=TRUE)),2),
      Median = round(sapply(df[numeric_vars], median, na.rm=TRUE),2),
      Mean = round(sapply(df[numeric_vars], mean, na.rm=TRUE),2),
      Q3 = round(sapply(df[numeric_vars], function(x) quantile(x,0.75,na.rm=TRUE)),2),
      Max = round(sapply(df[numeric_vars], max, na.rm=TRUE),2),
      SD = round(sapply(df[numeric_vars], sd, na.rm=TRUE),2),
      `Missing Count` = as.integer(sapply(df[numeric_vars], function(x) sum(is.na(x)))),
      `Missing (%)` = paste0(round(sapply(df[numeric_vars], function(x) mean(is.na(x))*100),1), "%"),
      check.names = FALSE
    )
    
    datatable(
      num_summary,
      options=list(scrollX=TRUE, pageLength=15,
                   columnDefs=list(
                     list(minWidth='150px', targets=0),
                     list(minWidth='80px', targets=1:7),
                     list(minWidth='100px', targets=8:9)
                   )),
      rownames=FALSE,
      class='cell-border stripe hover display nowrap'
    ) %>% formatStyle(columns=1:10, fontSize='14px', padding='8px')
  })
  
  # ------------------------------
  # Categorical Variables Table
  # ------------------------------
  
  output$summary_categorical_table <- renderDT({
    categorical_vars <- names(df)[sapply(df, is.factor)]
    if(length(categorical_vars)==0) return(
      datatable(data.frame(Message="No categorical variables found"), options=list(pageLength=1, dom='t'), rownames=FALSE)
    )
    
    cat_summary <- data.frame(
      Variable = categorical_vars,
      Type = ifelse(sapply(df[categorical_vars], is.ordered),"Ordered","Unordered"),
      `Cardinality` = as.integer(sapply(df[categorical_vars], nlevels)),
      `Most Frequent Level` = sapply(df[categorical_vars], function(x) {
        if(all(is.na(x))) NA else names(which.max(table(x)))
      }),
      `Top Frequency (%)` = paste0(round(sapply(df[categorical_vars], function(x) {
        if(all(is.na(x))) NA else max(table(x))/length(x)*100
      }),1), "%"),
      `Missing Count` = as.integer(sapply(df[categorical_vars], function(x) sum(is.na(x)))),
      `Missing (%)` = paste0(round(sapply(df[categorical_vars], function(x) mean(is.na(x))*100),1), "%"),
      check.names = FALSE
    )
    
    datatable(
      cat_summary,
      options=list(scrollX=TRUE, pageLength=15,
                   columnDefs=list(
                     list(minWidth='150px', targets=0),
                     list(minWidth='100px', targets=1),
                     list(minWidth='80px', targets=2),
                     list(minWidth='200px', targets=3),
                     list(minWidth='120px', targets=4),
                     list(minWidth='100px', targets=5:6)
                   )),
      rownames=FALSE,
      class='cell-border stripe hover display nowrap'
    ) %>% formatStyle(columns=1:7, fontSize='14px', padding='8px')
  })
  
  # -------------------------
  # Missing Values Table
  # -------------------------
  
  output$summary_missing_table <- renderDT({
    missing_by_var <- data.frame(
      Variable = names(df),
      `Missing Count` = as.integer(sapply(df, function(x) sum(is.na(x)))),
      `Missing (%)` = paste0(round(sapply(df, function(x) mean(is.na(x))*100),1), "%"),
      `Data Type` = sapply(df, function(x) {
        if(is.numeric(x)) "Numeric"
        else if(is.factor(x)) "Factor"
        else if(inherits(x,"Date")) "Date"
        else class(x)[1]
      }),
      check.names = FALSE
    )
    
    missing_by_var <- missing_by_var[order(missing_by_var$`Missing Count`, decreasing=TRUE), ]
    
    datatable(
      missing_by_var,
      options=list(scrollX=TRUE, pageLength=15,
                   columnDefs=list(
                     list(minWidth='150px', targets=0),
                     list(minWidth='100px', targets=1:3)
                   )),
      rownames=FALSE,
      class='cell-border stripe hover display nowrap'
    ) %>%
      formatStyle(columns=1:4,fontSize='14px',padding='8px') %>%
      formatStyle(
        'Missing Count',
        backgroundColor = styleInterval(
          c(0,10,100),
          c('#1fc600','#fffb05','#f0750f','#f04a3d' )
        )
      )
  })
  
  # -------------------------
  # Date Range Summary
  # -------------------------
  
  output$summary_date_range <- renderPrint({
    date_cols <- names(df)[sapply(df, function(x) inherits(x, "Date"))]
    if(length(date_cols)==0) {cat("No date variable found in dataset."); return()}
    
    cat("Date Range Information\n=====================\n\n")
    
    for(date_col in date_cols){
      date_min <- min(df[[date_col]], na.rm=TRUE)
      date_max <- max(df[[date_col]], na.rm=TRUE)
      date_range <- as.numeric(difftime(date_max, date_min, units="days"))
      
      cat(sprintf("%-20s: %s\n", "Date variable", date_col))
      cat(sprintf("%-20s: %s\n", "Minimum date", format(date_min,"%d-%m-%Y")))
      cat(sprintf("%-20s: %s\n", "Maximum date", format(date_max,"%d-%m-%Y")))
      cat(sprintf("%-20s: %s days\n", "Date range spans", format(date_range, big.mark=",")))
      
      years <- format(df[[date_col]], "%Y")
      year_counts <- table(years, useNA="ifany")
      cat("\nObservations by year:\n")
      print(year_counts)
      cat("\n")
    }
  })
  
  # -------------------------
  # Summarytools dfSummary
  # -------------------------
  
  output$summary_dfsummary <- renderUI({
    tryCatch({
      if(!requireNamespace("summarytools", quietly = TRUE)) {
        return(HTML(paste0(
          "<div class='alert alert-warning'>",
          "<strong>Package not installed:</strong> 'summarytools' is required for this view.<br>",
          "Please install it using: <code>install.packages('summarytools')</code>",
          "</div>"
        )))
      }
      
      # Generate dfSummary
      summary_df <- summarytools::dfSummary(
        df,
        graph.col = FALSE,  
        valid.col = TRUE,
        silent = TRUE,
        style = "grid",      
        plain.ascii = FALSE,
        headings = FALSE,    
        method = 'render',
        footnote = NA        
      )
      
      # Convert to HTML
      html_output <- capture.output(
        print(summary_df, 
              method = 'render',
              bootstrap.css = FALSE,
              silent = TRUE)
      )
      
      # Combine and return as HTML
      HTML(paste(html_output, collapse = "\n"))
      
    }, error = function(e) {
      # Fallback if summarytools fails
      HTML(paste0(
        "<div class='alert alert-danger'>",
        "<strong>Error generating summary:</strong> ", e$message, "<br><br>",
        "<strong>Basic dataset info:</strong><br>",
        "• Rows: ", nrow(df), "<br>",
        "• Columns: ", ncol(df), "<br>",
        "• Complete cases: ", sum(complete.cases(df)), "<br>",
        "• Memory size: ", format(object.size(df), units = "auto"),
        "</div>"
      ))
    })
  })
  
  
  # ============================================================================
  # BOXPLOT MODULE
  # ============================================================================
  
  
  # ---- Filter UI ----
  
  output$categorical_filters <- renderUI({
    req(input$categorical_vars)
    
    tagList(
      lapply(input$categorical_vars, function(var) {
        
        choices <- levels(df[[var]])
        if(any(is.na(df[[var]]))) choices <- c(choices, "NA")
        
        default_selected <- if(input$include_null_boxplot) {
          choices 
        } else {
          choices[choices != "NA"]
        }
        
        checkboxGroupInput(
          inputId = paste0("filter_", var),
          label = paste("Select levels for", var, ":"),
          choices = choices,
          selected = default_selected
        )
      })
    )
  })
  
  # ---- Data Filtering ----
  
  filtered_data <- reactive({
    data <- df
    
    data <- apply_categorical_filters(
      data, 
      input$categorical_vars, 
      "filter_", 
      input$include_null_boxplot
    )
    
    data <- apply_date_filter(data, "date_range")
    data
  })
  
  # ---- Data Transfomration ----
  
  boxplot_data <- reactive({
    req(input$numeric_vars)
    
    data <- filtered_data()[, input$numeric_vars, drop = FALSE]
    
    if(input$center_data || input$scale_data) {
      data <- as.data.frame(
        scale(data, 
              center = input$center_data, 
              scale = input$scale_data)
      )
    }
    
    tidyr::pivot_longer(
      data, 
      cols = everything(), 
      names_to = "variable", 
      values_to = "value"
    ) %>%
      dplyr::mutate(
        variable = factor(variable, levels = input$numeric_vars)
      )
  })
  
  # ---- Outlier Detection ----
  
  add_outlier_flags <- function(data, iqr_multiplier) {
    data %>%
      dplyr::group_by(variable) %>%
      dplyr::mutate(
        Q1 = quantile(value, 0.25, na.rm = TRUE),
        Q3 = quantile(value, 0.75, na.rm = TRUE),
        IQR = Q3 - Q1,
        lower_bound = Q1 - iqr_multiplier * IQR,
        upper_bound = Q3 + iqr_multiplier * IQR,
        is_outlier = value < lower_bound | value > upper_bound
      ) %>%
      dplyr::ungroup()
  }
  
  # ---- Plot Rendering ----
  
  output$boxplot <- renderPlotly({
    df_plot <- boxplot_data()
    outlier_data <- add_outlier_flags(df_plot, input$iqr_multiplier)
    
    # Split data
    non_outliers <- outlier_data %>% dplyr::filter(!is_outlier)
    outliers <- outlier_data %>% dplyr::filter(is_outlier)
    
    # Calculate stats
    outlier_counts <- outlier_data %>%
      dplyr::group_by(variable) %>%
      dplyr::summarise(
        n_outliers = sum(is_outlier, na.rm = TRUE),
        n_total = n(),
        pct_outliers = round(100 * n_outliers / n_total, 1)
      )
    
    # Build title components
    transform_text <- case_when(
      input$center_data && input$scale_data ~ "(Centered & Scaled)",
      input$center_data ~ "(Centered)",
      input$scale_data ~ "(Scaled)",
      TRUE ~ ""
    )
    
    null_text <- if(input$include_null_boxplot) {
      " | NULL values included"
    } else {
      " | NULL values excluded"
    }
    
    date_text <- paste("Date Range:", get_date_range_text(input$date_range))
    
    # Create base plot
    p <- ggplot() +
      
      # Boxplots for non-outliers
      geom_boxplot(
        data = non_outliers,
        aes(
          x = variable, 
          y = value,
          text = paste(
            "Variable:", variable,
            "<br>Value:", round(value, 2),
            "<br>Type: Non-outlier"
          )
        ), 
        fill = "lightblue", 
        color = "darkblue", 
        coef = input$iqr_multiplier, 
        outlier.shape = NA
      ) +
      
      # Points for outliers
      geom_point(
        data = outliers,
        aes(
          x = variable, 
          y = value,
          text = paste(
            "Variable:", variable,
            "<br>Value:", round(value, 2),
            "<br>Type: Outlier"
          )
        ), 
        color = "red", 
        size = 2, 
        alpha = 0.7, 
        position = position_identity()
      ) +
      
      # Flip coordinates for horizontal display
      coord_flip() +
      
      # Labels
      labs(
        title = paste(
          "Horizontal Boxplots | IQR Multiplier:", 
          input$iqr_multiplier, 
          transform_text
        ),
        subtitle = paste(
          sum(outlier_counts$n_outliers), 
          "outliers detected", 
          null_text, 
          "\n", 
          date_text
        ),
        y = ifelse(
          input$center_data | input$scale_data, 
          "Standardized Value", 
          "Value"
        ),
        x = "Variable"
      ) +
      
      # Theme
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, color = "gray50", size = 10)
      )
    
    # Convert to plotly
    ggplotly(p, tooltip = "text") %>% 
      layout(
        hoverlabel = list(
          bgcolor = "white", 
          font = list(size = 12)
        )
      )
  })
  
  # ---- Observation Counter ----
  
  output$obs_count <- renderText({
    filtered <- filtered_data()
    numeric_data <- filtered[, input$numeric_vars, drop = FALSE]
    
    # Calculate outliers per variable
    outlier_counts <- lapply(names(numeric_data), function(var) {
      x <- na.omit(numeric_data[[var]])
      if(length(x) == 0) return(0)
      
      Q1 <- quantile(x, 0.25)
      Q3 <- quantile(x, 0.75)
      IQR <- Q3 - Q1
      lower <- Q1 - input$iqr_multiplier * IQR
      upper <- Q3 + input$iqr_multiplier * IQR
      
      sum(x < lower | x > upper)
    })
    
    total_outliers <- sum(unlist(outlier_counts))
    
    # NULL value handling
    null_count <- if(input$include_null_boxplot) {
      sum(is.na(filtered[, input$numeric_vars]))
    } else {
      0
    }
    
    null_text <- if(null_count > 0) {
      paste(" | NULL values present:", null_count)
    } else {
      ""
    }
    
    # Build output string
    paste(
      "Showing", nrow(filtered), "of", nrow(df), "observations |",
      "Total outliers detected:", total_outliers,
      null_text, "|", 
      "Date Range:", get_date_range_text(input$date_range)
    )
  })
  
  
  # ============================================================================
  # CORRELATION MODULE
  # ============================================================================
  
  
  corr_filtered_data <- reactive({
    data <- df
    data <- apply_categorical_filters(data, 
                                      input$corr_categorical_vars, 
                                      "corr_filter_", 
                                      input$include_null_correlation)
    data <- apply_date_filter(data, "corr_date_range")
    data
  })
  
  # UI for correlation categorical filters
  output$corr_categorical_filters <- renderUI({
    req(input$corr_categorical_vars)
    tagList(lapply(input$corr_categorical_vars, function(var) {
      choices <- levels(df[[var]])
      
      if(any(is.na(df[[var]]))) {
        choices <- c(choices, "NA")
      }
      
      if(input$include_null_correlation) {
        default_selected <- choices
      } else {
        default_selected <- choices[choices != "NA"]
      }
      
      checkboxGroupInput(
        paste0("corr_filter_", var),
        paste("Select levels for", var),
        choices = choices, 
        selected = default_selected          
      )
    }))
  })
  
  # Explanatory text for NULL handling
  output$corr_null_explanation <- renderUI({
    if(input$include_null_correlation) {
      div(
        style = "color: #0c5460; background-color: #d1ecf1; padding: 8px; border-radius: 4px; margin: 10px 0;",
        icon("info-circle"),
        HTML("<strong>Note:</strong> NULLs in categorical variables are included in filtering, but any row with a NULL in a <strong>numeric</strong> variable will be automatically removed for correlation calculation.")
      )
    } else {
      div(
        style = "color: #155724; background-color: #d4edda; padding: 8px; border-radius: 4px; margin: 10px 0;",
        icon("check-circle"),
        HTML("<strong>Note:</strong> NULLs are excluded from categorical filtering. Any remaining NULLs in numeric variables will be automatically removed for correlation calculation.")
      )
    }
  })
  
  # Correlation Plot
  output$corr_plot <- renderPlotly({
    req(input$corr_numeric_vars)
    req(length(input$corr_numeric_vars) >= 2)
    
    num_vars <- length(input$corr_numeric_vars)
    
    data <- corr_filtered_data()
    
    num_data <- data[, input$corr_numeric_vars, drop = FALSE]
    num_data <- na.omit(num_data)
    
    # Check if we have enough data
    if(nrow(num_data) < 3) {
      plot_ly() %>%
        add_annotations(
          text = "Not enough complete observations",
          x = 0.5, y = 0.5, showarrow = FALSE,
          font = list(size = 14)
        ) %>%
        layout(title = "Correlation Heat Map")
      return()
    }
    
    # Remove columns with zero variance
    valid_cols <- sapply(num_data, function(col) sd(col) > 0)
    if(sum(valid_cols) < 2) {
      plot_ly() %>%
        add_annotations(
          text = "Need at least 2 variables with non-zero variance",
          x = 0.5, y = 0.5, showarrow = FALSE,
          font = list(size = 14)
        ) %>%
        layout(title = "Correlation Heat Map")
      return()
    }
    
    num_data <- num_data[, valid_cols, drop = FALSE]
    
    # Calculate correlation matrix
    corr_matrix <- cor(num_data, method = input$corr_method)
    
    # Apply absolute values if selected
    if(input$corr_abs) {
      corr_matrix <- abs(corr_matrix)
    }
    
    # Apply ordering based on selection
    if (input$corr_order == "AOE") {
      order_idx <- corrMatOrder(corr_matrix, order = "AOE")
      corr_matrix <- corr_matrix[order_idx, order_idx]
    } else if (input$corr_order == "FPC") {
      order_idx <- corrMatOrder(corr_matrix, order = "FPC")
      corr_matrix <- corr_matrix[order_idx, order_idx]
    } else if (input$corr_order == "hclust") {
      order_idx <- corrMatOrder(corr_matrix, order = "hclust", hclust.method = input$hclust_method)
      corr_matrix <- corr_matrix[order_idx, order_idx]
    } else if (input$corr_order == "alphabet") {
      order_idx <- order(colnames(corr_matrix))
      corr_matrix <- corr_matrix[order_idx, order_idx]
    }
    
    # Create upper triangle matrix (hide lower triangle)
    corr_upper <- corr_matrix
    corr_upper[lower.tri(corr_upper, diag = FALSE)] <- NA
    
    # Create method display for title
    method_display <- switch(input$corr_method,
                             "pearson" = "Pearson",
                             "spearman" = "Spearman",
                             "kendall" = "Kendall")
    
    order_display <- switch(input$corr_order,
                            "original" = "Original",
                            "AOE" = "Angular Order of Eigenvectors",
                            "FPC" = "First Principal Component",
                            "hclust" = paste("Hierarchical Clustering (", input$hclust_method, ")", sep = ""),
                            "alphabet" = "Alphabetical")
    
    abs_display <- if(input$corr_abs) " | Absolute Values" else ""
    
    plot_title <- paste0("Correlation Heat Map\nMethod: ", method_display, 
                         " | Order: ", order_display, abs_display)
    
    # Define colorscale properly
    colorscale <- list(
      list(0, "blue"),
      list(0.5, "white"),
      list(1, "red")
    )
    
    # Create plotly heatmap with only upper triangle
    p <- plot_ly(
      z = corr_upper,
      x = colnames(corr_matrix),
      y = colnames(corr_matrix),
      type = "heatmap",
      colorscale = colorscale,
      zmin = if(input$corr_abs) 0 else -1,
      zmax = 1,
      hovertemplate = "<b>%{x}</b> vs <b>%{y}</b><br>Correlation: %{z:.2f}<extra></extra>",
      showscale = TRUE,
      colorbar = list(
        title = "Correlation",
        titleside = "right",
        tickformat = ".1f",
        tickvals = if(input$corr_abs) c(0, 0.5, 1) else c(-1, -0.5, 0, 0.5, 1)
      )
    ) %>%
      layout(
        title = list(
          text = plot_title,
          font = list(size = 14, family = "Arial", color = "#2C3E50"),
          y = 0.95
        ),
        xaxis = list(
          title = "",
          tickangle = -45,
          tickfont = list(size = 8, family = "Arial"),
          side = "bottom"
        ),
        yaxis = list(
          title = "",
          tickfont = list(size = 8, family = "Arial"),
          autorange = "reversed"
        ),
        margin = list(b = 100, t = 80, l = 100, r = 80)
      )
    
    # Add correlation values as text if show_values is TRUE
    if(input$corr_show_values) {
      # Create annotations for upper triangle only
      annotations_list <- list()
      n <- ncol(corr_matrix)
      
      # Only add values for the upper triangle
      for (i in 1:n) {
        for (j in 1:n) {
          if (j > i) {  # Upper triangle
            # Calculate font size based on number of variables
            font_size <- ifelse(num_vars > 25, 5, 
                                ifelse(num_vars > 15, 6, 7))
            
            annotations_list <- append(annotations_list, list(
              list(
                x = colnames(corr_matrix)[j],
                y = colnames(corr_matrix)[i],
                text = sprintf(paste0("%.", input$corr_digits, "f"), corr_matrix[i, j]),
                showarrow = FALSE,
                font = list(size = font_size, color = "black"),
                xanchor = "center",
                yanchor = "middle"
              )
            ))
          }
        }
      }
      
      p <- p %>% layout(annotations = annotations_list)
    }
    
    return(p)
  })
  
  # Update correlation observation count
  output$corr_obs_count <- renderText({
    data <- corr_filtered_data()
    
    num_data <- data[, input$corr_numeric_vars, drop = FALSE]
    rows_with_nulls <- sum(!complete.cases(num_data))
    complete_cases <- sum(complete.cases(num_data))
    
    null_status <- if (input$include_null_correlation) {
      "Categorical NULLs included"
    } else {
      "Categorical NULLs excluded"
    }
    
    date_text <- get_date_range_text(input$corr_date_range)
    
    paste("Showing", nrow(data), "of", nrow(df), "observations |",
          null_status, "|",
          "Date Range:", date_text)
  })
  
  
  # ============================================================================
  # MISSING VALUES MODULE 
  # ============================================================================
  
  
  # UI for missing values filters 
  output$mv_categorical_filters <- renderUI({
    req(input$mv_categorical_vars)
    tagList(lapply(input$mv_categorical_vars, function(var) {
      choices <- levels(df[[var]])
      # Add NA option if there are any missing values
      if(any(is.na(df[[var]]))) {
        choices <- c(choices, "NA")
      }
      
      checkboxGroupInput(paste0("mv_filter_", var), 
                         paste("Select levels for", var),
                         choices = choices, 
                         selected = choices)
    }))
  })
  
  # Filtered data for missing values
  mv_filtered_data <- reactive({
    data <- df
    
    # Apply categorical filters with NA handling
    for(var in input$mv_categorical_vars) {
      sel <- input[[paste0("mv_filter_", var)]]
      if(!is.null(sel) && length(sel) > 0) {
        if("NA" %in% sel) {
          sel_real <- setdiff(sel, "NA")
          data <- data[data[[var]] %in% sel_real | is.na(data[[var]]), ]
        } else {
          data <- data[data[[var]] %in% sel, ]
        }
      }
    }
    
    data <- apply_date_filter(data, "mv_date_range")
    
    selected_vars <- c(input$mv_numeric_vars, input$mv_categorical_vars)
    data[, selected_vars, drop = FALSE]
  })
  
  # Render missing values plot
  output$mv_plot <- renderPlotly({
    data <- mv_filtered_data()
    req(ncol(data) > 0)
    
    # Calculate missing percentages (1 decimal place)
    missing_pcts <- round(sapply(data, function(x) mean(is.na(x)) * 100), 1)
    
    # Order variables if selected
    if (input$mv_order_missing == "desc") {
      order_index <- order(missing_pcts, decreasing = TRUE)
      data <- data[, order_index, drop = FALSE]
      missing_pcts <- missing_pcts[order_index]
    } else if (input$mv_order_missing == "asc") {
      order_index <- order(missing_pcts, decreasing = FALSE)
      data <- data[, order_index, drop = FALSE]
      missing_pcts <- missing_pcts[order_index]
    }
    # If "original", do nothing - keep original order
    
    n_vars <- ncol(data)
    n_obs <- nrow(data)
    
    # Create variable labels with percentages
    var_labels <- paste0(names(data), " (", missing_pcts, "%)")
    
    # Create missingness matrix (convert to numeric: 0 for present, 1 for missing)
    missing_matrix <- matrix(as.numeric(is.na(data)), nrow = n_obs, ncol = n_vars)
    colnames(missing_matrix) <- var_labels
    
    # Determine which observation numbers to show based on count
    if (n_obs > 100) {
      # Show every 20th observation
      tickvals <- seq(1, n_obs, by = 20)
      ticktext <- seq(1, n_obs, by = 20)  # Simple increasing sequence
    } else if (n_obs > 50) {
      # Show every 10th observation
      tickvals <- seq(1, n_obs, by = 10)
      ticktext <- seq(1, n_obs, by = 10)
    } else if (n_obs > 20) {
      # Show every 5th observation
      tickvals <- seq(1, n_obs, by = 5)
      ticktext <- seq(1, n_obs, by = 5)
    } else {
      # Show all observations
      tickvals <- 1:n_obs
      ticktext <- 1:n_obs
    }
    
    # Create plotly heatmap
    p <- plot_ly(
      z = missing_matrix,  # Original matrix (observation 1 at top of matrix = top of plot)
      x = var_labels,
      y = 1:n_obs,
      type = "heatmap",
      colors = c("lightblue", "red"),
      hoverinfo = "none",
      showscale = FALSE
    ) %>%
      layout(
        # Main title using annotations
        annotations = list(
          # Title
          list(
            x = 0.5,
            y = 1.12,
            text = "Missingness Visualisation:",
            showarrow = FALSE,
            xref = "paper",
            yref = "paper",
            font = list(size = 18, family = "Arial", color = "#2C3E50", weight = "bold")
          ),
          # Key - Present
          list(
            x = 0.4,
            y = 1.06,
            text = "■ Present",
            showarrow = FALSE,
            xref = "paper",
            yref = "paper",
            font = list(color = "lightblue", size = 14, family = "Arial", weight = "bold")
          ),
          # Key - Missing
          list(
            x = 0.6,
            y = 1.06,
            text = "■ Missing",
            showarrow = FALSE,
            xref = "paper",
            yref = "paper",
            font = list(color = "red", size = 14, family = "Arial", weight = "bold")
          )
        ),
        
        xaxis = list(
          title = "Variables",
          tickangle = -45,
          tickfont = list(size = ifelse(n_vars > 15, 8, 
                                        ifelse(n_vars > 10, 9, 11)), 
                          family = "Arial", weight = "bold"),
          titlefont = list(size = 14, family = "Arial", weight = "bold"),
          side = "bottom"
        ),
        
        yaxis = list(
          title = "Observation Index",
          tickmode = "array",
          tickvals = tickvals,
          ticktext = ticktext,  # Shows 1 at top, increasing downward
          tickfont = list(size = 10, family = "Arial", weight = "bold"),
          titlefont = list(size = 14, family = "Arial", weight = "bold"),
          autorange = "reversed"  # This makes 1 appear at the top
        ),
        
        margin = list(
          b = ifelse(n_vars > 15, 150, 
                     ifelse(n_vars > 10, 130, 120)),
          l = 80,
          t = 120,
          r = 50
        )
      )
    
    return(p)
  })
  
  output$mv_obs_count <- renderText({
    data <- mv_filtered_data()
    total_missing <- sum(is.na(data))
    total_values <- prod(dim(data))
    date_text <- get_date_range_text(input$mv_date_range)
    
    paste("Showing", nrow(data), "of", nrow(df), "observations |",
          "Missing:", total_missing, "of", total_values, 
          "values (", round(100 * total_missing/total_values, 1), "%) |",
          "Date Range:", date_text)
  })
  
  
  # ============================================================================
  # RISING VALUES MODULE
  # ============================================================================
  
  
  # UI for rising values filters
  output$rv_categorical_filters <- renderUI({
    req(input$rv_categorical_vars)
    
    tagList(lapply(input$rv_categorical_vars, function(var) {
      
      # Get levels including NA
      var_levels <- levels(df[[var]])
      
      # Add explicit NA label if NA exists
      if (any(is.na(df[[var]]))) {
        var_levels <- c(var_levels, "NA")
      }
      
      # Default selection: all EXCEPT NA (regardless of checkbox for initial render)
      default_selected <- var_levels[var_levels != "NA"]
      
      checkboxGroupInput(
        paste0("rv_filter_", var),
        paste("Select levels for", var),
        choices = var_levels,
        selected = default_selected
      )
    }))
  })
  
  # Observer to update checkbox selections when rv_include_null changes
  observeEvent(input$rv_include_null, {
    req(input$rv_categorical_vars)
    
    for(var in input$rv_categorical_vars) {
      var_levels <- levels(df[[var]])
      if (any(is.na(df[[var]]))) {
        var_levels <- c(var_levels, "NA")
      }
      
      if(input$rv_include_null) {
        # When checked, select all levels including NA
        updateCheckboxGroupInput(session, paste0("rv_filter_", var), selected = var_levels)
      } else {
        # When unchecked, select all levels except NA
        updateCheckboxGroupInput(session, paste0("rv_filter_", var), selected = var_levels[var_levels != "NA"])
      }
    }
  }, ignoreNULL = FALSE, ignoreInit = TRUE)
  
  # Helper function to safely get include_null value
  get_rv_include_null <- reactive({
    if(is.null(input$rv_include_null)) {
      return(FALSE)  # Default to FALSE if not set
    } else {
      return(input$rv_include_null)
    }
  })
  
  # Filtered data for rising values (full data for obs count)
  rv_obs_filtered_data <- reactive({
    data <- df
    
    # Get include_null value safely
    include_null <- get_rv_include_null()
    
    # Apply categorical filters with NULL inclusion option
    for(var in input$rv_categorical_vars) {
      sel <- input[[paste0("rv_filter_", var)]]
      if(!is.null(sel) && length(sel) > 0) {
        if("NA" %in% sel) {
          sel_real <- setdiff(sel, "NA")
          if(include_null) {
            # Include NULLs - keep selected levels OR NULLs
            data <- data[data[[var]] %in% sel_real | is.na(data[[var]]), ]
          } else {
            # Exclude NULLs - only keep selected levels
            data <- data[data[[var]] %in% sel_real, ]
          }
        } else {
          data <- data[data[[var]] %in% sel, ]
          if(!include_null) {
            # Also remove any NULLs if not including them
            data <- data[!is.na(data[[var]]), ]
          }
        }
      }
    }
    
    # Apply date filter
    if (!is.null(input$rv_date_range)) {
      data <- data[data$Date >= input$rv_date_range[1] & 
                     data$Date <= input$rv_date_range[2], ]
    }
    
    data
  })
  
  # Filtered numeric data for plotting
  rv_filtered_data <- reactive({
    req(input$rv_numeric_vars)
    data <- rv_obs_filtered_data()
    data[, input$rv_numeric_vars, drop = FALSE]
  })
  
  # Render rising values plot
  output$rv_plot <- renderPlotly({
    
    data <- rv_filtered_data()
    req(ncol(data) > 0)
    
    data <- data[, sapply(data, is.numeric), drop = FALSE]
    req(ncol(data) > 0)
    
    # Get date range and NULL status for footer
    date_text <- get_date_range_text(input$rv_date_range)
    include_null <- get_rv_include_null()
    null_status <- if(include_null) "NULLs included" else "NULLs excluded"
    
    # Handle single variable case
    if (ncol(data) == 1) {
      
      sorted_vals <- sort(na.omit(data[,1]))
      
      if (length(sorted_vals) < 2) {
        plot_ly() %>%
          add_annotations(text = "Insufficient data<br>Need at least 2 non-NA values",
                          x = 0.5, y = 0.5, showarrow = FALSE,
                          font = list(size = 14)) %>%
          layout(title = "Rising Value Chart")
        return()
      }
      
      if (input$rv_standardise) {
        plot_vals <- scale(sorted_vals)
        ylab_text <- "Standardised Values (Z-score)"
        title_suffix <- "(Standardised)"
      } else {
        plot_vals <- sorted_vals
        ylab_text <- "Raw Values"
        title_suffix <- "(Raw)"
      }
      
      x_vals <- seq(0, 100, length.out = length(plot_vals))
      
      plot_ly(
        x = x_vals,
        y = plot_vals,
        type = "scatter",
        mode = "lines",
        line = list(color = "blue", width = 2),
        name = names(data)[1],
        hovertemplate = "<b>Percentile:</b> %{x:.1f}<br><b>Value:</b> %{y:.2f}<extra></extra>"
      ) %>%
        layout(
          title = list(text = paste("Rising Value Chart -", names(data)[1], title_suffix)),
          xaxis = list(title = "Percentile"),
          yaxis = list(title = ylab_text),
          annotations = list(
            list(x = 0.5, y = -0.15,
                 text = paste(date_text, "|", null_status),
                 showarrow = FALSE,
                 xref = "paper", yref = "paper",
                 font = list(size = 10))
          )
        )
      
    } else {
      
      # Multiple variables
      data <- data[rowSums(is.na(data)) < ncol(data), ]
      req(nrow(data) > 1)
      
      sorted_list <- lapply(data, function(col) {
        sort(na.omit(col))
      })
      
      min_len <- min(sapply(sorted_list, length))
      sorted_trimmed <- sapply(sorted_list, function(col) col[1:min_len])
      
      if (input$rv_standardise) {
        plot_data <- scale(sorted_trimmed)
        ylab_text <- "Standardised Values (Z-score)"
        title_suffix <- "(Standardised)"
      } else {
        plot_data <- sorted_trimmed
        ylab_text <- "Raw Values"
        title_suffix <- "(Raw)"
      }
      
      main_title <- paste("Rising Value Chart", title_suffix)
      x_vals <- seq(1, 100, length.out = nrow(plot_data))
      
      # Create plotly plot
      p <- plot_ly()
      
      for (i in 1:ncol(plot_data)) {
        p <- add_trace(p,
                       x = x_vals,
                       y = plot_data[, i],
                       type = "scatter",
                       mode = "lines",
                       line = list(width = 1.5),
                       name = colnames(plot_data)[i],
                       hovertemplate = paste("<b>", colnames(plot_data)[i], "</b><br>",
                                             "Percentile: %{x:.1f}<br>",
                                             "Value: %{y:.2f}<extra></extra>"))
      }
      
      p %>%
        layout(
          title = list(text = main_title),
          xaxis = list(title = "Percentile"),
          yaxis = list(title = ylab_text),
          hovermode = "x unified",
          showlegend = TRUE,
          legend = list(x = 1.05, y = 0.5, xanchor = "left"),
          annotations = list(
            list(x = 0.5, y = -0.15,
                 text = paste(date_text, "|", null_status),
                 showarrow = FALSE,
                 xref = "paper", yref = "paper",
                 font = list(size = 10))
          )
        )
    }
  })
  
  # Update observation count
  output$rv_obs_count <- renderText({
    include_null <- get_rv_include_null()
    null_status <- if(include_null) "NULLs included" else "NULLs excluded"
    
    date_text <- ""
    if (!is.null(input$rv_date_range)) {
      date_text <- paste(format(input$rv_date_range[1], "%d-%m-%Y"), 
                         "to", 
                         format(input$rv_date_range[2], "%d-%m-%Y"))
    }
    
    paste("Showing",
          nrow(rv_obs_filtered_data()),
          "of",
          nrow(df),
          "observations |",
          null_status, "|",
          "Date Range:", date_text)
  })
  
  
  # ============================================================================
  # TIME SERIES MODULE
  # ============================================================================
  
  
  # Update time series pickers on app start
  observe({
    vars <- get_variable_types()
    
    updatePickerInput(
      session, "ts_numeric_vars",
      choices = vars$numeric,
      selected = vars$numeric[1:min(1, length(vars$numeric))]
    )
    
    updatePickerInput(
      session, "ts_categorical_vars",
      choices = vars$categorical,
      selected = NULL
    )
  })
  
  # Time series categorical filters UI
  output$ts_categorical_filters <- renderUI({
    req(input$ts_categorical_vars)
    
    tagList(lapply(input$ts_categorical_vars, function(var) {
      choices <- levels(df[[var]])
      if(any(is.na(df[[var]]))) {
        choices <- c(choices, "NA")
      }
      
      default_selected <- if(input$ts_include_null) {
        choices
      } else {
        choices[choices != "NA"]
      }
      
      checkboxGroupInput(
        paste0("ts_filter_", var),
        paste("Select levels for", var),
        choices = choices,
        selected = default_selected
      )
    }))
  })
  
  # Observer for include_null checkbox
  observeEvent(input$ts_include_null, {
    req(input$ts_categorical_vars)
    
    for(var in input$ts_categorical_vars) {
      choices <- levels(df[[var]])
      if(any(is.na(df[[var]]))) {
        choices <- c(choices, "NA")
      }
      
      if(input$ts_include_null) {
        updateCheckboxGroupInput(session, paste0("ts_filter_", var), selected = choices)
      } else {
        updateCheckboxGroupInput(session, paste0("ts_filter_", var), 
                                 selected = choices[choices != "NA"])
      }
    }
  }, ignoreNULL = FALSE, ignoreInit = TRUE)
  
  # Variable warning output
  output$ts_variable_warning <- renderUI({
    n_vars <- length(input$ts_numeric_vars)
    
    if(n_vars > 6) {
      div(
        style = "color: #dc3545; font-weight: bold; margin: 10px 0; padding: 8px; background-color: #f8d7da; border-radius: 4px;",
        icon("exclamation-triangle"),
        paste("Warning:", n_vars, "variables selected. Maximum recommended is 6 for readability.")
      )
    } else if(n_vars == 0) {
      div(
        style = "color: #6c757d; margin: 10px 0;",
        icon("info-circle"),
        "Please select at least one numeric variable."
      )
    }
  })
  
  # Helper for include_null
  get_ts_include_null <- reactive({
    if(is.null(input$ts_include_null)) return(FALSE)
    input$ts_include_null
  })
  
  # Filtered data for time series
  ts_filtered_data <- reactive({
    data <- df
    
    # Apply categorical filters
    for(var in input$ts_categorical_vars) {
      sel <- input[[paste0("ts_filter_", var)]]
      if(!is.null(sel) && length(sel) > 0) {
        include_null <- get_ts_include_null()
        
        if("NA" %in% sel) {
          sel_real <- setdiff(sel, "NA")
          if(include_null) {
            data <- data[data[[var]] %in% sel_real | is.na(data[[var]]), ]
          } else {
            data <- data[data[[var]] %in% sel_real, ]
          }
        } else {
          data <- data[data[[var]] %in% sel, ]
          if(!include_null) {
            data <- data[!is.na(data[[var]]), ]
          }
        }
      }
    }
    
    # Apply date filter
    data <- apply_date_filter(data, "ts_date_range")
    
    # Sort by date
    data <- data[order(data$Date), ]
    
    data
  })
  
  # Check if we have data for plotting
  output$ts_has_data <- reactive({
    nrow(ts_filtered_data()) > 0 && length(input$ts_numeric_vars) > 0
  })
  outputOptions(output, "ts_has_data", suspendWhenHidden = FALSE)
  
  # Time series plot
  output$ts_plot <- renderPlotly({
    req(input$ts_numeric_vars)
    req(length(input$ts_numeric_vars) > 0)
    
    data <- ts_filtered_data()
    req(nrow(data) > 0)
    
    # Get numeric data
    numeric_data <- data[, input$ts_numeric_vars, drop = FALSE]
    
    # Apply transformations
    if(input$ts_center || input$ts_scale) {
      numeric_data <- as.data.frame(scale(numeric_data, 
                                          center = input$ts_center, 
                                          scale = input$ts_scale))
    }
    
    # Add date column
    plot_data <- cbind(Date = data$Date, numeric_data)
    
    # Create transformation text
    transform_text <- if(input$ts_center && input$ts_scale) {
      "(Centered & Scaled)"
    } else if(input$ts_center) {
      "(Centered)"
    } else if(input$ts_scale) {
      "(Scaled)"
    } else {
      ""
    }
    
    # Create plot
    p <- plot_ly()
    
    # Add each variable as a line
    for(var in input$ts_numeric_vars) {
      p <- add_trace(p,
                     x = plot_data$Date,  # This is a Date object, not numeric
                     y = plot_data[[var]],
                     type = "scatter",
                     mode = "lines",
                     name = var,
                     line = list(width = 1.5),
                     hovertemplate = paste("<b>", var, "</b><br>",
                                           "Date: %{x|%d-%m-%Y}<br>",
                                           "Value: %{y:.2f}<extra></extra>"))
    }
    
    # Add smooth lines if requested
    if(input$ts_smooth && length(input$ts_numeric_vars) <= 6) {
      for(var in input$ts_numeric_vars) {
        # Create smooth line data - use as.numeric for model but keep dates for plotting
        valid_idx <- !is.na(plot_data[[var]])
        if(sum(valid_idx) > 5) {
          x_numeric <- as.numeric(plot_data$Date[valid_idx])
          y_vals <- plot_data[[var]][valid_idx]
          
          if(input$ts_smooth_method == "loess") {
            smooth_fit <- loess(y_vals ~ x_numeric, span = input$ts_smooth_span)
            smooth_vals <- predict(smooth_fit)
          } else if(input$ts_smooth_method == "lm") {
            smooth_fit <- lm(y_vals ~ x_numeric)
            smooth_vals <- predict(smooth_fit)
          } else if(input$ts_smooth_method == "gam" && requireNamespace("mgcv", quietly = TRUE)) {
            smooth_fit <- mgcv::gam(y_vals ~ s(x_numeric))
            smooth_vals <- predict(smooth_fit)
          } else {
            next
          }
          
          p <- add_trace(p,
                         x = plot_data$Date[valid_idx],
                         y = smooth_vals,
                         type = "scatter",
                         mode = "lines",
                         name = paste(var, "(smoothed)"),
                         line = list(width = 2.5, dash = "dash"),
                         opacity = 0.7,
                         showlegend = FALSE,
                         hovertemplate = paste("<b>", var, "(smooth)</b><br>",
                                               "Date: %{x|%d-%m-%Y}<br>",
                                               "Value: %{y:.2f}<extra></extra>"))
        }
      }
    }
    
    # Add vertical lines for year boundaries
    years <- seq(as.Date(paste0(format(min(plot_data$Date), "%Y"), "-01-01")),
                 as.Date(paste0(format(max(plot_data$Date), "%Y"), "-12-31")),
                 by = "year")
    
    # Get y-axis range for vertical lines
    y_min <- min(numeric_data, na.rm = TRUE)
    y_max <- max(numeric_data, na.rm = TRUE)
    y_range <- y_max - y_min
    y_buffer <- y_range * 0.05
    
    for(year_date in years) {
      if(year_date >= min(plot_data$Date) && year_date <= max(plot_data$Date)) {
        p <- add_segments(p,
                          x = year_date, xend = year_date,
                          y = y_min - y_buffer, yend = y_max + y_buffer,
                          line = list(color = "gray", width = 0.5, dash = "dot"),
                          showlegend = FALSE,
                          hoverinfo = "none")
      }
    }
    
    # Layout
    p <- p %>%
      layout(
        title = list(
          text = paste("Time Series Plot", transform_text),
          font = list(size = 16, family = "Arial", color = "#2C3E50"),
          y = 0.95
        ),
        xaxis = list(
          title = "Date",
          tickfont = list(size = 10),
          tickformat = "%b %Y",
          tickangle = -45,
          range = c(input$ts_date_range[1], input$ts_date_range[2])
        ),
        yaxis = list(
          title = if(input$ts_center || input$ts_scale) "Standardized Value" else "Value",
          tickfont = list(size = 10)
        ),
        hovermode = "x unified",
        showlegend = TRUE,
        legend = list(
          x = 1.05,
          y = 0.5,
          xanchor = "left",
          font = list(size = 10)
        ),
        margin = list(r = 150, t = 80, b = 80, l = 60)
      )
    
    return(p)
  })
  
  # Time series observation count
  output$ts_obs_count <- renderText({
    data <- ts_filtered_data()
    include_null <- get_ts_include_null()
    null_status <- if(include_null) "NULLs included" else "NULLs excluded"
    
    date_text <- get_date_range_text(input$ts_date_range)
    
    paste("Showing", nrow(data), "of", nrow(df), "observations |",
          null_status, "|",
          "Date Range:", date_text)
  })
  
  # Time series summary table
  output$ts_summary_table <- renderDT({
    req(input$ts_numeric_vars)
    req(length(input$ts_numeric_vars) > 0)
    
    data <- ts_filtered_data()
    req(nrow(data) > 0)
    
    numeric_data <- data[, input$ts_numeric_vars, drop = FALSE]
    
    summary_df <- data.frame(
      Variable = input$ts_numeric_vars,
      Min = round(sapply(numeric_data, min, na.rm = TRUE), 2),
      Mean = round(sapply(numeric_data, mean, na.rm = TRUE), 2),
      Max = round(sapply(numeric_data, max, na.rm = TRUE), 2),
      SD = round(sapply(numeric_data, sd, na.rm = TRUE), 2),
      `Missing` = sapply(numeric_data, function(x) sum(is.na(x))),
      `Missing %` = paste0(round(sapply(numeric_data, function(x) mean(is.na(x)) * 100), 1), "%"),
      check.names = FALSE
    )
    
    datatable(
      summary_df,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 't'
      ),
      rownames = FALSE,
      class = 'cell-border stripe hover display nowrap'
    ) %>%
      formatStyle(columns = 1:7, fontSize = '14px', padding = '8px')
  })
  
  
  # ============================================================================
  # TABPLOT MODULE 
  # ============================================================================
  

  # Check if tabplot is installed
  output$tabplot_check <- reactive({
    if(!requireNamespace("tabplot", quietly = TRUE)) {
      return(FALSE)
    }
    TRUE
  })
  outputOptions(output, "tabplot_check", suspendWhenHidden = FALSE)
  
  # Tabplot categorical filters UI
  output$tabplot_categorical_filters <- renderUI({
    req(input$tabplot_categorical_vars)
    
    tagList(lapply(input$tabplot_categorical_vars, function(var) {
      choices <- levels(df[[var]])
      if(any(is.na(df[[var]]))) {
        choices <- c(choices, "NA")
      }
      
      checkboxGroupInput(
        paste0("tabplot_filter_", var),
        paste("Select levels for", var),
        choices = choices,
        selected = choices
      )
    }))
  })
  
  # Filtered data for tabplot
  tabplot_filtered_data <- reactive({
    req(input$tabplot_numeric_vars, input$tabplot_categorical_vars)
    
    data <- df
    
    # Apply categorical filters
    for(var in input$tabplot_categorical_vars) {
      sel <- input[[paste0("tabplot_filter_", var)]]
      if(!is.null(sel) && length(sel) > 0) {
        if("NA" %in% sel) {
          sel_real <- setdiff(sel, "NA")
          data <- data[data[[var]] %in% sel_real | is.na(data[[var]]), ]
        } else {
          data <- data[data[[var]] %in% sel, ]
        }
      }
    }
    
    # Apply date filter
    data <- apply_date_filter(data, "tabplot_date_range")
    
    # Select variables
    selected_vars <- c(input$tabplot_numeric_vars, input$tabplot_categorical_vars)
    if(length(selected_vars) == 0) {
      return(NULL)
    }
    
    # Create data frame with Date as the FIRST column
    data_with_date <- data.frame(
      Date = data$Date,
      data[, selected_vars, drop = FALSE]
    )
    
    # Convert Date to numeric for sorting
    data_with_date$Date <- as.numeric(data_with_date$Date)
    
    as.data.frame(data_with_date)
  })
  
  # Check if we have data
  output$tabplot_has_data <- reactive({
    !is.null(tabplot_filtered_data()) && nrow(tabplot_filtered_data()) > 0
  })
  outputOptions(output, "tabplot_has_data", suspendWhenHidden = FALSE)
  
  # Dynamic title information - UPDATED for two options only
  output$tabplot_title_info <- renderUI({
    data <- tabplot_filtered_data()
    req(data, nrow(data) > 0)
    
    order_text <- switch(input$tabplot_time_order,
                         "asc" = "Oldest First",
                         "desc" = "Newest First"
    )
    
    title_parts <- c(
      paste0("<strong>Bins:</strong> ", input$tabplot_nbins),
      paste0("<strong>Order:</strong> ", order_text),
      paste0("<strong>NULLs:</strong> ", if(input$tabplot_include_null) "included" else "excluded"),
      paste0("<strong>Date:</strong> ", 
             format(input$tabplot_date_range[1], "%d-%m-%Y"), " to ",
             format(input$tabplot_date_range[2], "%d-%m-%Y"))
    )
    
    HTML(paste(title_parts, collapse = " | "))
  })
  
  # Tabplot generation
  output$tabplot_plot <- renderPlot({
    
    # Check if tabplot is installed
    if(!requireNamespace("tabplot", quietly = TRUE)) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "",
           main = "tabplot package not installed")
      text(1, 1, "Please install tabplot package", cex = 1.2)
      return()
    }
    
    # Get filtered data
    data <- tabplot_filtered_data()
    
    # Validate data
    if(is.null(data) || nrow(data) == 0 || ncol(data) == 0) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "",
           main = "No Data Available")
      text(1, 1, "Please select at least one variable", cex = 1.2)
      return()
    }
    
    # Handle NULL values
    if(!input$tabplot_include_null) {
      data <- na.omit(data)
      if(nrow(data) == 0) {
        plot(1, type = "n", axes = FALSE, xlab = "", ylab = "",
             main = "No Complete Cases")
        text(1, 1, "No complete observations after removing NULLs", cex = 1.2)
        return()
      }
    }
    
    # Prepare data types
    data_plot <- as.data.frame(data)
    for(col in names(data_plot)) {
      if(is.character(data_plot[[col]])) {
        data_plot[[col]] <- as.factor(data_plot[[col]])
      }
    }
    
    # Always sort by Date (first column)
    sort_col <- "Date"
    decreasing <- (input$tabplot_time_order == "desc")
    
    # Create tabplot with explicit sorting and NO log transforms
    tryCatch({
      # Set options to disable automatic log transformations
      op <- options(tabplot.transforms = FALSE)
      
      tabplot::tableplot(
        data_plot,
        sortCol = sort_col,
        decreasing = decreasing,
        nBins = input$tabplot_nbins,
        showNA = if(input$tabplot_showNA) "ifany" else "no",
        plot = TRUE
      )
      
      # Restore options
      options(op)
      
    }, error = function(e) {
      # Fallback if error
      tryCatch({
        tabplot::tableplot(
          data_plot,
          nBins = input$tabplot_nbins,
          plot = TRUE
        )
      }, error = function(e2) {
        plot(1, type = "n", axes = FALSE, xlab = "", ylab = "",
             main = "Error Creating Tabplot")
        text(1, 1, paste("Error:", substr(e2$message, 1, 40)), cex = 0.8)
      })
    })
  })
  
  # Tabplot observation count
  output$tabplot_obs_count <- renderText({
    data <- tabplot_filtered_data()
    
    if(is.null(data) || nrow(data) == 0) {
      return("No data available")
    }
    
    total_rows <- nrow(data)
    
    if(input$tabplot_include_null) {
      complete_rows <- sum(complete.cases(data))
      null_status <- paste0("NULLs included (", complete_rows, " complete cases)")
    } else {
      complete_rows <- nrow(na.omit(data))
      null_status <- "NULLs excluded"
    }
    
    date_text <- paste(format(input$tabplot_date_range[1], "%d-%m-%Y"),
                       "to",
                       format(input$tabplot_date_range[2], "%d-%m-%Y"))
    
    paste("Showing", total_rows, "of", nrow(df), "observations |",
          null_status, "|",
          "Date Range:", date_text)
  })
  
  
  # ============================================================================
  # MOSAIC MODULE 
  # ============================================================================
  
  
  # Helper function to safely get include_null value
  get_mosaic_include_null <- reactive({
    if(is.null(input$mosaic_include_null)) {
      return(FALSE)  # Default to FALSE if not set
    } else {
      return(input$mosaic_include_null)
    }
  })
  
  # Filtered data for mosaic plot with NULL handling
  mosaic_filtered_data <- reactive({
    data <- df
    
    # Apply date filter
    data <- apply_date_filter(data, "mosaic_date_range")
    
    # Get the selected variables
    vars_list <- c(input$mosaic_x, input$mosaic_y)
    if(input$mosaic_z != "None") vars_list <- c(vars_list, input$mosaic_z)
    if(input$mosaic_w != "None") vars_list <- c(vars_list, input$mosaic_w)
    
    # Handle NULLs based on checkbox
    include_null <- get_mosaic_include_null()
    
    if(!include_null) {
      # If NOT including NULLs, remove rows with NA in any selected variable
      data <- na.omit(data[, vars_list])
    } else {
      # If including NULLs, keep all rows but ensure we have the selected columns
      data <- data[, vars_list, drop = FALSE]
      # Note: mosaic() function will handle NULLs by showing them as a separate category
    }
    
    data
  })
  
  output$mosaic_plot <- renderPlot({
    xvar <- input$mosaic_x
    yvar <- input$mosaic_y
    zvar <- if(input$mosaic_z == "None") NULL else input$mosaic_z
    wvar <- if(input$mosaic_w == "None") NULL else input$mosaic_w
    
    req(xvar, yvar)
    
    data <- mosaic_filtered_data()
    
    # Check if we have data
    if(nrow(data) == 0 || ncol(data) == 0) {
      plot(1, type = "n", axes = FALSE, xlab = "", ylab = "",
           main = "No data available after filtering")
      text(1, 1, "No observations for selected variables", cex = 1.2)
      return()
    }
    
    # Build formula with up to 4 variables
    vars_list <- c(xvar, yvar)
    if(!is.null(zvar)) vars_list <- c(vars_list, zvar)
    if(!is.null(wvar)) vars_list <- c(vars_list, wvar)
    
    formula <- as.formula(paste("~", paste(vars_list, collapse = " + ")))
    
    # Create title based on number of variables
    if(!is.null(wvar)) {
      title_text <- paste("Mosaic Plot:", xvar, "vs", yvar, "vs", zvar, "vs", wvar)
    } else if(!is.null(zvar)) {
      title_text <- paste("Mosaic Plot:", xvar, "vs", yvar, "vs", zvar)
    } else {
      title_text <- paste("Mosaic Plot:", xvar, "vs", yvar)
    }
    
    # Create the mosaic plot 
    mosaic(formula, data = data,
           color = TRUE, shade = TRUE, legend = TRUE,
           main = title_text) 
  })
  
  output$mosaic_obs_count <- renderText({
    data <- mosaic_filtered_data()
    include_null <- get_mosaic_include_null()
    null_status <- if(include_null) "NULLs included" else "NULLs excluded"
    
    paste("Showing", nrow(data), "of", nrow(df), "observations |",
          null_status, "|",
          "Date Range:", get_date_range_text(input$mosaic_date_range))
  })
  
  
  # ============================================================================
  # GGPAIRS MODULE
  # ============================================================================
  
  
  # Observe deselect buttons
  observeEvent(input$deselect_numeric, {
    updatePickerInput(session, "ggpairs_numeric_vars", selected = character(0))
  })
  
  observeEvent(input$deselect_categorical, {
    updatePickerInput(session, "ggpairs_categorical_vars", selected = character(0))
  })
  
  # Display total selected variables count
  output$ggpairs_total_count <- renderUI({
    num_count <- length(input$ggpairs_numeric_vars)
    cat_count <- length(input$ggpairs_categorical_vars)
    total <- num_count + cat_count
    
    if(total > 10) {
      div(
        style = "color: #dc3545; font-weight: bold; margin: 5px 0;",
        icon("exclamation-triangle"),
        paste("Total:", total, "of 10 variables selected (too many)")
      )
    } else if(total == 0) {
      div(
        style = "color: #6c757d; margin: 5px 0;",
        icon("info-circle"),
        "No variables selected"
      )
    } else {
      div(
        style = "color: #28a745; margin: 5px 0;",
        icon("check-circle"),
        paste("Total:", total, "of 10 variables selected")
      )
    }
  })
  
  # Combine selected variables for plotting
  ggpairs_selected_vars <- reactive({
    c(input$ggpairs_numeric_vars, input$ggpairs_categorical_vars)
  })
  
  ggpairs_filtered_data <- reactive({
    data <- df
    data <- apply_date_filter(data, "ggpairs_date_range")
    data
  })
  
  output$ggpairs_plot <- renderPlotly({
    vars <- ggpairs_selected_vars()
    req(length(vars) > 0)
    req(length(vars) <= 10)  # Enforce max 10 variables
    
    data <- ggpairs_filtered_data()[, vars, drop = FALSE]
    
    color_var <- if(input$ggpairs_color == "None") NULL else input$ggpairs_color
    
    if(!is.null(color_var)) {
      if(!color_var %in% names(data)) {
        data[[color_var]] <- ggpairs_filtered_data()[[color_var]]
      }
      data <- data[!is.na(data[[color_var]]), ]
    }
    
    data <- na.omit(data)
    
    if(nrow(data) == 0) {
      plot_ly() %>%
        add_annotations(text = "No complete observations after filtering",
                        x = 0.5, y = 0.5, showarrow = FALSE,
                        font = list(size = 14)) %>%
        layout(title = "GGpairs Plot")
      return()
    }
    
    date_text <- paste("Date Range:", get_date_range_text(input$ggpairs_date_range))
    
    # Create ggpairs plot
    if(!is.null(color_var) && color_var %in% names(data)) {
      
      if(!is.factor(data[[color_var]])) {
        data[[color_var]] <- as.factor(data[[color_var]])
      }
      
      if(input$ggpairs_show_cor) {
        ggp <- ggpairs(
          data,
          columns = which(names(data) != color_var),
          mapping = aes(color = .data[[color_var]]),
          title = paste("GGpairs Plot - Colored by", color_var),
          subtitle = date_text,
          progress = FALSE,
          upper = list(continuous = wrap("cor", size = 3)),
          lower = list(continuous = wrap("points", alpha = 0.5, size = 0.5))
        )
      } else {
        ggp <- ggpairs(
          data,
          columns = which(names(data) != color_var),
          mapping = aes(color = .data[[color_var]]),
          title = paste("GGpairs Plot - Colored by", color_var),
          subtitle = date_text,
          progress = FALSE,
          upper = list(continuous = wrap("points", alpha = 0.5, size = 0.5)),
          lower = list(continuous = wrap("points", alpha = 0.5, size = 0.5))
        )
      }
      
    } else {
      
      if(input$ggpairs_show_cor) {
        ggp <- ggpairs(
          data,
          title = "GGpairs Plot",
          subtitle = date_text,
          progress = FALSE,
          upper = list(continuous = wrap("cor", size = 3)),
          lower = list(continuous = wrap("points", alpha = 0.5, size = 0.5))
        )
      } else {
        ggp <- ggpairs(
          data,
          title = "GGpairs Plot",
          subtitle = date_text,
          progress = FALSE,
          upper = list(continuous = wrap("points", alpha = 0.5, size = 0.5)),
          lower = list(continuous = wrap("points", alpha = 0.5, size = 0.5))
        )
      }
    }
    
    ggp <- ggp + 
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
        plot.subtitle = element_text(hjust = 0.5, color = "gray50", size = 11),
        strip.background = element_rect(fill = "lightgray"),
        strip.text = element_text(face = "bold", size = 10)
      )
    
    # Convert to plotly with more top margin for title
    ggplotly(ggp, height = 800, tooltip = c("x", "y", "colour")) %>%
      layout(
        hoverlabel = list(bgcolor = "white", font = list(size = 10)),
        margin = list(t = 80)  # Add more top margin to prevent title cutoff
      )
  })
  
  output$ggpairs_obs_count <- renderText({
    data <- ggpairs_filtered_data()
    vars <- ggpairs_selected_vars()
    
    if(length(vars) > 0) {
      data_subset <- data[, vars, drop = FALSE]
      complete_cases <- sum(complete.cases(data_subset))
      
      paste("Showing", nrow(data), "of", nrow(df), "observations",
            "| Complete cases for selected variables:", complete_cases,
            "| Date Range:", get_date_range_text(input$ggpairs_date_range))
    } else {
      paste("Showing", nrow(data), "of", nrow(df), "observations",
            "| Date Range:", get_date_range_text(input$ggpairs_date_range))
    }
  })
  
  
  # ============================================================================
  # DATA TABLE
  # ============================================================================
  
  
  # Add observers for column selection
  observe({
    all_cols <- names(df)
    updatePickerInput(session, "dt_columns",
                      choices = all_cols,
                      selected = all_cols)
  })
  
  observeEvent(input$dt_select_all, {
    updatePickerInput(session, "dt_columns", selected = names(df))
  })
  
  observeEvent(input$dt_deselect_all, {
    updatePickerInput(session, "dt_columns", selected = character(0))
  })
  
  # Reactive for selected columns
  selected_columns <- reactive({
    if(is.null(input$dt_columns) || length(input$dt_columns) == 0) {
      return(names(df))
    }
    input$dt_columns
  })
  
  output$datatable <- renderDT({
    req(selected_columns())
    df_subset <- df[, selected_columns(), drop = FALSE]
    
    page_length <- if(input$dt_page_length == -1) {
      nrow(df_subset)
    } else {
      as.numeric(input$dt_page_length)
    }
    
    datatable(
      df_subset, 
      extensions = "Buttons",
      options = list(
        dom = 'Bfrtip', 
        buttons = c('copy', 'csv', 'excel', 'pdf', 'print'),
        pageLength = page_length,
        lengthMenu = list(c(10, 25, 50, 100, -1), 
                          c("10", "25", "50", "100", "All")),
        scrollX = TRUE,
        autoWidth = TRUE
      ),
      filter = "top",
      class = 'cell-border stripe hover'
    )
  })
  
} 

DEFAULT_COLOR <- "white"

theme_axelfraud <- function(plot_margin = 15) {
  theme(
    plot.background = element_rect(fill = "grey40", color = "grey40"),
    plot.title = element_text(color = "grey80", size = 14),
    plot.margin = margin(plot_margin, plot_margin, plot_margin, plot_margin),
    panel.background = element_rect(fill = "grey30"),
    panel.grid.major = element_line(color = "grey40", size = 0.8),
    panel.grid.minor = element_line(color = "grey40", size = 0.8),
    axis.title = element_text(color = "grey80"),
    axis.text = element_text(color = "grey80")
  )
}

theme_axelfraud_arrange <- function(plot_margin = 15) {
  theme(
    plot.margin = margin(t = plot_margin, b = plot_margin, l = plot_margin, r = plot_margin),
    plot.background = element_rect(fill = "grey40", color = "grey40")
  )
}

format_data <- function(data) {
  data$step %<>% as.numeric()
  data$id %<>% as.numeric()
  data$culture %<>% as.character()
  data$changed_culture %<>% as.logical()
  data$replicate %<>% as.numeric()
  data$x %<>% as.numeric()
  data$y %<>% as.numeric()
  data$config %<>% as.character()
  return(data)
}

distribution_plot <- function(
  dataset, title, 
  binwidth = 10, color = DEFAULT_COLOR, 
  y_breaks = 10, ylim = c(0, 100), 
  axis_title_size = 11, axis_text_size = 9, title_size = 12
) {
  p <- dataset %>% 
    filter(step == max(step)) %>% 
    filter(culture == "00000") %>% 
    group_by(replicate) %>% 
    summarize(count = n()) %>% 
    ungroup() %>% 
    ggplot(aes(x = count)) +
      geom_histogram(fill = color, alpha = 0.7, binwidth = binwidth) +
      scale_y_continuous(breaks = seq(0, 100, by = y_breaks), limits = ylim) +
      labs(
        title = title,
        x = "Final spread of stubborn culture",
        y = "Amount"
      ) +
      theme_axelfraud(plot_margin = 5) +
      theme(
        title = element_text(size = title_size),
        axis.title = element_text(size = axis_title_size),
        axis.text = element_text(size = axis_text_size)
      ) +
      NULL  
  return(p)
}

development_plot <- function(
  dataset, title, 
  alpha = 0.05, size = 2, color = DEFAULT_COLOR,
  y_breaks = 25, axis_title_size = 11, axis_text_size = 9, title_size = 12
) {
  n_replicates <- dim(dataset %>% select(replicate) %>% unique())[1]
  color_scheme <- rep(color, n_replicates)
  p <- dataset %>% 
    filter(culture == "00000") %>% 
    group_by(step, replicate, culture) %>% 
    summarize(count = n()) %>% 
    ungroup() %>% 
    ggplot(aes(x = step, y = count, color = as.factor(replicate))) +
      geom_line(alpha = alpha, size = size) +
      scale_y_continuous(breaks = seq(0, 100, by = y_breaks)) +
      scale_color_manual(values = color_scheme) +
      labs(
        title = title,
        x = "Step",
        y = "Stubborn culture count"
      ) +
      theme_axelfraud(plot_margin = 5) +
      theme(
        legend.position = "None",
        title = element_text(size = title_size),
        axis.title = element_text(size = axis_title_size),
        axis.text = element_text(size = axis_text_size)
      ) +
      NULL
  return(p)
}

grid_plot <- function(
  df, x, y, color, 
  non_stubborn_color = "firebrick", stubborn_color = "gold3", 
  config_title = "default", title_size = 14) {
  p <- df %>% 
    ggplot(aes_string(x = x, y = y, color = color)) +
      geom_point(size = 6) +
      scale_color_manual(values = c("0" = non_stubborn_color, "1" = stubborn_color)) +
      scale_x_continuous(breaks = seq(1, 10, by = 1)) +
      scale_y_continuous(breaks = seq(1, 10, by = 1)) +
      labs(y = config_title) +
      coord_fixed() +
      theme_axelfraud(plot_margin = 5) +
      theme(
        legend.position = "None",
        axis.title.x = element_blank(),
        axis.title.y = element_text(size = title_size),
        axis.text = element_blank(),
        axis.ticks = element_blank()
      ) +
      NULL
  return(p)
}

by_class <- function(df, config_name) {
  df_classed <- df
  df_classed$replicate %<>% factor(levels = seq(1, 300, by = 1))
  df_classed  %<>% 
    filter(step == max(step)) %>% 
    filter(culture == "00000") %>% 
    group_by(replicate, .drop = FALSE) %>% 
    summarize(stubborn_culture_count = n()) %>% 
    ungroup() %>% 
    mutate(stubborn_culture_grouped = ceiling(stubborn_culture_count / 10)) %>% 
    mutate(stubborn_culture_grouped = stubborn_culture_grouped %>% factor(levels = seq(1, 10, by = 1))) %>% 
    group_by(stubborn_culture_grouped, .drop = FALSE) %>% 
    summarize(count = n()) %>% 
    ungroup() %>% 
    mutate(count = as.numeric(count)) %>% 
    mutate(config = config_name)
  return(df_classed)
}

agreement_by_step <- function(df) {
  df %>% 
    filter(culture == "00000") %>% 
    group_by(step, replicate, culture) %>% 
    summarize(count = n()) %>% 
    ungroup() %>% 
    mutate(count = as.numeric(count)) %>% 
    mutate(count_grouped = ceiling(count / 10)) %>% 
    mutate(count_grouped = count_grouped %>% factor(levels = seq(1, 10, by = 1))) %>% 
    group_by(step, count_grouped, .drop = FALSE) %>% 
    summarize(count = n()) %>% 
    ungroup() %>% 
    group_by(step, .drop = FALSE) %>% 
    summarize(agreement = agreement(count)) %>% 
    ungroup() -> df_agreement_by_step
  return(df_agreement_by_step)
}

DEFAULT_COLOR <- "white"

theme_axelfraud <- function() {
  theme(
    plot.background = element_rect(fill = "grey40", color = "transparent"),
    plot.title = element_text(color = "grey80", size = 14),
    plot.margin = margin(15, 15, 15, 15),
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
    plot.background = element_rect(fill = "grey40", color = "transparent")
  )
}

load_data <- function(file_path) {
  data <- arrow::read_feather(file_path)
  data$step %<>% as.numeric()
  data$id %<>% as.numeric()
  data$culture %<>% as.character()
  data$replicate %<>% as.numeric()
  data$x %<>% as.numeric()
  data$y %<>% as.numeric()  
  return(data)
}

distribution_plot <- function(dataset, title, binwidth = 10, color = DEFAULT_COLOR) {
  p <- dataset %>% 
    filter(step == max(step)) %>% 
    filter(culture == "00000") %>% 
    group_by(replicate) %>% 
    summarize(count = n()) %>% 
    ungroup() %>% 
    ggplot(aes(x = count)) +
      geom_histogram(fill = color, alpha = 0.7, binwidth = binwidth) +
      labs(
        title = title,
        x = "Number of agents with stubborn culture",
        y = "Number of replicates"
      ) +
      theme_axelfraud() +
      theme(
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 12)
      ) +
      NULL  
  return(p)
}

development_plot <- function(dataset, title, alpha = 0.05, size = 2, color = DEFAULT_COLOR) {
  n_replicates <- dim(corners %>% select(replicate) %>% unique())[1]
  color_scheme <- rep(color, n_replicates)
  p <- dataset %>% 
    filter(culture == "00000") %>% 
    group_by(step, replicate, culture) %>% 
    summarize(count = n()) %>% 
    ungroup() %>% 
    ggplot(aes(x = step, y = count, color = as.factor(replicate))) +
      geom_line(alpha = alpha, size = size) +
      scale_color_manual(values = color_scheme) +
      labs(
        title = title,
        x = "Step",
        y = "Stubborn culture count"
      ) +
      theme_axelfraud() +
      theme(
        legend.position = "None",
        axis.title = element_text(size = 14),
        axis.text = element_text(size = 12)
      ) +
      NULL
  return(p)
}

grid_plot <- function(df, x, y, color, non_stubborn_color = "firebrick", stubborn_color = "gold3") {
  p <- df %>% 
    ggplot(aes_string(x = x, y = y, color = color)) +
      geom_point(size = 6) +
      scale_color_manual(values = c("0" = non_stubborn_color, "1" = stubborn_color)) +
      scale_x_continuous(breaks = seq(1, 10, by = 1)) +
      scale_y_continuous(breaks = seq(1, 10, by = 1)) +
      coord_fixed() +
      theme_axelfraud() +
      theme(
        legend.position = "None",
        axis.title = element_blank(),
        axis.text = element_blank()
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

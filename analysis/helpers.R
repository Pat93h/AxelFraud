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
#===========================================================
# Stattistical tests and data visualisation
#===========================================================

# feel free to modify code for personal use 
# - refer to the guide or my publications for more information on choice of tests
# graph labels are in russian for now, i will edit them later for multilingual clarity

#Libraries
library(dplyr)
library(ggplot2)
library(ggsci)
library(MetBrewer)
library(PNWColors)
library(ggdark)
library(viridis)
library(ggsignif)
library(scico)

#Concatenate (merge vertically) Final Data Frames of 3 groups
nuc_merged <- rbind(m2_final_df, m6_final_df, m12_final_df)

#Concatenate (merge vertically) simple Data Frames of 3 groups
nuc_simple <- rbind(m2_simplified_data, m6_simplified_data, m12_simplified_data)

# Modify to create adequate data frame
df_nuc_merged <- data.frame(nuc_merged)
df_nuc_merged$group.name <- factor(df_nuc_merged$group.name, levels = c("m2","m6","m12"))

df_nuc_simple <- data.frame(nuc_simple)
df_nuc_simple$group.name <- factor(df_nuc_simple$group.name, levels = c("m2","m6","m12"))

# Create data frame that removes nuclei where measurements=0 (FOR M/Q)
df_for_MQ <- df_nuc_merged[df_nuc_merged$measurements != 0, ]


#STATISTICAL TESTS
#===========================================================

#normality test
# Shapiro-Wilk test for each group
shapiro_results <- df_nuc_simple %>%
  group_by(group.name) %>%
  summarise(
    shapiro_statistic = shapiro.test(d_Vol/n_Vol)$statistic,
    shapiro_p_value = shapiro.test(d_Vol/n_Vol)$p.value
  )
# QQplot (additional visualisation)
# qqPlot()

# cajal body count distribution
# 1) Kruskal test (initial)
# 2) Mann whitney U test (additional) with Bonferonni correction
kruskal.test(measurements ~ group.name, data = df_nuc_simple)

m2_vs_m6 <- wilcox.test(
  measurements ~ group.name, 
  data = subset(df_nuc_simple, group.name %in% c("m2", "m6")),
  exact = FALSE  # Avoids ties warning
)
summary(df_nuc_simple$measurements[df_nuc_simple$group.name == "m2"])

m2_vs_m12 <- wilcox.test(
  measurements ~ group.name, 
  data = subset(df_nuc_simple, group.name %in% c("m2", "m12")),
  exact = FALSE  # Avoids ties warning
)
summary(df_nuc_simple$measurements[df_nuc_simple$group.name == "m6"])

m6_vs_m12 <- wilcox.test(
  measurements ~ group.name, 
  data = subset(df_nuc_simple, group.name %in% c("m6", "m12")),
  exact = FALSE  # Avoids ties warning
)
summary(df_nuc_simple$measurements[df_nuc_simple$group.name == "m12"])

# 3) Jokeree for effect size
library(PMCMRplus)
jonckheereTest(measurements ~ as.numeric(factor(group.name)), 
               data = df_nuc_simple)
cor.test(
  x = as.numeric(df_nuc_simple$group.name),  # Ordered groups (numeric)
  y = df_nuc_simple$measurements,            # Your continuous variable
  method = "kendall"
)


# MGV with age

kruskal.test(Mean ~ group.name, data = df_for_MQ)

# 2) Mann whitney U test (additional) with Bonferonni correction
m2_vs_m6 <- wilcox.test(
  Mean ~ group.name, 
  data = subset(df_for_MQ, group.name %in% c("m2", "m6")),
  exact = FALSE  # Avoids ties warning
)
summary(df_for_MQ$Mean[df_for_MQ$group.name == "m2"])

m2_vs_m12 <- wilcox.test(
  Mean ~ group.name, 
  data = subset(df_for_MQ, group.name %in% c("m2", "m12")),
  exact = FALSE  # Avoids ties warning
)
summary(df_for_MQ$Mean[df_for_MQ$group.name == "m6"])

m6_vs_m12 <- wilcox.test(
  Mean ~ group.name, 
  data = subset(df_for_MQ, group.name %in% c("m6", "m12")),
  exact = FALSE  # Avoids ties warning
)
summary(df_for_MQ$Mean[df_for_MQ$group.name == "m12"])
jonckheereTest(Mean ~ as.numeric(factor(group.name)), 
               data = df_for_MQ)
cor.test(
  x = as.numeric(df_for_MQ$group.name),  # Ordered groups (numeric)
  y = df_for_MQ$Mean,                    # Your continuous measurement
  method = "kendall"
)

# Volume distribution

kruskal.test(Vol..unit. ~ group.name, data = df_for_MQ)

# 2) Mann whitney U test (additional) with Bonferonni correction
m2_vs_m6 <- wilcox.test(
  Vol..unit. ~ group.name, 
  data = subset(df_for_MQ, group.name %in% c("m2", "m6")),
  exact = FALSE  # Avoids ties warning
)
summary(df_for_MQ$Vol..unit.[df_for_MQ$group.name == "m2"])

m2_vs_m12 <- wilcox.test(
  Vol..unit. ~ group.name, 
  data = subset(df_for_MQ, group.name %in% c("m2", "m12")),
  exact = FALSE  # Avoids ties warning
)
summary(df_for_MQ$Vol..unit.[df_for_MQ$group.name == "m6"])

m6_vs_m12 <- wilcox.test(
  Vol..unit. ~ group.name, 
  data = subset(df_for_MQ, group.name %in% c("m6", "m12")),
  exact = FALSE  # Avoids ties warning
)
summary(df_for_MQ$Vol..unit.[df_for_MQ$group.name == "m12"])
jonckheereTest(Vol..unit. ~ as.numeric(factor(group.name)), 
               data = df_for_MQ)

cor.test(
  x = as.numeric(df_for_MQ$group.name),  # Ordered groups (numeric)
  y = df_for_MQ$Vol..unit.,                    # Your continuous measurement
  method = "kendall"
)

# nucelus volume distribution
summary(df_nuc_simple$n_Vol)
 #GRAPHS - save workspace
ggplot(df_nuc_simple, aes(x = 1, y = n_Vol)) +
  geom_violin() + theme_minimal()
#===========================================================

#VIOLIN PLOTS

#cajal body count distribution
ggplot(df_nuc_simple, aes(x = group.name, y = measurements, fill = group.name)) +
  geom_violin() + theme_minimal()
#cajal body MGV distribution
ggplot(df_for_MQ, aes(x = group.name, y = Mean, fill = group.name)) +
  geom_violin() + theme_minimal()

#DAPI volume distribution
ggplot(df_nuc_simple, aes(x = group.name, y = d_Vol, fill = group.name)) +
  geom_violin() + theme_minimal()

#NM volume distribution
ggplot(df_nuc_simple, aes(x = group.name, y = n_Vol, fill = group.name)) +
  geom_violin() + theme_minimal()

# relative DAPI volume distribution
ggplot(df_nuc_simple, aes(x = group.name, y = d_Vol/n_Vol, fill = group.name)) +
  geom_violin() + theme_minimal()

#  DAPI surface distribution
ggplot(df_nuc_simple, aes(x = group.name, y = d_Surf, fill = group.name)) +
  geom_violin() + theme_minimal()

# Cajal body Sise dynamics v1 <================ [INCLUDE] [NB!] [3]


ggplot(df_for_MQ, aes(x = group.name, y = log10(Vol..unit.))) +
  # Violin plots (kept subtle)
  geom_boxplot(aes(fill = group.name,), alpha = 0.8) + theme_minimal() +
  # geom_jitter(width = 0.2, size = 0.75, alpha = 1, aes(color = group.name)) +
  scale_fill_npg(
    palette = c("nrc"),
    name = "Group",
    labels = c("m2", "m6", "m12")
  ) +

  geom_signif(
    comparisons = list(
      c("m2", "m6"),
      c("m2", "m12")
    ),
    map_signif_level = c("*" = 0.016, "**" = 0.003,"***" = 0.0003),
    # Shows stars instead of p-values
    test = "wilcox.test", # Uses Mann-Whitney test
    test.args = list(exact = FALSE, correct = TRUE), # Handles ties
    step_increase = 0.1, # Spaces out the significance bars
  ) +
  scale_x_discrete(labels = c("m2" = "2-3", 
                              "m6" = "6-7", 
                              "m12" = "12")
  ) +
  # Labels and theme
  guides(fill = "none"
  ) +
  labs(
    x = "Возрастная группа, мес.",
    y = expression(paste("Логарифмический объём коилин+ телец, ", log[10], "(мкм"^3 * ")"))
    )



# Wierd Cajal body Sise dynamics v2]
ggplot(df_for_MQ, aes(x = group.name, y = log10(Vol..unit.))) +
  # Violin plots (kept subtle)
  geom_boxplot(fill = "white", alpha = 0.8, show.legend = FALSE) +
  
  # Points with viridis color scale for Mean
  geom_point(
    aes(
      color = Mean,         # Color maps to Mean values
    ),
    position = position_jitter(width = 0.15),
    size = 1.2,             # Adjust point size
    alpha = 1             # Slight transparency for overlaps
  ) +
  
  # Viridis color scale 
  scale_color_viridis_c(
    begin = 0,
    end = 1,
    option = "H",      # Try "viridis", "magma", or "inferno"
    direction = 1,         # Reverse scale (high values = yellow)
    name = "Среднее 
значение серого 
(MGV), у.е."
  ) +
  geom_signif(
    comparisons = list(
      c("m2", "m6"),
      c("m2", "m12")
    ),
    map_signif_level = c("*" = 0.016, "**" = 0.003,"***" = 0.0003),
    # Shows stars instead of p-values
    test = "wilcox.test", # Uses Mann-Whitney test
    test.args = list(exact = FALSE, correct = TRUE), # Handles ties
    step_increase = 0.1, # Spaces out the significance bars
  ) +
  # Labels and theme
  labs(
    x = "Возрастная группа, мес.",
    y = expression(paste("Логарифмический объём коилин+ телец, ", log[10], "(мкм"^3 * ")"))
  ) +
  scale_x_discrete(labels = c("m2" = "2-3", 
                              "m6" = "6-7", 
                              "m12" = "12")) +
  theme_minimal() +
  theme(
    legend.position = "right",
    panel.grid.minor = element_blank()
  )


names(df_for_MQ)
#BOX PLOTS

#cajal body count distribution
ggplot(df_nuc_simple, aes(x = group.name, y = measurements, fill = group.name)) +
  geom_boxplot() + theme_minimal()

#neat body count distribution v1
ggplot(df_nuc_simple, aes(x = group.name, y = measurements)) +
  geom_boxplot(aes(fill = group.name,), alpha = 0.8) + theme_minimal() +
  # geom_jitter(width = 0.2, size = 0.75, alpha = 1, aes(color = group.name)) +
  scale_fill_npg(
    palette = c("nrc"),
    name = "Group",
    labels = c("m2", "m6", "m12")
  ) +
  geom_signif(
    comparisons = list(
      c("m6", "m12"),
      c("m2", "m12"),
      c("m2", "m6")
    ),
    map_signif_level = function(p) sprintf("p = %.2g", p), # Shows stars instead of p-values
    test = "wilcox.test", # Uses Mann-Whitney test
    test.args = list(exact = FALSE), # Handles ties
    step_increase = 0.1 # Spaces out the significance bars
  )

#neat body count distribution v2 <================ [INCLUDE] [NB!] [1+]
ggplot(df_nuc_simple, aes(x = group.name, y = measurements)) +
  geom_boxplot(aes(fill = group.name,), alpha = 0.8) + theme_minimal() +
  # geom_jitter(width = 0.2, size = 0.75, alpha = 1, aes(color = group.name)) +
  scale_fill_npg(
    palette = c("nrc"),
    name = "Group",
    labels = c("m2", "m6", "m12")
  ) +
  labs(
    x = "Возрастная группа, мес.",
    y = "Количество коилин+ телец"
  ) +
  scale_x_discrete(labels = c("m2" = "2-3", 
                              "m6" = "6-7", 
                              "m12" = "12")
  ) +
  guides(fill = "none"
  ) +
  geom_signif(
    comparisons = list(
      c("m6", "m12"),
      c("m2", "m12")
    ),
    # Significance with Bonferroni adjustments
    map_signif_level = c("*" = 0.016, "**" = 0.003,"***" = 0.0003),
    # Shows stars instead of p-values
    test = "wilcox.test", # Uses Mann-Whitney test
    test.args = list(exact = FALSE, correct = TRUE), # Handles ties
    step_increase = 0.1, # Spaces out the significance bars
  )

#cajal body MGV distribution
ggplot(df_for_MQ, aes(x = group.name, y = Mean, fill = group.name)) +
  geom_boxplot() + theme_minimal()

#neat cajal body MGV distribution v1 <================ [INCLUDE] [NB!] [2+]
ggplot(df_for_MQ, aes(x = group.name, y = Mean)) +
  geom_boxplot(aes(fill = group.name,), alpha = 0.8) + theme_minimal() +
  # geom_jitter(width = 0.2, size = 0.75, alpha = 1, aes(color = group.name)) +
  scale_fill_npg(
    palette = c("nrc"),
    name = "Group",
    labels = c("m2", "m6", "m12")
  ) +
  labs(
    x = "Возрастная группа, мес.",
    y = "Среднее значение серого (MGV) коилин+ телец, у.е."
  ) +
  scale_x_discrete(labels = c("m2" = "2-3", 
                              "m6" = "6-7", 
                              "m12" = "12")
  ) +
  guides(fill = "none"
  ) +
  geom_signif(
    comparisons = list(
      c("m6", "m12"),
      c("m2", "m12")
    ),
    map_signif_level = c("*" = 0.016, "**" = 0.003,"***" = 0.0003),
    # Shows stars instead of p-values
    test = "wilcox.test", # Uses Mann-Whitney test
    test.args = list(exact = FALSE, correct = TRUE), # Handles ties
    step_increase = 0.1, # Spaces out the significance bars
  )


#DAPI volume distribution 
ggplot(df_nuc_simple, aes(x = group.name, y = d_Vol, fill = group.name)) +
  geom_boxplot() + theme_minimal()

# relative DAPI volume distribution
ggplot(df_nuc_simple, aes(x = group.name, y = d_Vol/n_Vol, fill = group.name)) +
  geom_boxplot() + theme_minimal()

#  DAPI surface distribution
ggplot(df_nuc_simple, aes(x = group.name, y = d_Surf, fill = group.name)) +
  geom_boxplot() + theme_minimal()

#Scatter PLOTS
ggplot(df_for_MQ, aes(x = log10(Vol..unit.), y = Mean, fill = group.name)) +
  geom_point(aes (color = group.name, shape = group.name)) + 
  theme_minimal()

# BAR GRAPHS

# Relative DAPI volume distribution <================ [INCLUDE] [NB!] [5]
library(ggplot2)
library(dplyr)

# 1. Calculate summary statistics (mean ± SD)
dn_df_summary <- df_nuc_simple %>%
  group_by(group.name) %>%
  summarise(
    mean = mean(d_Vol/n_Vol),
    sd = sd(d_Vol/n_Vol)
  )
# Tukey test
anova_model_t <- aov(d_Vol/n_Vol ~ group.name, data = df_nuc_simple)
tukey_results <- TukeyHSD(anova_model_t)
tukey_p_values <- tukey_results$group.name[, "p adj"]

t_manual_p_values <- c(
  "m2 vs m6" = 0.1212693,   # Replace with your m2-m6 p-value
  "m2 vs m12" = 0.0000001, # Replace with your m2-m12 p-value
  "m6 vs m12" = 0.0039760    # Replace with your m6-m12 p-value
)


# 2. Run ANOVA
dn_anova_result <- aov(d_Vol/n_Vol ~ group.name, data = df_nuc_simple)
dn_anova_p <- summary(dn_anova_result)[[1]]$"Pr(>F)"[1]  # Extract p-value
summary(dn_anova_result)[[1]]$"Pr(>F)"[1]

# 3. Create bar plot with error bars (SD)
ggplot(dn_df_summary, aes(x = group.name, y = mean*100, fill = group.name)) +
  geom_bar(stat = "identity", width = 0.6, alpha = 0.8) +
  geom_errorbar(
    aes(ymin = mean*100 - sd*100, ymax = mean*100 + sd*100),
    width = 0.2,
    linewidth = 0.5
  ) +
  # # Add ANOVA p-value annotation
  # geom_text(
  #   aes(x = 1.5, y = max(mean + sd) * 1.1),
  #   label = ifelse(dn_anova_p < 0.001, "ANOVA: p < 0.001",
  #                  paste("ANOVA: p =", round(anova_p, 3))),
  #   size = 4
  # ) +
  geom_signif(
    comparisons = list(
      c("m2", "m12"), 
      c("m6", "m12")
    ),
    annotations = c(
      ifelse(t_manual_p_values["m2 vs m12"] < 0.001, "***", 
             ifelse(t_manual_p_values["m2 vs m12"] < 0.01, "**",
                    ifelse(t_manual_p_values["m2 vs m12"] < 0.05, "*", "NS"))),
      ifelse(t_manual_p_values["m6 vs m12"] < 0.001, "***", 
             ifelse(t_manual_p_values["m6 vs m12"] < 0.01, "**",
                    ifelse(t_manual_p_values["m6 vs m12"] < 0.05, "*", "NS")))
    ),
    y_position = max(dn_df_summary$mean*100 + dn_df_summary$sd*100) * c(1.1, 1.2, 1.3),
    tip_length = 0.01
  ) +
  scale_fill_npg(
    palette = c("nrc"),
    name = "Group",
    labels = c("m2", "m6", "m12")
  ) +
  labs(
    x = "Возрастная группа, мес.",
    y = "Относительный обьём DAPI+ региона, %"
  ) +
  scale_x_discrete(labels = c("m2" = "2-3", 
                              "m6" = "6-7", 
                              "m12" = "12")
  ) +
  theme_minimal() +
  theme(legend.position = "none")

jonckheereTest(d_Vol/n_Vol ~ as.numeric(factor(group.name)), 
               data = nuc_simple)

cor.test(
  x = as.numeric(nuc_simple$group.name),  # Ordered groups (numeric)
  y = (nuc_simple$d_Vol)/(nuc_simple$n_Vol),                    # Your continuous measurement
  method = "kendall"
)

#EXPERIMENTAL

#cluster diagram v1
ggplot(df_for_MQ, aes(x = log10(Vol..unit.), y = Mean)) +
  # Density contours (filled)
  stat_density_2d(
    aes(fill = group.name, alpha = after_stat(level)), 
    geom = "polygon", 
    bins = 15,
    color = NA,  # No border on contours
    show.legend = TRUE
  ) +
  # Points on top
  geom_point(
    aes(colour = group.name), 
    alpha = 0.4,
    size = 1,
    shape = 16) +
  # Modern color scheme (viridis alternative)
   scale_fill_viridis_d(
    option = "plasma",
    name = "Age Group",
    labels = c("2 months", "6 months", "12 months"),  # More descriptive
    aesthetics = c("fill", "color")  # Single scale for both
  ) +
  # Cleaner alpha scaling
  scale_alpha_continuous(
    range = c(0.2, 0.7), 
    guide = "none"  # Hide alpha legend
  ) +
  # Professional theme
  theme_minimal() +
  labs(
    x = expression(log[10]("Volume per unit")),
    y = "Mean Value",
    title = "Cluster Distribution by Group"
  )

# Cluster diagram v2 <================ [INCLUDE] [NB!] [4]
ggplot(df_for_MQ, aes(x = log10(Vol..unit.), y = Mean)) +
  # Density contours (filled)
  stat_density_2d(
    aes(fill = group.name, alpha = after_stat(level)), 
    geom = "polygon", 
    bins = 15,
    #color = group.name,  # No border on contours
    show.legend = TRUE,
    contour = TRUE
  ) +
  # Points on top
  geom_point(
    aes(colour = group.name), 
    alpha = 0.4,
    size = 1,
    shape = 16) +
  # Modern color scheme (viridis alternative)
  scale_colour_viridis_d(
    option = "viridis",
    name = "Возрастная 
    группа",
    labels = c("2-3 мес.", "6-7 мес.", "12 мес."),  # More descriptive
    aesthetics = c("fill", "color")  # Single scale for both
  ) +
  # Cleaner alpha scaling
  scale_alpha_continuous(
    name = "Density Level",  # Legend title
    range = c(0.3, 0.5),
    guide = "none"  # Show gradient as fill
  ) +
  # Professional theme
  theme_minimal() +
  labs(
    x = expression(paste("Логарифмический объём коилин+ телец, ", log[10], "(мкм"^3 * ")")),
    y = "Среднее значение серого (MGV) коилин+ телец, у.е."
  )

library(ggh4x) 

# cluster diagram v3

ggplot(df_for_MQ, aes(x = log10(Vol..unit.), y = Mean)) +
  geom_density_2d_filled(
    aes(fill = after_stat(level_mid)),  # Use level midpoints
    contour_var = "density",
    alpha = 0.7,
    bins = 64
  ) +
  scale_fill_viridis_c(
    option = "plasma",
    labels = scales::scientific  # Optional: format legend labels
  ) +
  theme_minimal() +
  labs(
    x = expression(paste("Логарифмический объём коилин+ телец, ", log[10], "(мкм"^3 * ")")),
    y = "Среднее значение серого (MGV) коилин+ телец, у.е.",
    fill = "Density"
  )

#cluster diagram v4
library(ggnewscale)
p <- ggplot(df_for_MQ, aes(x = log10(Vol..unit.), y = Mean)) +
  geom_density_2d_filled(
    aes(fill = after_stat(level_mid), group = group.name),
    alpha = 0.6,
    bins = 15,
    contour_var = "density"
  ) +
  theme_minimal() +
  theme(
    panel.background = element_rect(fill = "#121212"),
    plot.background = element_rect(fill = "#121212"),
    text = element_text(color = "white"),
    axis.text = element_text(color = "white"),
    legend.position = "bottom",
    legend.box = "vertical"
  ) +
  labs(
    x = expression(paste("Log Volume ", log[10], "(µm"^3 * ")")),
    y = "Mean Gray Value (MGV)"
  )

# Apply different viridis scales to each group
p + facetted_pos_scales(
  y = list(
    scale_fill_viridis_c(option = "plasma", name = "Group 1"),
    scale_fill_viridis_c(option = "magma", name = "Group 2"),
    scale_fill_viridis_c(option = "inferno", name = "Group 3")
  ))
  
p

#Density experimental


p <- ggplot() +
  theme_minimal() +
  labs(
    x = expression(paste("Log Volume ", log[10], "(µm"^3 * ")")),
    y = "Mean Gray Value (MGV)"
  )

# Add each group with its own scale
group_names <- unique(df_for_MQ$group.name)
color_scales <- c("cividis", "mako", "rocket")  # Viridis options

for (i in seq_along(group_names)) {
  group_data <- subset(df_for_MQ, group.name == group_names[i])
  
  p <- p +
    geom_density_2d_filled(
      data = group_data,
      aes(x = log10(Vol..unit.), y = Mean, 
          fill = after_stat(level_mid)),
      alpha = 1,
      bins = 64
    ) +
    scale_fill_viridis_c(
      option = color_scales[i],
      name = paste(group_names[i], "Density"),
      guide = guide_colorbar(order = i)  # Ensures legends stack
    )
  
  # Add new scale before next group
  if (i < length(group_names)) {
    p <- p + new_scale_fill()
  }
}

print(p)
#scales
# scale_fill_npg(
#   palette = c("nrc"),
#   name = "Group",
#   labels = c("m2", "m6", "m12")
# ) +
#
# scale_fill_nejm(
#   palette = c("default"),
#   name = "Group",
#   labels = c("m2", "m6", "m12")
# ) +
# scale_fill_nejm(
#   palette = c("default"),
#   name = "Group",
#   labels = c("m2", "m6", "m12")
# ) +


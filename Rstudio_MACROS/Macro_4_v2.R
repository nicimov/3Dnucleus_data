#============================
# MACRO IV - PROCESSING M, Q, M_D, and M_N FILES
#============================
# IMPORTANT!:
# Set working directory to group files (Ctrl+Shift+H)
# Input group name:
group_name <- "m2"  # Change this to your group identifier!

# Run with Ctrl+Shift+S

library(dplyr)

# Modify parameters to suit your workflow (if needed)
# Set starting nucleus number
starting_nuc <- 0

# Define columns to remove (to reduce unnecessary memory use)
columns_to_remove <- c("CX..pix.", "CY..pix.", "CZ..pix.", 
                       "CX..unit.", "CY..unit.", "CZ..unit.", 
                       "Xmin..pix.", "Ymin..pix.", "Zmin..pix.", 
                       "Xmax..pix.", "Ymax..pix.", "Zmax..pix.", 
                       "VolBounding..pix.", "RatioVolbox", "CompDiscrete", 
                       "Ell_MajRad", "Ell_Elon", "Ell_Flatness", 
                       "volEllipsoid..unit.", "RatioVolEllipsoid", 
                       "DCMin..unit.", "DCMax..unit.", "DCMean..unit.", "DCSD..unit.")

base_columns_to_remove <- c("Nb", "Name", "Label", "Type", "X")

# Get file lists
m_files <- list.files(pattern = "^M_\\d+\\.csv$")
q_files <- list.files(pattern = "^Q_\\d+\\.csv$")
md_files <- list.files(pattern = "^M_D_\\d+\\.csv$")
mn_files <- list.files(pattern = "^M_N_\\d+\\.csv$")

# Extract nucleus numbers
m_numbers <- as.numeric(gsub("^M_(\\d+)\\.csv$", "\\1", m_files))
q_numbers <- as.numeric(gsub("^Q_(\\d+)\\.csv$", "\\1", q_files))
common_numbers <- intersect(m_numbers, q_numbers)

# Initialize list for merged data
all_merged_data <- list()

# Process each nucleus
for (num in common_numbers) {
  # Read files
  m_data <- read.csv(paste0("M_", num, ".csv"))
  q_data <- read.csv(paste0("Q_", num, ".csv"))
  
  # Process M data
  m_data <- cbind(nucleus = num + starting_nuc, 
                  m_data[!names(m_data) %in% c(columns_to_remove, "Name", "Label", "Type", "X")])
  
  # Process Q data
  q_data <- q_data[!names(q_data) %in% c("Nb", "Name", "Label", "Type", "X")]
  
  # Process M_D if exists
  if (num %in% as.numeric(gsub("^M_D_(\\d+)\\.csv$", "\\1", md_files))) {
    md_data <- read.csv(paste0("M_D_", num, ".csv"))
    md_data <- md_data[!names(md_data) %in% c(base_columns_to_remove, columns_to_remove)]
    names(md_data) <- paste0("d_", names(md_data))
    md_data <- md_data[rep(1, nrow(m_data)), ] # Repeat for each row
  } else {
    md_data <- NULL
  }
  
  # Process M_N if exists
  if (num %in% as.numeric(gsub("^M_N_(\\d+)\\.csv$", "\\1", mn_files))) {
    mn_data <- read.csv(paste0("M_N_", num, ".csv"))
    mn_data <- mn_data[!names(mn_data) %in% c(base_columns_to_remove, columns_to_remove)]
    names(mn_data) <- paste0("n_", names(mn_data))
    mn_data <- mn_data[rep(1, nrow(m_data)), ] # Repeat for each row
  } else {
    mn_data <- NULL
  }
  
  # Merge all data
  merged_data <- cbind(m_data, q_data)
  if (!is.null(md_data)) merged_data <- cbind(merged_data, md_data)
  if (!is.null(mn_data)) merged_data <- cbind(merged_data, mn_data)
  
  all_merged_data[[as.character(num)]] <- merged_data
}

# Combine all data
final_df <- do.call(rbind, all_merged_data)

# Add measurements count
measurements_count <- as.data.frame(table(final_df$nucleus))
names(measurements_count) <- c("nucleus", "measurements")
final_df <- merge(final_df, measurements_count, by = "nucleus")

# Reorder columns
final_df <- final_df[, c("nucleus", "measurements", 
                         setdiff(names(final_df), c("nucleus", "measurements")))]

# Sort by nucleus
final_df <- final_df[order(final_df$nucleus), ]
rownames(final_df) <- NULL

# Add group name column to final_df
final_df <- cbind(group.name = factor(group_name), final_df)

# Fix "measurements" variable to be equal to 0 if "Nb"="NaN" (no nuclear bodies)
final_df <- final_df %>%
  mutate(measurements = ifelse(is.nan(Nb), 0, measurements))

# Assign with group prefix
assign(paste0(group_name, "_final_df"), final_df)
cat("Final table created with", nrow(final_df), "nuclear body entries.\n")

# Create simplified summary table
if (!require(dplyr)) install.packages("dplyr")
library(dplyr)

simplified_data <- final_df %>%
  group_by(nucleus) %>%
  summarise(
    group.name = first(group.name),
    measurements = first(measurements),
    mean_Vol = mean(Vol..unit., na.rm = TRUE),
    mean_Surf = mean(Surf..unit., na.rm = TRUE),
    mean_Min = mean(Min, na.rm = TRUE),
    mean_Max = mean(Max, na.rm = TRUE),
    mean_Mean = mean(Mean, na.rm = TRUE),
    d_Vol = first(d_Vol..unit.),
    d_Surf = first(d_Surf..unit.),
    n_Vol = first(n_Vol..unit.),
    n_Surf = first(n_Surf..unit.),
  ) %>%
  ungroup()

# Assign with group prefix
assign(paste0(group_name, "_simplified_data"), simplified_data)

# View the simplified table
# View(simplified_data)

cat("Simplified table created with", nrow(simplified_data), "nucleus entries.\n")
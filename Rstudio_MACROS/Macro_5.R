#============================
#
# FILE PROCESSING
#
#============================

# Set working directory to the folder containing CSV files
# setwd("path/to/your/folder")

# Get list of all C_#.csv files in the working directory
file_names <- list.files(pattern = "C_\\d+\\.csv$")

# Initialize an empty list to store processed data frames
processed_dfs <- list()

# Process each file
for (file in file_names) {
  # Extract the number from the filename
  file_number <- gsub("C_(\\d+)\\.csv", "\\1", file)
  
  # Read the CSV file
  df <- read.csv(file)
  
  # Add nucleus column with the file number as value
  df$nucleus <- as.numeric(file_number)
  
  # Move nucleus column to the beginning
  df <- df[, c("nucleus", setdiff(names(df), "nucleus"))]
  
  # Remove specified columns if they exist
  cols_to_remove <- c("Nb", "Type1", "Type2", "X")
  df <- df[, !(names(df) %in% cols_to_remove)]
  
  # Add processed dataframe to the list
  processed_dfs[[file]] <- df
  
  cat("Processed:", file ,"\n")
}

# Combine all dataframes vertically (and order them)
final_df_C <- do.call(rbind, processed_dfs)
final_df_C <- final_df_C[order(final_df_C$nucleus), ]
final_df_C12 <-final_df_C
cat("\nAll files processed and combined into 'final_df_C'!\n")

# Optional: Write the combined dataframe to a new CSV file
# write.csv(final_df, "combined_data_C2.csv", row.names = FALSE)
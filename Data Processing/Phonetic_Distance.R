# Quantifying Phonetic Distance Between Languages

## Overview

# This R script analyzes phonetic distance between languages using the 
# PHOIBLE database. It computes the overlap of phonetic features 
# between pairs of languages as a percentage of the total number of unique
# phonemes within each pair.

# The PHOIBLE repository of cross-linguistic phonological inventory data forms
# the basis of the phonetic distance calculations, and is available via 
# https://phoible.org/download (Moran & McCloy, 2019).


##### 1. Data Loading and Preparation #####

# Load necessary libraries
library(tidyverse) # (Wickam et al., 2019)

# 1. Read the PHOIBLE data (Moran & McCloy, 2019)
file <-     # paste file Pathname for 'values.csv' (PHOIBLE)
df_phoible <- read.csv(file)

# Reshape the data into a wider format using 'pivot_wider'
# This transforms the data so each language becomes a column,
# making comparisons easier
df_wide <- df_phoible %>%
  pivot_wider(names_from = Language_ID, values_from = Value)

# Remove columns that are not needed for the analysis
df_wide_trimmed <- subset(df_wide, select = -c(ID, Parameter_ID, Code_ID, 
                                               Comment, Source, Marginal, 
                                               Allophones, Contribution_ID)) 


##### 2. phonetic Overlap Calculation #####

# Generate all possible pairs of languages using 'combn'
language_pairs <- combn(colnames(df_wide_trimmed), 2, simplify = FALSE)

# Initialize variables for tracking progress
total_pairs <- length(language_pairs)  # Get the total number of pairs
counter <- 0   

# Calculate phonetic overlap for each language pair using 'map_dfr'
df.phonetic.distances <- map_dfr(language_pairs, function(pair) {
  # Extract phonetic features for each language in the pair
  features1 <- na.omit(df_wide_trimmed[[pair[1]]]) #Remove NAs
  features2 <- na.omit(df_wide_trimmed[[pair[2]]]) #Remove NAs
  
  # Calculate the total unique features and the number of shared features
  # (intersection)
  total_features <- unique(c(features1, features2))
  overlap <- length(intersect(features1, features2)) / length(total_features)
  
  # Update and print progress
  counter <<- counter + 1
  percentage_complete <- (counter / total_pairs) * 100
  
  if (counter %% 100000 == 0) {  # Print every 100000 iterations
    cat(sprintf("Processed %.2f%% of language pairs...\n", percentage_complete))
  }
  
  # Return the results as a tibble
  tibble(lang1 = pair[1], lang2 = pair[2], overlap = overlap)
})

# Save df.phonetic.distances in .csv format.
file <-    # Define file path and name in the format 
           # "[folder pathname]/phonetic_distances.csv"
write.csv(df.phonetic.distances, file)

#look into how to automatically create a file name and automatically create a
# a folder and extract the file path.


##### References #####

# 1.
# Moran, Steven & McCloy, Daniel (eds.) 2019. 
# PHOIBLE 2.0. 
# Jena: Max Planck Institute for the Science of Human History.
# (Available online at http://phoible.org, Accessed on 2024-06-19.)

# 2.
# Wickham H, Averick M, Bryan J, Chang W, McGowan LD, François R, Grolemund G, 
# Hayes A, Henry L, Hester J, Kuhn M, Pedersen TL, Miller E, Bache SM, Müller K, 
# Ooms J, Robinson D, Seidel DP, Spinu V, Takahashi K, Vaughan D, Wilke C, 
# Woo K, Yutani H (2019). “Welcome to the tidyverse.” _Journal of Open Source 
# Software_, *4*(43), 1686. doi:10.21105/joss.01686 
# <https://doi.org/10.21105/joss.01686>.

# 3.
# R Core Team (2023). R: A language and environment for statistical computing. 
# R Foundation for Statistical Computing, Vienna, Austria. 
# URL https://www.R-project.org/.

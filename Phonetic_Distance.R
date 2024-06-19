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
df_phoible <- read.csv("/Users/seangan/My Drive (seangan518@gmail.com)/Research
                       /Language Differences/PHOIBLE/cldf/values.csv")

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
df.phonetic.overlap <- map_dfr(language_pairs, function(pair) {
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


##### 3. Optimal Network Cutoff Determination #####

# Load the 'igraph' package for network analysis (Csárdi et al., 2024)
library(igraph)

# Sort the overlap data frame in descending order by overlap
df_sorted <- df.phonetic.overlap[order(-df.phonetic.overlap$overlap), ]

# Initialize the threshold for overlap
threshold <- 1.0

# Find the optimal cutoff for a fully connected network graph
while (threshold > 0) {
  # Filter the data frame based on the current threshold
  filtered_df <- df_sorted[df_sorted$overlap >= threshold, ]
  
  # Create a network graph from the filtered data
  G <- graph_from_data_frame(filtered_df[, c("lang1", "lang2")], directed = FALSE)
  
  # Check if the graph is connected (all nodes can reach each other)
  if (is_connected(G)) {
    break  # If connected, we found our cutoff
  } else {
    threshold <- threshold - 0.01  # Decrease the threshold and try again
  }
}

# Print the optimal cutoff value
cat("Optimal Cutoff:", threshold, "\n")


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
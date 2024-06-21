# Optimal Edge Width Calculation for Network Map Optimization

## Overview

# This script calculates the optimal edge width cutoff to enhance network
# map readability by keeping edge number low, while ensuring that all nodes are
# connected to at least one other node.


##### Optimal Edge Width Calculation #####

# Load the 'igraph' package for network analysis (Csárdi et al., 2024)
library(igraph)

# Sort the overlap data frame in descending order by overlap
df_sorted <- df.phonetic.distances[order(-df.phonetic.distances$overlap), ]

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
# Csárdi G, Nepusz T, Traag V, Horvát Sz, Zanini F, Noom D, Müller K (2024). 
# _igraph: Network Analysis and Visualization in R_.
# doi:10.5281/zenodo.7682609 <https://doi.org/10.5281/zenodo.7682609>, 
# R package version 2.0.3, <https://CRAN.R-project.org/package=igraph>.

# 2.
# R Core Team (2023). R: A language and environment for statistical computing. 
# R Foundation for Statistical Computing, Vienna, Austria. 
# URL https://www.R-project.org/.

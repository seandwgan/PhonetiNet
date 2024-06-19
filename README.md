# PhonetiNet: Quantifying and Visualizing Phonetic Distance Between Languages

## Description

PhonetiNet is an R/python-based project that analyzes and visualizes the phonetic similarities between languages. It applies the PHOIBLE database, a comprehensive collection of phonetic inventories, to calculate the pairwise phonetic overlap between languages. The project then constructs a network graph where languages are connected based on their shared phonetic features, offering a visual representation of their relationships and clusters.

## Key Features

- **Phonetic Overlap Calculation:**  Computes the proportion of shared phonetic features between all possible pairs of languages in the PHOIBLE dataset.
- **Network Graph Generation:** Creates an interactive network graph that visualizes the phonetic connections between languages.
- **Optimal Threshold Determination:** Identifies the optimal threshold of phonetic overlap for including connections in the network graph, ensuring a balance between informativeness and clarity.

## Usage

1. **Clone the repository:** `git clone https://github.com/seandwgan/PhonetiNet.git`
2. **Install dependencies:** Ensure you have R and the following packages installed:
   - `tidyverse`
   - `igraph`
3. **Prepare data:** 
    - Download the PHOIBLE data (`values.csv`) from [https://phoible.org/](https://phoible.org/)
    - Define the Pathname for `values.csv` in `Phonetic_Distance.R`
4. **Run the scripts:**  Execute `Phonetic_Distance.R` and `Optimal_Edge_Width.R` in R or RStudio.
5. **Explore the results:**
   - `Phonetic_Distance.R` will generate a CSV file (`phonetic_overlap.csv`) containing pairwise phonetic overlap values.
   - `Optimal_Edge_Width.R` will print the optimal cutoff value for the network graph.
   - (Soon) An interactive network graph will be displayed, allowing you to explore the relationships between languages.

## Data Source

Phonetic data is sourced from the PHOIBLE database: [https://phoible.org/](https://phoible.org/)

## License

This project is licensed under the GNU General Public License v3.0 or later.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

## Contact

For questions or feedback, please contact Sean Gan at gan.sean@pm.me.

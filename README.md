# PhonetiNet: Quantifying and Mapping Phonetic Distance Between Languages

## Description

PhonetiNet is an R-based project that analyzes and visualizes the phonetic similarities between languages. It applies the PHOIBLE database, a comprehensive collection of phonetic inventories, to calculate the pairwise phonetic overlap between languages. The project then generates an interactive network visualisation tool, with language and phonological searching features, and sub-network generation.

## Key Features

- **Phonetic Overlap Calculation:**  Computes the proportion of shared phonetic features between all possible language pairs in the PHOIBLE phonological database.
- **Optimal Threshold Determination:** Identifies the optimal threshold of phonetic overlap for including connections in the network graph, for stronger clustering without isolated nodes.
- **Interactive Network App:** Generates an interactive network mapping application that visualizes the phonetic connections between languages, supporting language searching and sub-network generation for focused analyses.

## Getting Started

1. **Clone the repository:** `git clone https://github.com/seandwgan/PhonetiNet.git`
2. **To use the app**, run `app.R`
3. **To run your own analyses**, start with `Phonetic_Distance.R`, then follow up with `Optimal_Edge_Width.R` and `Network_Visualization.R`

## Data Source

Phonetic data is sourced from the PHOIBLE database: [https://phoible.org/](https://phoible.org/)

## License

This project is licensed under the GNU General Public License v3.0 or later.

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

## Contact

For questions or feedback, please contact me at gan.sean@pm.me.

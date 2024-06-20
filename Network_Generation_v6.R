# Network Generation

library(igraph)
library(visNetwork)
library(shiny)
library(dplyr)

# Load your data
file <-   #"[phonetic_distances.csv Pathname]"
df.phonetic.distances <- read.csv(file)

# Load language names
file <-   #"[languages.csv Pathname]"
df.languages <- read.csv(file)
df.language.names <- df.languages[, 1:2]

# Set minimum edge width, calculated in 'Optimal_Edge_Width.R'
min_edge_width <- 0.34

df.phonetic.distances.trimmed <- subset(df.phonetic.distances, df.phonetic.distances$overlap >= min_edge_width)

# Create graph object
g <- graph_from_data_frame(df.phonetic.distances.trimmed[, c("lang1", "lang2")])
E(g)$weight <- as.numeric(df.phonetic.distances.trimmed$overlap)

# Scale and adjust edge weights (add small constant and multiply)
E(g)$weight <- E(g)$weight + 0.01

# Calculate betweenness centrality
betweenness <- betweenness(g)
normalized_betweenness <- (betweenness - min(betweenness)) / (max(betweenness) - min(betweenness))

# Add numeric IDs to nodes AFTER filtering
V(g)$id <- 1:vcount(g) # Reset IDs to match the filtered graph

# Match node names to language codes
matched_names <- match(V(g)$name, df.language.names$ID)

# Replace node labels with full language names
V(g)$label <- df.language.names$Name[matched_names]
V(g)$label[is.na(matched_names)] <- "Unknown Language"

# Create node data frame (with updated node IDs and labels)
nodes <- data.frame(
  id = V(g)$id,
  label = V(g)$label,
  size = normalized_betweenness[V(g)$id] * 30 + 5 # Use updated node IDs
)
nodes$id <- as.numeric(nodes$id)  # Convert to numeric and update the column
# Create edge data frame, ensuring node IDs match

edges <- data.frame(
  from = get.edgelist(g)[,1],
  to = get.edgelist(g)[,2],
  width = E(g)$weight * 5
)

# Create the interactive network visualization
PhonetiNet <- visNetwork(nodes, edges) %>%
  visIgraphLayout(layout = "layout_with_drl", randomSeed = 123) %>%
  visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
  visInteraction(navigationButtons = TRUE)
PhonetiNet

nodes$title <- nodes$label

# Shiny UI
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .vis-tooltip {
        position: fixed; visibility:hidden; padding: 5px; white-space: nowrap; 
        font-family: verdana; font-size:14px; font-color:#000000; background-color: #f5f4ed; 
        -moz-border-radius: 3px; -webkit-border-radius: 3px; border-radius: 3px; 
        border: 1px solid #808074; box-shadow: 3px 3px 10px rgba(0, 0, 0, 0.2);
      }
      .vis-network { width: 100%; } 
    "))
  ),
  titlePanel("PhonetiNet"),
  sidebarLayout(
    sidebarPanel(
      textInput("search", "Search Node:", placeholder = "Enter Language Name"),
      actionButton("resetHighlight", "Reset Highlight"),
      textOutput("searchMessage"),
      numericInput("maxConnectedNodes", "Max Connected Nodes:", value = 5, min = 1) # New input box
    ),
    mainPanel(
      visNetworkOutput("network", height = "800px") 
    )
  )
)

# Shiny Server
server <- function(input, output, session) {
  
  selected_node <- reactiveVal(NULL)
  
  # Output the network
  output$network <- renderVisNetwork({
    visNetwork(nodes, edges) %>%
      visIgraphLayout(layout = "layout_with_drl", randomSeed = 123) %>%
      visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
      visInteraction(navigationButtons = TRUE, hover = TRUE, tooltipDelay = 0) %>%
      visEvents(
        select = "function(params) {
          Shiny.onInputChange('clicked_node', params.nodes[0]);
        }",
        hoverNode = "function(params) {
          Shiny.onInputChange('hovered_node', params.node);
        }",
        blurNode = "function(params) {
          Shiny.onInputChange('hovered_node', null);
        }"
      )
  })
  
  # Reactive values to track highlighted nodes
  highlighted_nodes <- reactiveVal(NULL)
  search_nodes <- reactiveVal(NULL)
  
  # Observe node click events for highlighting
  observeEvent(input$clicked_node, {
    selected_node(input$clicked_node)
    
    if (!is.null(selected_node())) {
      clicked_node_name <- V(g)$name[V(g)$id == selected_node()]
      
      # Find the connected component of the clicked node using its name
      component <- subcomponent(g, v = which(V(g)$name == clicked_node_name), mode = "out")
      
      highlighted_nodes(V(g)$id[component])  # Use numeric IDs for highlighting
      
      highlighted_edges <- subset(edges, from %in% clicked_node_name | to %in% clicked_node_name)
      
      # Sort highlighted_edges by width
      highlighted_edges <- highlighted_edges %>% arrange(desc(width))
      
      # Limit highlighted nodes based on max_nodes
      highlighted_edges <- head(highlighted_edges, input$maxConnectedNodes)
      
      # Extract unique node names from highlighted_edges
      highlighted_node_names <- unique(c(highlighted_edges$from, highlighted_edges$to))
      
      highlighted_node_ids <- V(g)$id[V(g)$name %in% highlighted_node_names]
      
      # Update node and edge colors (corrected)
      visNetworkProxy("network") %>%
        visUpdateNodes(nodes = data.frame(
          id = nodes$id,
          color = ifelse(as.numeric(nodes$id) %in% highlighted_node_ids, "purple", "skyblue"),
          value = ifelse(nodes$id %in% highlighted_node_ids, nodes$size * 10, nodes$size)# Purple for connected nodes
        )) %>%
        visUpdateEdges(edges = data.frame(
          id = edges$id,
          color = ifelse(as.numeric(edges$id) %in% highlighted_node_ids, "purple", "gray"),
          value = ifelse(edges$id %in% highlighted_node_ids, nodes$size * 10, nodes$size)  # Double size for purple nodes
        ))
    } else {
      # Reset node and edge colors when no node is clicked
      visNetworkProxy("network") %>%
        visUpdateNodes(nodes = data.frame(
          id = nodes$id,
          color = "skyblue"
        )) %>%
        visUpdateEdges(edges = data.frame(
          id = edges$id,
          color = "gray"
        ))
    }
  })
  
  # Update highlighted nodes based on search or reset
  observeEvent(input$search, {
    search_term <- input$search
    matched_nodes <- nodes %>% filter(grepl(search_term, label, ignore.case = TRUE))
    if (nrow(matched_nodes) > 0) {
      search_nodes(matched_nodes$id)
      highlighted_nodes(NULL) # Reset the clicked node when searching
    } 
    
    # Update search result message
    if (nrow(matched_nodes) == 0) {
      output$searchMessage <- renderText("No matching nodes found.")
      search_nodes(NULL)
    } else {
      output$searchMessage <- renderText("")
    }
    
    observeEvent(input$resetHighlight, {
      highlighted_nodes(nodes$id)  # Show all nodes when reset
      highlighted_edges(edges$id) # Show all edges when reset
      search_nodes(NULL)
      output$searchMessage <- renderText("")  # Clear message on reset
    })
    
    #Update node colors based on highlighting
    observeEvent(c(search_nodes()), {
      search_node_ids <- search_nodes()
      
      visNetworkProxy("network") %>%
        visUpdateNodes(nodes = data.frame(
          id = nodes$id,
          color = ifelse(nodes$id %in% search_node_ids, "red", "skyblue"),
          value = ifelse(nodes$id %in% search_node_ids, nodes$size * 10, nodes$size))  # Double size for red nodes)
        )
    }
    )
  }
  )
  
  # Tooltip handling
  observeEvent(input$hovered_node, {
    if (!is.null(input$hovered_node)) {
      # Update tooltip text only when hovered
      visNetworkProxy("network") %>%
        visUpdateNodes(nodes = data.frame(
          id = input$hovered_node,
          title = nodes$title[nodes$id == input$hovered_node]
        ))
    } 
  })
  
  # Output node information (when a node is selected)
  output$nodeInfo <- renderTable({
    req(input$clicked_node)  # Only show the table if a node is clicked
    
    # Get information about the clicked node
    clicked_node_data <- nodes %>% filter(id == input$clicked_node)
    
    # You can customize the information displayed here:
    data.frame(
      Language = clicked_node_data$label,
      Centrality = round(normalized_betweenness[clicked_node_data$id], 3) # Add more columns as needed
    )
  })
  
}  # End of server function

# Run Shiny App
shinyApp(ui, server)


# Network Visualization for Phonetic Distances

library(igraph)
library(visNetwork)
library(shiny)
library(dplyr)

load("df.language.names.RDa")
load("df.languages.RDa")
load("df.phonetic.distances.RDa")
load("edges.RDa")
load("g.Rda")
load("nodes.RDa")
load("normalized_betweenness.RDa")

# Node and Edge Data Frames
# Assign unique numeric IDs to nodes
V(g)$id <- 1:vcount(g)

# Match node names to language IDs and replace with full language names
V(g)$label <- df.language.names$Name[match(V(g)$name, df.language.names$ID)]
V(g)$label[is.na(V(g)$label)] <- "Unknown Language"

# Create node data frame
nodes <- data.frame(
  id = V(g)$id,
  label = V(g)$label,
  size = normalized_betweenness[V(g)$id,] * 30 + 5 # Use updated node IDs
)
nodes$id <- as.numeric(nodes$id)

# Create edge data frame
edges <- data.frame(
  from = as_edgelist(g)[,1],
  to = as_edgelist(g)[,2],
  width = E(g)$weight * 5
)


nodes$title <- nodes$label

# Shiny UI
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .vis-tooltip {
        position: fixed; visibility:hidden; padding: 5px; white-space: nowrap; 
        font-family: verdana; font-size:14px; font-color:#000000; 
        background-color: #f5f4ed; -moz-border-radius: 3px; 
        -webkit-border-radius: 3px; border-radius: 3px; border: 1px solid #808074; 
        box-shadow: 3px 3px 10px rgba(0, 0, 0, 0.2);
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
      numericInput("maxConnectedNodes", "Max Connected Nodes:", value = 5, 
                   min = 1) # New input box
    ),
    mainPanel(
      actionButton("generateFromSelected", "Generate from Selected"),
      actionButton("resetNetwork", "Reset Network"),
      visNetworkOutput("network", height = "800px") 
    )
  )
)

# Shiny Server
server <- function(input, output, session) {
  
  selected_node <- reactiveVal(NULL)
  
  random_index <- sample(1:nrow(nodes), 1)
  random_number <- nodes$id[random_index]
  
  # Output the network
  output$network <- renderVisNetwork({
    visNetwork(nodes, edges) %>%
      visIgraphLayout(layout = "layout_with_drl", randomSeed = random_number) %>%
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
  highlighted_edges <- reactiveVal(NULL)
  search_nodes <- reactiveVal(NULL)
  new_nodes <- reactiveVal(NULL)
  new_edges <- reactiveVal(NULL)
  
  # Observe node click events for highlighting
  observeEvent(input$clicked_node, {
    selected_node(input$clicked_node)
    
    if (!is.null(selected_node())) {
      clicked_node_name <- V(g)$name[V(g)$id == selected_node()]
      
      # Find the connected component of the clicked node using its name
      component <- subcomponent(g, v = which(V(g)$name == clicked_node_name), 
                                mode = "out")
      
      highlighted_nodes(V(g)$id[component])  # Use numeric IDs for highlighting
      
      highlighted_edges <- subset(edges, from %in% clicked_node_name | 
                                    to %in% clicked_node_name)
      
      # Sort highlighted_edges by width
      highlighted_edges <- highlighted_edges %>% arrange(desc(width))
      
      # Limit highlighted nodes based on max_nodes
      highlighted_edges <- head(highlighted_edges, input$maxConnectedNodes)
      
      # Extract unique node names from highlighted_edges
      highlighted_node_names <- unique(c(highlighted_edges$from, 
                                         highlighted_edges$to))
      
      highlighted_node_ids <- V(g)$id[V(g)$name %in% highlighted_node_names]
      
      new_nodes(subset(nodes, id %in% highlighted_node_ids))
      new_edges(highlighted_edges)
      
      # Update node and edge colors (corrected)
      visNetworkProxy("network") %>%
        visUpdateNodes(nodes = data.frame(
          id = nodes$id,
          color = ifelse(as.numeric(nodes$id) %in% highlighted_node_ids, 
                         "purple", "skyblue"),
          size = ifelse(nodes$id %in% highlighted_node_ids, nodes$size * 2, 
                        nodes$size)# Purple for connected nodes
        )) %>%
        visUpdateEdges(edges = data.frame(
          id = edges$id,
          color = ifelse(as.numeric(edges$id) %in% highlighted_node_ids, 
                         "purple", "gray"),
          size = ifelse(edges$id %in% highlighted_node_ids, nodes$size * 2, 
                        nodes$size)  # Double size for purple nodes
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
  
  # Observe the "Generate from Selected" button
  observeEvent(input$generateFromSelected, {
    
    req(highlighted_nodes())  # Make sure some nodes are highlighted
    
    random_index <- sample(1:nrow(new_nodes()), 1)
    random_number <- new_nodes()$id[random_index] 
    
    output$network <- renderVisNetwork({
      visNetwork(new_nodes(), new_edges()) %>%
       visIgraphLayout(layout = "layout_with_drl", 
                       randomSeed = random_number) %>%
        visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
        visInteraction(navigationButtons = TRUE, hover = TRUE, 
                       tooltipDelay = 0) %>%
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
    }
    )
  
  # Observe "Reset Network" button click
  observeEvent(input$resetNetwork, {
    highlighted_nodes(NULL)  # Clear highlighted nodes
    
    random_index <- sample(1:nrow(nodes), 1)
    random_number <- nodes$id[random_index] 
    
    output$network <- renderVisNetwork({
      visNetwork(nodes, edges) %>%
        visIgraphLayout(layout = "layout_with_drl", 
                        randomSeed = random_number) %>%
        visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE) %>%
        visInteraction(navigationButtons = TRUE, hover = TRUE, 
                       tooltipDelay = 0) %>%
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
  }
  )
  
  # Update highlighted nodes based on search or reset
  observeEvent(input$search, {
    search_term <- input$search
    matched_nodes <- nodes %>% filter(grepl(search_term, label, 
                                            ignore.case = TRUE))
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
          size = ifelse(nodes$id %in% search_node_ids, nodes$size * 2, 
                        nodes$size))  # Double size for red nodes)
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
      Centrality = round(normalized_betweenness[clicked_node_data$id,], 3)
    )
  })
}  # End of server function

# Run Shiny App
shinyApp(ui, server)


##### References #####

# 1.
# Moran, Steven & McCloy, Daniel (eds.) 2019. 
# PHOIBLE 2.0. 
# Jena: Max Planck Institute for the Science of Human History.
# (Available online at http://phoible.org, Accessed on 2024-06-19.)

# 2.
# R Core Team (2023). R: A language and environment for statistical computing. 
# R Foundation for Statistical Computing, Vienna, Austria. 
# URL https://www.R-project.org/.

# 3.
# Csárdi G, Nepusz T, Traag V, Horvát Sz, Zanini F, Noom D, Müller K (2024).
# _igraph: Network Analysis and Visualization in R_. 
# doi:10.5281/zenodo.7682609 <https://doi.org/10.5281/zenodo.7682609>, 
# R package version 2.0.3, <https://CRAN.R-project.org/package=igraph>.

# 4.
# Almende B.V. and Contributors, Thieurmel B (2022). 
# _visNetwork: Network Visualization using 'vis.js' Library_. 
# R package version 2.1.2, <https://CRAN.R-project.org/package=visNetwork>.

# 5.
# Chang W, Cheng J, Allaire J, Sievert C, Schloerke B, Xie Y, Allen J, 
# McPherson J, Dipert A, Borges B (2024). _shiny: Web Application Framework 
# for R_. R package version 1.8.1, <https://CRAN.R-project.org/package=shiny>.

# 6.
# Wickham H, François R, Henry L, Müller K, Vaughan D (2023). _dplyr: A Grammar 
# of Data Manipulation_. R package version 1.1.4, 
# <https://CRAN.R-project.org/package=dplyr>.

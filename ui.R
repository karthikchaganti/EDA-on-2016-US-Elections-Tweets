library(ggvis)
library(shiny)

langs <- list("All"="all", "English"="en", "French"="fr" , "German"="ge" , "Italian"="it", "Spanish"="sp")

shinyUI(fluidPage(theme="bootstrap.min.css",
          # Application title
         
          titlePanel("2016 US Elections Tweets Analysis"),
          
          sidebarLayout(
            # Sidebar with a slider and selection inputs
            sidebarPanel(
              selectInput("source1","Choose candidates:",
                          choices=c("#DonaldTrump","#HillaryClinton","#TedCruz","#BernieSanders",
                                                                   selected = "#HillaryClinton")),
              
              conditionalPanel(
                condition = "input.show_source2 == true",
                selectInput("source2","Compare with:",choices=c("#Donald Trump","#Hillary Clinton","#Ted Cruz","#Bernie Sanders",
                                                                selected = "#Hillary Clinton"))
              ),
              
              checkboxInput("show_source2", "Compare"),
              actionButton("plot_feel", "Plot Sentiments"),
              hr(),
              
              selectInput("lang",
                          "Language:", langs)
              
            ),
            
            
            mainPanel(
              tabsetPanel(
              tabPanel("Live",
                       
              verbatimTextOutput("tweet_view"),
              
              verbatimTextOutput("printer"),
              
              h4("The Sentiments Timeline"),
              
              helpText("Click on dots to read the tweet!"),
              
              ggvisOutput("plot1"),
              
              h4("Analytics"),
              
              
              plotOutput("trends"),
              
              h4("A few tweets!"),
              
              tableOutput("viewtable"),
              
              h4("Sources"),
              
              plotOutput("plot")
              ),
              tabPanel("Last Week Analytics",sliderInput("slider", "Slide to get older tweets by days:", 1, 7, 1),h4("Old Sentiments Timeline"),
                       helpText("Click on dots to read the tweet!"),ggvisOutput("plot2"),h4("Analytics"), plotOutput("trends_old"),h4("A few tweets!"),tableOutput("vs_viewtable"), h4("Sources"),
                       plotOutput("plot_old"))
              )
          ))
))

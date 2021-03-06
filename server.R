#install.packages("twitteR")
#install.packages("plyr")
#install.packages("stringr")
#install.packages("ggvis")
#install.packages("ggplot2")
#install.packages("memoise")
#install.packages("gridExtra")

# Function to check if package exists already
checkForPackage <- function(pack){
  is.element(pack, installed.packages()[,1])
}
if(!checkForPackage("twitteR")){
  install.packages("twitteR")
}
if(!checkForPackage("plyr")){
  install.packages("plyr")
}
if(!checkForPackage("stringr")){
  install.packages("stringr")
}



if(!checkForPackage("ggvis")){
  install.packages("ggvis")
}
if(!checkForPackage("ggplot2")){
  install.packages("ggplot2")
}
if(!checkForPackage("memoise")){
  install.packages("memoise")
}
if(!checkForPackage("gridExtra")){
  install.packages("gridExtra")
}


library(twitteR)
library(plyr)
library(stringr)
library(ggvis)
library(ggplot2)
library(memoise)
library(gridExtra)


options(shiny.trace=TRUE)

n_tweets <- 180
n_summary <- 10


consumerKey <- "PPPleVlMJJ92SJyoSscjabRdy"
consumerSecret <- "hI6OzAUGOpYePHaCIkuq6dOfMNJ2BTL51EixB687KmeH3hQ8X8"
acessToken <- "97679565-0nRLpRoI5SnHwjob6Czya5xfci9BBZynyUqpeyTTd"
accessTokenSecret <- "cviNSxQagHsE44S8lT5jecUos11aNPfRhivNFx6AQaBSo"


setup_twitter_oauth(consumerKey, consumerSecret, acessToken, accessTokenSecret)

shinyServer(function(input, output, session) {
  # Define a reactive expression for the document term matrix

  tryTolower = function(x){
    # create missing value
    # this is where the returned value will be
    y = NA
    # tryCatch error
    try_error = tryCatch(tolower(x), error = function(e) e)
    # if not an error
    if (!inherits(try_error, "error"))
      y = tolower(x)
    return(y)
  }

  score.sentiment <- function(sentences, pos.words, neg.words, .progress='none')
  {
    scores = laply(sentences, function(sentence, pos.words, neg.words) {

      # clean up sentences with R's regex-driven global substitute, gsub():
      sentence = gsub('[[:punct:]]', '', sentence)
      sentence = gsub('[[:cntrl:]]', '', sentence)
      sentence = gsub('\\d+', '', sentence)
      # and convert to lower case:
      #sentence = tolower(sentence)

      # split into words. str_split is in the stringr package
      word.list = str_split(sentence, '\\s+')
      # sometimes a list() is one level of hierarchy too much
      words = unlist(word.list)

      # compare our words to the dictionaries of positive & negative terms
      pos.matches = match(words, pos.words)
      neg.matches = match(words, neg.words)

      # match() returns the position of the matched term or NA
      # we just want a TRUE/FALSE:
      pos.matches = !is.na(pos.matches)
      neg.matches = !is.na(neg.matches)

      # and conveniently enough, TRUE/FALSE will be treated as 1/0 by sum():
      score = sum(pos.matches) - sum(neg.matches)

      return(score)
    }, pos.words, neg.words, .progress=.progress )

    scores.df = data.frame(score=scores, text=sentences)
    return(scores.df)
  }

  cleanFun <- function(htmlString) {
    return(gsub("<.*?>", "", htmlString))
  }

  get_source <- function(x){
    X <- cleanFun(x[["statusSource"]])
    X
    }

  tweets_df <- reactive({
    # Change when the "update" button is pressed...
    input$plot_feel
    # ...but not for anything else
    isolate({
      withProgress({
        setProgress(message = "Please wait for a moment......")

        
        tweets <- searchTwitter(input$source1,n=n_tweets)
        tweets <- strip_retweets(tweets, strip_manual=TRUE, strip_mt=TRUE)

         df <- twListToDF(tweets)

         df$Search <- input$source1

         if( (input$show_source2 == TRUE) && (input$source2 != ""))
         {
           tweets2 <- searchTwitter(input$source2, n=n_tweets)
           tweets2 <- strip_retweets(tweets2, strip_manual=TRUE, strip_mt=TRUE)
           df2 <- twListToDF(tweets2)
           df2$Search <- input$source2
           df <- rbind(df, df2)
           tweets <- c(tweets, tweets2)
         }


  df$Date <- format(df$created,'%m/%d/%Y %H:%I:%S')
  df$Source <-  apply(df, 1, get_source)

  sentences <- sapply(df$text, function(x) tryTolower(x))

  scores <- score.sentiment(sentences, pos.words, neg.words)
  df <- cbind(df, scores)

  df <- df[, c("id", "text", "Source", "Date", "Search", "created", "score")]
  names(df) <- c("id", "Post", "Source", "Date", "Search", "created", "score")



  df
      })
    })
  })
  
  tweets_df_old <- reactive({
    # Change when the "update" button is pressed...
    input$slider
    input$plot_feel
   
    # ...but not for anything else
    isolate({
      withProgress({
        setProgress(message = "Please wait for a moment......")
        
        tweetdays <- input$slider
        tweets <- searchTwitter(input$source1,n=n_tweets,since =as.character(Sys.Date()-tweetdays), until= as.character(Sys.Date()-tweetdays+1))
        tweets <- strip_retweets(tweets, strip_manual=TRUE, strip_mt=TRUE)
        
        df <- twListToDF(tweets)
        
        df$Search <- input$source1
        
        if( (input$show_source2 == TRUE) && (input$source2 != ""))
        {
          tweets2 <- searchTwitter(input$source2, n=n_tweets,since =as.character(Sys.Date()-tweetdays), until= as.character(Sys.Date()-tweetdays+1))
          tweets2 <- strip_retweets(tweets2, strip_manual=TRUE, strip_mt=TRUE)
          df2 <- twListToDF(tweets2)
          df2$Search <- input$source2
          df <- rbind(df, df2)
          tweets <- c(tweets, tweets2)
        }
        
        
        df$Date <- format(df$created,'%m/%d/%Y %H:%I:%S')
        df$Source <-  apply(df, 1, get_source)
        
        sentences <- sapply(df$text, function(x) tryTolower(x))
        
        scores <- score.sentiment(sentences, pos.words, neg.words)
        df <- cbind(df, scores)
        
        df <- df[, c("id", "text", "Source", "Date", "Search", "created", "score")]
        names(df) <- c("id", "Post", "Source", "Date", "Search", "created", "score")
        
        
        
        df
      })
    })
  })


  output$plot <- renderPlot({
    df <- tweets_df()
    sources <- df$Source
    sources <- sapply(sources, function(x) ifelse(length(x) > 1, x[2], x[1]))
    source_table <- table(sources)
    s_t <- source_table[source_table > 10]
    pie(s_t, col = rainbow(length(s_t)))

  })
  output$plot_old <- renderPlot({
    df <- tweets_df_old()
    sources <- df$Source
    sources <- sapply(sources, function(x) ifelse(length(x) > 1, x[2], x[1]))
    source_table <- table(sources)
    s_t <- source_table[source_table > 10]
    pie(s_t, col = rainbow(length(s_t)))
    
  })

  output$trends <- reactive({
    df <- tweets_df()
    
    source1 <- df[df$Search==input$source1,]
    p1 <- ggplot(source1, aes(x=created, y=score)) + geom_point(shape=1, size=0)+geom_smooth(se=F)+labs(title=input$source1, x = "Date /Time", y = "Popularity") + ylim(-5, 5)
    
    if( (input$show_source2 == TRUE) && (input$source2 != ""))
    {
      source2 <- df[df$Search==input$source2,]
      
      p2 <- ggplot(source2, aes(x=created, y=score)) + geom_point(shape=1, size=0)+geom_smooth(se=F)+labs(title=input$source2, x = "Date /Time", y = "Popularity") + ylim(-5, 5)
      grid.arrange(p1, p2, nrow=1, ncol=2)
    }
    else
      print(p1)
    
  })
  
  output$trends_old <- reactive({
    df <- tweets_df_old()
    
    source1 <- df[df$Search==input$source1,]
    p1 <- ggplot(source1, aes(x=created, y=score)) + geom_point(shape=1, size=0)+geom_smooth(se=F)+labs(title=input$source1, x = "Date /Time", y = "Popularity") + ylim(-5, 5)
    
    if( (input$show_source2 == TRUE) && (input$source2 != ""))
    {
      source2 <- df[df$Search==input$source2,]
      
      p2 <- ggplot(source2, aes(x=created, y=score)) + geom_point(shape=1, size=0)+geom_smooth(se=F)+labs(title=input$source2, x = "Date /Time", y = "Popularity") + ylim(-5, 5)
      grid.arrange(p1, p2, nrow=1, ncol=2)
    }
    else
      print(p1)
    
  })
  



  
  output$tweet_view <- renderPrint({
    if( (input$show_source2 == TRUE) && (input$source2 != ""))
      cat(paste(input$source1, " vs. ", input$source2))
    else
      cat(input$source1)
  })
  
  output$printer <- renderPrint({
    df <- tweets_df()
    df <- df[df$Search==input$source1,]
    df$Post[1]
  })
  output$printer_old <- renderPrint({
    df <- tweets_df_old()
    df <- df[df$Search==input$source1,]
    df$Post[1]
  })
  
  output$viewtable <- renderTable({
    df <- tweets_df()
    df <- df[df$Search==input$source1,]
    head(df, n = 5, addrownums=F)
  })
  
  output$vs_viewtable <- renderTable({
    
    
      df <- tweets_df_old()
      df <- df[df$Search==input$source1,]
      head(df, n = 5, addrownums=F)
    
  })
  
  
  # Function for generating tooltip text
  movie_tooltip <- function(x) {
    if (is.null(x)) return(NULL)
    if (is.null(x$id)) return(NULL)
    
    all_tweets <- isolate(tweets_df())
    tweet <- all_tweets[all_tweets$id == x$id, ]
    
    paste0("<b>", tweet$Post, "</b><br><em><small>from ", tweet$Source, " (", tweet$Date, ")</small></em>")
  }
  movie_tooltip_old <- function(x) {
    if (is.null(x)) return(NULL)
    if (is.null(x$id)) return(NULL)
    
    all_tweets <- isolate(tweets_df_old())
    tweet <- all_tweets[all_tweets$id == x$id, ]
    
    paste0("<b>", tweet$Post, "</b><br><em><small>from ", tweet$Source, " (", tweet$Date, ")</small></em>")
  }

  vis <- reactive({
    legend_val <- c(input$source1)
    if( (input$show_source2 == TRUE) && (input$source2 != ""))
      legend_val <- c(input$source1, input$source2)
    
    df <- tweets_df()
    
    df %>%  ggvis(~created, ~score) %>% layer_points(fill = ~Search, key := ~id)  %>% layer_lines(stroke=~Search) %>% add_legend(c("fill", "stroke"), orient="left") %>% add_axis("x", title = "Date Time") %>% add_axis("y", title = "Popularity") %>% set_options(width = 800, height = 300) %>% add_tooltip(movie_tooltip, "click")
  })
  vis3 <- reactive({
    
    df <- tweets_df_old()
    
    df %>%  ggvis(~created, ~score) %>% layer_points(fill = ~Search, key := ~id)  %>% layer_lines(stroke=~Search) %>% add_legend(c("fill", "stroke"), orient="left") %>% add_axis("x", title = "Time") %>% add_axis("y", title = "Popularity") %>% set_options(width = 750, height = 300) %>% add_tooltip(movie_tooltip_old, "click")
    
  })
  
  vis %>% bind_shiny("plot1")
  vis3 %>% bind_shiny("plot2")
  #vis6 %>% bind_shiny("plot3")

})

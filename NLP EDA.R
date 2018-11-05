## Exploratory Data Analysis for Natural Language Processing

    ##rm(list=ls())
    library(tm)
    library(readr)
    library(stringi)
    library(SnowballC)
    library(quanteda)
    library(RColorBrewer)
    
    setwd("~/DataScience/CapstoneJHU")
    dirData <- "~/DataScience/CapstoneJHU/data/"
    
    lstLanguage <- c("de_DE","en_US","fi_FI","ru_RU")
    lstDoctype <- c(".blogs",".news",".twitter")
    lstFileDE <- c("de_DE.blogs","de_DE.news","de_DE.twitter")
    lstFileEN <- c("en_US.blogs","en_US.news","en_US.twitter")
    lstFileFI <- c("fi_FI.blogs","fi_FI.news","fi_FI.twitter")
    lstFileRU <- c("ru_RU.blogs","ru_RU.news","ru_RU.twitter")

    
## --------------------------------------------------------------------------
## REUSABLE FUNCTIONS
## --------------------------------------------------------------------------
    
    ## makes filename from directory, language, doctype and extension        
    getFilename <- function(tDir,tLanguage,tDocName,tExtension) {
        tDir <- paste(tDir,tLanguage,"/",sep="")
        tFilename <-paste(tDir,tDocName,tExtension,sep="")
        tFilename }
    
    ## get file information
    getSizeMb <- function(data){format(x = object.size(data), units = "auto")}
    getLength <- function(data){format(x = length(data),big.mark = ",")}
    getWordCount <- function(data){
        value <- sum(sapply(gregexpr("\\W+", data), length) + 1)
        format(x = value,big.mark = ",")}

    
    ## read text File, print no of lines, return data
    readTextFile <- function(tDir,tLanguage,tDocName) {
        fileData <-getFilename(tDir,tLanguage,tDocName,".txt")
        tData <- scan(file = fileData,sep = '\n', what = '', skipNul = TRUE)
        print(fileData)
        print(stri_stats_general(tData)) ## lines of data
        tData }
    ##tData <- readTextFile(dirData,"en_US",lstFileEN[1])

    
    ## read Token file
    readTokenFile <- function(tDir,tLanguage) {
        tDocName <- tLanguage
        fileRDS <-getFilename(tDir,tLanguage,tDocName,".token.rds")
        a <- readRDS(fileRDS)
        a }     

    ## read ngram file
    readNgramFile <- function(tDir,tLanguage,tExtension) {
        tDocName <- tLanguage
        fileRDS <-getFilename(tDir,tLanguage,"token",tExtension)
        a <- readRDS(fileRDS)
        a }   
    

## --------------------------------------------------------------------------
## PROCESSING FUNCTIONS FOR TEXT TO CORPUS
## --------------------------------------------------------------------------
    
    ## convert text to corpus in quanteda and sample x% of data
    preprocessText <- function(tData) {
        tSample <- 0.50  ## sample 20% of the data
        tData <- sample(tData,length(tData)*tSample,replace=FALSE)   
        tData <- gsub("<.*?>", "", tData) ## remove html style tags
        a <- iconv(tData,to="ASCII") ## from="UTF-8",
        a <- gsub("(https?)?://[^[:blank:]]*", " ",a) ## remove urls
        a <- gsub("[[:blank:]]#[^[:blank:]]*", " ",a) ## remove hashtags
        a <- gsub("[[:digit:]]","",a)
        a <- gsub("[[:punct:]]","",a)
        a <- gsub("^[:alphanum:][:space:]"," ",a)
        corpus(a) }
    

## --------------------------------------------------------------------------
## PROCESSING FUNCTIONS FOR CORPUS TO TOKENS
## -------------------------------------------------------------------------- 
    
    ## reads corpus, preprocessing and tokenising
    tokenText <- function(tDir,tLanguage,lstFile) {
        ## read text file and preprocess
        tDocName <- tLanguage
        a1 <- readTextFile(tDir,tLanguage,lstFile[1])
        a2 <- readTextFile(tDir,tLanguage,lstFile[2])
        a3 <- readTextFile(tDir,tLanguage,lstFile[3])
        a1 <- preprocessText(a1)
        a2 <- preprocessText(a2)
        a3 <- preprocessText(a3)
        x <- a1 + a2 + a3
        rm(a1,a2,a3)
        saveRDS(x,getFilename(tDir,tLanguage,tDocName,".corpus.rds"))
        ## make tokens
        x <-tokens(x,remove_punct=TRUE, remove_numbers=TRUE, 
            remove_symbols=TRUE, remove_twitter=FALSE, remove_hyphens=TRUE,
            include_docvars=FALSE, what = "word")
        ##x <-tokens(x,what="sentence", remove_numbers = TRUE,
        ##    remove_symbols=TRUE, remove_twitter=TRUE, remove_hyphens=TRUE) 
        x <-tokens(x,what="fasterword",remove_url=TRUE)
        x <-tokens_remove(x,lstProfanity)
        ## x <-tokens_remove(x,stopwords(substr(tLanguage,1,2)))
        saveRDS(x,getFilename(tDir,tLanguage,tDocName,".token.rds"))
        x }

## --------------------------------------------------------------------------
## PROCESSING FUNCTIONS FOR TOKENS TO NGRAMS
## -------------------------------------------------------------------------- 
    ## calculate n-grams from tokens
    getNgram <- function(x,n,nskip,tDir,tLanguage,tExtension) {
        xgram <- tokens_ngrams(x,n,nskip,concatenator=" ")
        saveRDS(xgram,getFilename(tDir,tLanguage,"token",tExtension)) 
        rm(xgram) }        
    
    
    ## convert tokens to ngrams, creates x.ngram file
    ngramToken <- function(tDir, tLanguage) {
        x <- readTokenFile(tDir,tLanguage)
        getNgram(x,n=1L,nskip=0L,tDir,tLanguage,".x1gram.rds")
        getNgram(x,n=2L,nskip=0L,tDir,tLanguage,".x2gram.rds")
        getNgram(x,n=3L,nskip=0L,tDir,tLanguage,".x3gram.rds")
        getNgram(x,n=4L,nskip=0L,tDir,tLanguage,".x4gram.rds")
        rm(x)
    }

            
## --------------------------------------------------------------------------
## PROCESSING FUNCTIONS FOR NGRAMS TO DFM
## -------------------------------------------------------------------------- 
    ## coverage by number of features - only works on dfm objects
    ngramCoverage <- function(xgram,n) {
        ## word cloud and top words
        ## textplot_wordcloud(xgram,max_words=60/n,color=brewer.pal(6,"Dark2"))
        print(topfeatures(xgram,n=25))
        ## word frequency table
        tblgram <- textstat_frequency(xgram)
        tblgram <- data.frame(tblgram, 
            cumfreq = cumsum(tblgram$frequency)/sum(tblgram$frequency),
            length=nchar(tblgram$feature))
        ## print(mean(tblgram$length))
        ## for x% coverage of text, cumfreq of features as abs and % of corpus
        tblgram2 <- data.frame(coverage = 1:10)
        tblgram2$coverage <- tblgram2$coverage/10
        cumfreq <- sapply(tblgram2$coverage, function(x)
            length(which(tblgram$cumfreq<=x)))
        cumfreqpct <- cumfreq/NROW(tblgram$freq)
        tblgram2 <- cbind(tblgram2,cumfreq,cumfreqpct)
        print(tblgram2) 
        ## ggplot(tblgram2,aes(cumfreqpct,coverage))+geom_line()
        ## count of features which appear x times in corpus
        tblgram3 <- data.frame(freqcount = 1:10)
        featcount <- sapply(tblgram3$freqcount, function(x)
            length(which(tblgram$freq==x)))
        featfreq <- cumsum(featcount)/NROW(tblgram$freq)
        tblgram3 <- cbind(tblgram3,featcount,featfreq)
        print(tblgram3)
        rm(tblgram, tblgram2,tblgram3) }
    
    
    ## calculate dfm from ngrams
    getdfm <- function(tDir,tLanguage,tExtension) {
        x <- readNgramFile(tDir,tLanguage,tExtension)
        ##xdfm <- dfm(x, stem=FALSE, tolower=TRUE, ngrams=n, skip=nskip)
        xdfm <- dfm(x)
        xdfm <- dfm_sort(xdfm,decreasing=TRUE,margin="features")
        saveRDS(xdfm,getFilename(tDir,tLanguage,"dfm",tExtension))
        ## ngramCoverage(xdfm,n)
        ## xdfm 
        rm(xdfm) }     

    
    ## convert ngrams to dfm, trim and create dfm file
    dfmNgram <- function(tDir, tLanguage) {
        getdfm(tDir,tLanguage,".x1gram.rds")
        getdfm(tDir,tLanguage,".x2gram.rds")
        getdfm(tDir,tLanguage,".x3gram.rds")
        getdfm(tDir,tLanguage,".x4gram.rds")}
    

## --------------------------------------------------------------------------
## PROCESSING FUNCTIONS FOR DFM TO DICTIONARY
## --------------------------------------------------------------------------  
    ## get frequency of n-gram
    freqNgram <- function(x,tbllookup) {
        tbllookup <- tbllookup[,c("feature","featfreq")]
        names(tbllookup) <- c("currword","currfreq")
        x <- merge(x,tbllookup,by="currword")   
        x <- x[order(x$rank),]
        rm(tbllookup)
        x$currfreq }    

    
    ## split n-grams, x is a dfm (trimmed)
    splitNgram <- function(x,n,tminfreq,tbllookup) {
        x <- dfm_trim(x,min_termfreq=tminfreq)
        x <- textstat_frequency(x); x$group <- NULL; x$docfreq <- NULL
        x$nextword<-sapply(x$feature,
            function(x)unlist(strsplit(x,split=" "))[n])
        if (n==1) { 
            x$currword = ""
            x$currfreq <- sum(x$frequency)
        } else {
            x$currword<-mapply(function(x,y) gsub(y,"",x),x$feature,
                               paste(" ",x$nextword,"$",sep=""))
            x$currfreq <- freqNgram(x,tbllookup)}  
        x$n <- n
        names(x) <- c("feature","featfreq","rank","nextword",
            "currword","currfreq","n")
        x <- x[,c("n","rank","feature","featfreq","currword","currfreq",
                  "nextword")]
        print(format(object.size(x), units = "Mb"))
        x }

    ## library(data.table)
    ## dt1 <- data.table(ngram=featnames(x1),count = colSums(x1),key="ngram")
    ## dt1 <- dt1[order(dt1$count,decreasing=TRUE),]    
    ## https://s3.amazonaws.com/assets.datacamp.com/blog_assets/datatable_Cheat_Sheet_R.pdf
        
    ## create dfm from dictionary and save output
    dictionarydfm <- function(tDir,tLanguage) {
        tDocName <- "dfm"
        ## x.1gram frequency ; ngramCoverage(x1,1)
        x1 <- readRDS(getFilename(tDir,tLanguage,tDocName,".x1gram.rds"))
        x1 <- splitNgram(x1,n=1,tminfreq,x1) ## tbllookup not used
        x1$probability <- x1$featfreq/x1$currfreq

                
        ## x.2gram frequency
        x2 <- readRDS(getFilename(tDir,tLanguage,tDocName,".x2gram.rds"))
        x2 <- splitNgram(x2,n=2,tminfreq,x1)
        x2$probability <- x2$featfreq/x2$currfreq
        
        ## x.3gram frequency
        x3 <- readRDS(getFilename(tDir,tLanguage,tDocName,".x3gram.rds"))
        x3 <- splitNgram(x3,n=3,tminfreq,x2)
        x3$probability <- x3$featfreq/x3$currfreq
        
        ## x.4gram frequency
        x4 <- readRDS(getFilename(tDir,tLanguage,tDocName,".x4gram.rds"))
        x4 <- splitNgram(x4,n=4,tminfreq,x3)
        x4$probability <- x4$featfreq/x4$currfreq
        
        xdictionary <- rbind(x2,x3,x4); rm(x2,x3,x4)
        xdictionary <- as.data.frame(xdictionary)
        xdictionary$rank <- NULL
 
        saveRDS(x1,getFilename(tDir,tLanguage,tLanguage,
                 ".vocabulary.rds")) ; rm(x1)       
        
        saveRDS(xdictionary,getFilename(tDir,tLanguage,tLanguage,
            ".dictionary.rds"))
        print(format(object.size(xdictionary), units = "Mb"))
        xdictionary }    
        
    
## --------------------------------------------------------------------------
## REAL CODE STARTS HERE
## --------------------------------------------------------------------------
## bad word list https://www.cs.cmu.edu/~biglou/resources/
    fileProfanity <- getFilename("data","","bad-words",".txt")
    lstProfanity <- scan(file=fileProfanity,sep ='\n',what='',skipNul=TRUE) 
    tminfreq <- 2
    ## tDir <- dirData ; tLanguage <- "en_US"
    
    ## tokenText : convert text to tokens; creates .corpus and .token file
    ## ngramToken : convert tokens to ngrams, creates x.ngram file
    ## dfmNgram : convert ngrams to dfm, create dfm file
    ## dictionarydfm : convert dfm to dictionary, create dictionary file
    
    ## de_DE
    ##system.time(tokenDE <- tokenText(dirData,"de_DE",lstFileDE))
    ##system.time(ngramDE <- ngramToken(dirData,"de_DE"))
    ##system.time(dfmDE <- dfmNgram(dirData,"de_DE"))
    ##system.time(dictionaryDE <- dictionarydfm(dirData,"de_DE")) 
    
    ## en_US
    ##system.time(tokenEN <- tokenText(dirData,"en_US",lstFileEN))
    ##system.time(ngramEN <- ngramToken(dirData,"en_US"))
    ##system.time(dfmEN <- dfmNgram(dirData,"en_US"))
    ##system.time(dictionaryEN <- dictionarydfm(dirData,"en_US")) 
    
    ## fi_FI
    ##system.time(tokenFI <- tokenText(dirData,"fi_FI",lstFileFI))
    ##system.time(ngramFI <- ngramToken(dirData,"fi_FI"))
    ##system.time(dfmFI <- dfmNgram(dirData,"fi_FI"))
    ##system.time(dictionaryFI <- dictionarydfm(dirData,"fi_FI")) 
    
    ## ru_RU
    ##system.time(tokenRU <- tokenText(dirData,"ru_RU",lstFileRU))   
    ##system.time(ngramRU <- ngramToken(dirData,"ru_RU"))
    ##system.time(dfmRU <- dfmNgram(dirData,"ru_RU")) 
    ##system.time(dictionaryRU <- dictionarydfm(dirData,"ru_RU")) 
    

    
    
## --------------------------------------------------------------------------
## UNUSED CODE
## --------------------------------------------------------------------------  
    
    
    ## build word hierarichal clusters from dfm, convert to tm format
    buildHCluster <- function(x) {
        x <- convert(x,to = "tm")
        x <- removeSparseTerms(x,sparse = 0.50)
        hc <- hclust(d=dist(x, method = "euclidean"),method="complete")
        plot(hc) }
    ## buildHCluster(dtmEN)
    
    ## build word associations - correlation matrix
    buildWordAssociation <- function(x,xword) {
        y <- findAssoc(x,xword,0.2) ## where 0.2 is correlation cutoff
        y }    
    
## read Corpus File
    readCorpusFile <- function(tDir,tLanguage,tDocName) {
        fileRDS <-getFilename(tDir,tLanguage,tDocName,".corpus.rds")
        a <- readRDS(fileRDS)
        print(fileRDS)
        print(stri_stats_general(fileRDS))     ## lines of data  
        a }      
    ## a <- readCorpusFile(dirData,"en_US",lstFileEN[1])   
    
## convert text to corpus and clean in tm
    preprocessCorpus <- function(tData, tLanguage) {
        tLang1<- substr(tLanguage,1,2)
        a <- VCorpus(VectorSource(tData),
                     readerControl=list(readPlain, language=tLanguage))
        removeSpecialChars <- function(x) gsub("[^a-zA-Z0-9 ]","",x)
        a <- tm_map(a,removeSpecialChars)
        a <- tm_map(a,tolower)
        a <- tm_map(a,removeWords,stopwords(tLang1))
        a <- tm_map(a,removeWords,lstProfanity)
        a <- tm_map(a,removePunctuation)
        a <- tm_map(a,removeNumbers)
        a <- tm_map(a,stripWhitespace)
        a <- tm_map(a,PlainTextDocument)
        a <- Corpus(VectorSource(a))
        a }
    ##a <- preprocessCorpus(tData,"en_US")   
    
    
## clean and convert corpus and save as rds file
    makeCorpusFile <- function(tDir,tLanguage,tDocName) {
        tSample <- 0.10  ## sample 10% of the data
        tData <- readTextFile(tDir,tLanguage,tDocName)
        tData <- sample(tData,length(tData)*tSample,replace=FALSE)
        
        ## preprocess
        a <- preprocessCorpus(tData, tLanguage)
        
        ## save file
        fileRDS <- getFilename(tDir,tLanguage,tDocName,".corpus.rds")
        print(fileRDS)
        saveRDS(a,fileRDS) }
    ## makeCorpusFile(dirData,"en_US",lstFileEN[1])
    
## read corpus file,  make document term matrix file using tm library
    makeDTMFiletm <- function(tDir,tLanguage,tDocName) {
        a <- readCorpusFile(tDir,tLanguage,tDocName)
        ## a <- tm_map(a, stemDocument, language = tLang2)
        ## a <- tm_map(a,PlainTextDocument)
        adtm <-DocumentTermMatrix(a) 
        ## inspect(adtm)
        
        ## convert to matrix
        adtm.matrix <- as.matrix(adtm)
        wordcount <- colSums(adtm.matrix)
        topten <- sort(wordcount, decreasing=TRUE)
        print(head(topten,50))
        
        ## save to file
        tDocName.rds <- paste(tDir,tDocName,".dtm.rds",sep="")  
        print(tDir)
        print(tDocName.rds)
        saveRDS(adtm,tDocName.rds)        
    }
    
    ##makeDTMFiletm(dirData,"en_US",lstFileEN[i])

    

    
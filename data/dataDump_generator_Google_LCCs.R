if (!require("crayon")) install.packages("crayon", repos='https://cran.rstudio.com')
if (!require("dplyr")) install.packages("dplyr", repos='https://cran.rstudio.com')
library(crayon)
library(dplyr)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop(red("\nIncorrect number of arguments.") %+% 
         "\nSyntax should be as follows: \n \t Rscript dataDump_generato_Google_LCCs.R " %+% 
         green$bold("pathToFiles") %+% 
         "\n If the file is in the current directory, enter \"\" as pathToFiles")
} else if(!is.na(args[1]) && !is.na(args[2])) {
  pathToFiles <- args[1]
  if(grepl("[^/]$",pathToFiles)) pathToFiles <- paste0(pathToFiles,"/") ## ensure correct format path
  fixed_or_mobile <- args[2]
} 

##FIXED BROADBAND
data_in <- read.csv(paste0(pathToFiles,"FixedBB_prices.csv"),header = TRUE)
data_in <- select(data_in,-X)
data_in <- distinct(data_in)## reomve duplicates
line <- "USE telecom;"
write.table(line,paste0(pathToFiles,"dataDump_fixedBB.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE)
line <- "INSERT INTO fixedbb_prices (CountryCode, `Year`, Price,Speed, Cap, Operator) VALUES"
write.table(line,paste0(pathToFiles,"dataDump_fixedBB.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE
            , append = TRUE)
line <- paste0("(",data_in$Country[1:dim(data_in)[1]-1],",",
               data_in$Year[1:dim(data_in)[1]-1],",",
               data_in$Price[1:dim(data_in)[1]-1],",",
               data_in$Speed[1:dim(data_in)[1]-1],",",
               "\"",data_in$Cap[1:dim(data_in)[1]-1],"\"",
               ",","\"",data_in$Operator[1:dim(data_in)[1]-1],"\"",")",",")

write.table(line,paste0(pathToFiles,"dataDump_fixedBB.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE, 
            append = TRUE)

line <- paste0("(",data_in$Country[dim(data_in)[1]],",",
               data_in$Year[dim(data_in)[1]],",",
               data_in$Price[dim(data_in)[1]],",",
               data_in$Speed[dim(data_in)[1]],",",
               "\"",data_in$Cap[dim(data_in)[1]],"\"",
               ",","\"",data_in$Operator[dim(data_in)[1]],"\"",")",";")

write.table(line,paste0(pathToFiles,"dataDump_fixedBB.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE, 
            append = TRUE)

##MOBILE BROADBAND
data_in <- read.csv(paste0(pathToFiles,"MobileBB_prices.csv"),header = TRUE)
data_in <- select(data_in,-X)
data_in <- distinct(data_in)## remove duplicates
line <- "USE telecom;"
write.table(line,paste0(pathToFiles,"dataDump_mobileBB.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE)
line <- 
  "INSERT INTO mobilebb_prices (CountryCode, `Year`, Price, Cap, Validity, Contract, Operator) VALUES"
write.table(line,paste0(pathToFiles,"dataDump_mobileBB.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE
            , append = TRUE)
line <- paste0("(",data_in$Country[1:dim(data_in)[1]-1],",",
               data_in$Year[1:dim(data_in)[1]-1],",",
               data_in$Price[1:dim(data_in)[1]-1],",",
               "\"",data_in$Cap[1:dim(data_in)[1]-1],"\"",",",
               "\"",data_in$Validity[1:dim(data_in)[1]-1],"\"",",",
               "\"",data_in$Contract[1:dim(data_in)[1]-1],"\"",",",
               "\"",data_in$Operator[1:dim(data_in)[1]-1],"\"",")",",")

write.table(line,paste0(pathToFiles,"dataDump_mobileBB.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE, 
            append = TRUE)

line <- paste0("(",data_in$Country[dim(data_in)[1]],",",
               data_in$Year[dim(data_in)[1]],",",
               data_in$Price[dim(data_in)[1]],",",
               "\"",data_in$Cap[dim(data_in)[1]],"\"",",",
               "\"",data_in$Validity[dim(data_in)[1]],"\"",",",
               "\"",data_in$Contract[dim(data_in)[1]],"\"",",",
               "\"",data_in$Operator[dim(data_in)[1]],"\"",")",";")

write.table(line,paste0(pathToFiles,"dataDump_mobileBB.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE, 
            append = TRUE)

##LCCs
data_in <- read.csv(paste0(pathToFiles,"LCC_list.csv"),header = TRUE)
data_in <- select(data_in,-X)

line <- "USE telecom;"
write.table(line,paste0(pathToFiles,"dataDump_LCC.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE)
line <- 
  "INSERT INTO LCCs (CountryCode, `Year`, LCC) VALUES"
write.table(line,paste0(pathToFiles,"dataDump_LCC.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE
            , append = TRUE)
line <- paste0("(",data_in$Country[1:dim(data_in)[1]-1],",",
               data_in$Year[1:dim(data_in)[1]-1],",",
               data_in$LCC[1:dim(data_in)[1]-1],")",",")

write.table(line,paste0(pathToFiles,"dataDump_LCC.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE, 
            append = TRUE)

line <- paste0("(",data_in$Country[dim(data_in)[1]],",",
               data_in$Year[dim(data_in)[1]],",",
               data_in$LCC[dim(data_in)[1]],")",";")

write.table(line,paste0(pathToFiles,"dataDump_LCC.sql"), quote= FALSE, row.names = FALSE, col.names = FALSE, 
            append = TRUE)

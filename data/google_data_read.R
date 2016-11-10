if (!require("crayon")) stop("Please install package \"crayon\" an reexecute the script.")
if (!require("dplyr")) stop("Please install package \"dplyr\" an reexecute the script.")



args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop(red("\nIncorrect number of arguments.") %+% 
         "\nSyntax should be as follows: \n \t Rscript Google_formatter.R " %+% 
         green$bold("pathToFiles") %+% 
          "\n If the file is in the current directory, enter \"\" as pathToFiles")
} else if(!is.na(args[1]) && !is.na(args[2])) {
  pathToFiles <- args[1]
  if(grepl("[^/]$",pathToFiles)) paste0(pathToFiles,"/") ## ensure correct format path
  fixed_or_mobile <- args[2]
} 


## FIXED BROADBAND PRICES
result <- data.frame(row.names = c("Country","Operator","Speed","Speed_units",
                                   "Cap", "Cap_units", "Price", "Currency", "Year"),
                     stringsAsFactors = FALSE)
##Load in data
  for(i in 2012:2015){
    google_data <- read.csv(paste0(pathToFiles, "Fixed_",i,".csv"),stringsAsFactors = FALSE, 
                            header = TRUE)
    output <- data.frame("Country" = google_data$Country,
                        "Operator" = google_data$ISP,
                        "Speed" = google_data$Downstream.bandwidth,
                        "Speed_units" = google_data$Downstream.units,
                        "Cap" = google_data$Usage.cap,
                        "Cap_units" = google_data$Cap.units,
                        "Price" = google_data$Monthly.cost..local.currency.,
                        "Currency" = google_data$Tariff.currency,
                        "Year" = i,
                        stringsAsFactors = FALSE)
  result  <- rbind(result,output)
}


##Tidy NA, remove plans priced by hour, as they cannot be compared with the rest
result$Cap_units[is.na(result$Cap_units)] <- ""
result <- filter(result,Cap_units != "Hours" & Cap_units != "hours")

##Adapt country names to ITU names, remove those territories not in ITU list
ITU_names <- read.csv(paste0(pathToFiles,"googleCountryNames.csv"))
result$Country <- ITU_names$Country_code[match(result$Country,ITU_names$Names_Google)]
result <- filter(result, Country != "")

##Normalize cap to MB, clean NAs '?' and 0, assume no cap = unlimited, correct misspellings
result <- filter(result,!is.na(Cap))
result <- filter(result,Cap != "?")
result <- filter(result,Cap != 0)
result$Cap[grepl("[Uu]nl*",result$Cap)] <- "Unlimited"
result$Cap[result$Cap == ""] <- "Unlimited"
result$Cap_units[result$Cap == "Unlimited"] <- ""

result$Cap[result$Cap_units == "GB"] <- as.numeric(result$Cap[result$Cap_units == "GB"]) * 
  1024 
result$Cap[result$Cap_units == "TB"] <- as.numeric(result$Cap[result$Cap_units == "TB"]) * 
  1024 * 1024 

##Normalize speed to Mbit/s, clean NAs, blanks
result <- filter(result,!is.na(Speed))
result <- filter(result,Speed != "")

result$Speed[grepl("*[Kk]bps*",result$Speed_units)] <- 
  as.numeric(result$Speed[grepl("*[Kk]bps*",result$Speed_units)]) / 1024

result$Speed[grepl("*[Gg]bps*",result$Speed_units)] <- 
  as.numeric(result$Speed[grepl("*[Gg]bps*",result$Speed_units)]) * 1024

##Price into local currency
result$Currency <- trimws(result$Currency) ## remove whitespaces from curr code
ex_rates <- read.csv(paste0(pathToFiles,"Unique_Currency.csv"))
result$Price <- gsub(",","", result$Price) ## delete "," sometimes inserted for thousands
#ex rate conversion per year
for(i in 1:4){
  year <- 2011+i
  result$Price[result$Year == year] <- as.numeric(result$Price[result$Year == year]) /
    as.numeric(ex_rates[,i+1][match(result$Currency[result$Year == year],ex_rates$X)])
}
result <- filter(result,!is.na(Price)) ## delete prices for unknown currencies

# select fields to export into .csv & write
result_export <- select(result, Country, Year, Price, Speed, Cap, Operator)
write.csv(result_export,file = paste0(pathToFiles,"/FixedBB_prices.csv"))

## MOBILE BROADBAND PRICES
result <- data.frame(row.names = c("Country","Operator","Contract","Cap", 
                                   "Cap_units", "Validity", "Price_post", 
                                   "Price_pre","Price","Currency", "Year"),
                     stringsAsFactors = FALSE)
##Load in data
for(i in 2012:2015){
  google_data <- read.csv(paste0(pathToFiles, "Mobile_",i,".csv"),stringsAsFactors = FALSE, 
                          header = TRUE)
  output <- data.frame("Country" = google_data$Country,
                       "Operator" = google_data$ISP,
                       "Contract" = google_data$Pre.or.Post.paid,
                       "Cap" = google_data$Usage.allowance,
                       "Cap_units" = google_data$Allowance.units,
                       "Validity" = google_data$Validity..days.,
                       "Price_post" = google_data$Monthly.cost..specified.currency.,
                       "Price_pre" = google_data$Pack.Cost..specified.currency.,
                       "Price" = "",
                       "Currency" = google_data$Tariff.currency,
                       "Year" = i,
                       stringsAsFactors = FALSE)
  result  <- rbind(result,output)
}


##Tidy NA, remove plans priced by hour/day, as they cannot be compared with the rest
result$Cap_units[is.na(result$Cap_units)] <- ""
result$Price_pre[is.na(result$Price_pre)] <- ""
result$Price_pre[result$Price_pre == "#N/A"] <- ""
result$Price_post[is.na(result$Price_post)] <- ""
result$Price_post[result$Price_post == "#N/A"] <- ""

result <- filter(result,Cap_units != "hours" & Cap_units != "hour" & 
                   Cap_units != "day" & Cap_units != "days")

##Adapt country names to ITU names, remove those territories not in ITU list
ITU_names <- read.csv(paste0(pathToFiles,"googleCountryNames.csv"))
result$Country <- ITU_names$Country_code[match(result$Country,ITU_names$Names_Google)]
result <- filter(result, Country != "")

##Price into local currency
ex_rates <- read.csv(paste0(pathToFiles,"Unique_Currency.csv"))
result$Price_pre <- gsub(",","", result$Price_pre) ## delete "," used 1000s
result$Price_post <- gsub(",","", result$Price_post) ## delete "," used 1000s
# combine post and prepaid prices into a single column
result$Price[result$Price_post!=""] <- result$Price_post[result$Price_post!=""]
result$Price[result$Price_pre!=""] <- result$Price_pre[result$Price_pre!=""]
result <- filter(result, Price != "")

#ex rate conversion per year
result$Currency <- trimws(result$Currency) ## remove whitespaces from curr code
result <- result[!is.na(match(result$Currency,ex_rates$X)),] ## clean unknown currencies

for(i in 1:4){
  year <- 2011+i
  result$Price[result$Year == year] <- as.numeric(result$Price[result$Year == year]) /
    as.numeric(ex_rates[,i+1][match(result$Currency[result$Year == year],ex_rates$X)])
}


##Normalize cap to MB, clean NAs '?' and 0, assume no cap = unlimited, correct misspellings
result <- filter(result,Cap != "?")
result$Cap[grepl("[Uu]nl*",result$Cap)] <- "Unlimited"
result$Cap[result$Cap == ""] <- "Unlimited"
result$Cap_units[result$Cap == "Unlimited"] <- ""

result$Cap[result$Cap_units == "GB"] <- as.numeric(result$Cap[result$Cap_units == "GB"]) * 
  1024 
result$Cap[result$Cap_units == "TB"] <- as.numeric(result$Cap[result$Cap_units == "TB"]) * 
  1024 * 1024 



##Validity cleaning
result$Validity[result$Validity == "N/A"] <- 30 ## if not specified, supposing monthly plan
result$Validity[is.na(result$Validity)] <- 30 ## idem
result$Validity[result$Validity == ""] <- 30 ## idem
result$Validity[result$Validity == "?"] <- 30 ## idem
result$Validity[result$Validity == "Per usage charge"] <- 30 ## idem

##Contract cleaning
result$Contract <- sub("\\s+$","",result$Contract) #remove trailing spaces
result$Contract <- sub("post+$","Post",result$Contract)

# select fields to export into .csv & write
result_export <- select(result, Country, Year, Price, Cap, Validity, Contract, Operator)
write.csv(result_export,file = paste0(pathToFiles,"/MobileBB_prices.csv"))
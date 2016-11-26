#load libraries
library(RMySQL)
if (!require("dplyr")) install.packages("dplyr", repos='https://cran.rstudio.com')
if (!require("gridExtra")) install.packages("gridExtra", repos='https://cran.rstudio.com')
if (!require("grid")) install.packages("grid", repos='https://cran.rstudio.com')
if (!require("gtable")) install.packages("gtable", repos='https://cran.rstudio.com')
library(grid)
library(dplyr)
library(gtable)
library(gridExtra)

#set wd
setwd("~/BGSE_Classes/Computing_lab/Project")

#Connection to SQL
db <- dbConnect(MySQL(), user='root', password='root' , dbname='telecom', host='localhost')

#retrieve wb_data for countries with unknown LCC status
result <- dbSendQuery(db, "SELECT 	a.IndicatorCode,
                      a.CountryCode,
                      a.IndicatorYear,
                      a. IndicatorValue
                      FROM wb_data a,
                      LCCs b
                      WHERE a.CountryCode = b.CountryCode AND a.IndicatorYear=2014 
                      AND b.`Year`=2014 AND b.LCC IS NULL")
wb_data <- fetch(result,n=-1)

#retrieve google_data for countries with unknown LCC status
result <- dbSendQuery(db, "SELECT 	a.CountryCode,
                      a.IndicatorYear,
                      a. IndicatorValue
                      FROM fixedbb_summary a,
                      LCCs b
                      WHERE a.CountryCode = b.CountryCode AND a.IndicatorYear=2014 
                      AND b.`Year`=2014 AND b.LCC IS NULL")
fixedbb_data <- fetch(result,n=-1)

result <- dbSendQuery(db, "SELECT 	a.CountryCode,
                      a.IndicatorYear,
                      a. IndicatorValue
                      FROM fixedbb_summary a,
                      LCCs b
                      WHERE a.CountryCode = b.CountryCode AND a.IndicatorYear=2014 
                      AND b.`Year`=2014 AND b.LCC IS NULL")
mobilebb_data <- fetch(result,n=-1)

#retrieve ITU data for countries with unknown LCC status
result <- dbSendQuery(db, "SELECT 	a.CountryCode,
                      a.IndicatorCode,
                      c.Description,
                      a. IndicatorValue
                      FROM itu_data a,
                      LCCs b,
                      itu_indicators c
                      WHERE a.CountryCode = b.CountryCode AND a.IndicatorCode = c.IndicatorCode
                      AND a.IndicatorYear=2014 AND b.`Year`=2014 AND b.LCC IS NULL")
ITU_data <- fetch(result,n=-1)

#retrieve indicator names
result <- dbSendQuery(db, "SELECT 	*
                      FROM wb_indicators")
indics_names <- fetch(result,n=-1)
indics_names <- rbind(indics_names,c("FBP","Fixed broadband prices"), 
      c("MBP","Mobile broadband prices"),
      c(ITU_data[ITU_data$Description==distinct(ITU_data,Description)[1,1],2][1], 
        distinct(ITU_data,Description)[1,1]),
      c(ITU_data[ITU_data$Description==distinct(ITU_data,Description)[2,1],2][1], 
        distinct(ITU_data,Description)[2,1]),
      c(ITU_data[ITU_data$Description==distinct(ITU_data,Description)[3,1],2][1], 
        distinct(ITU_data,Description)[3,1]))
      
#retrieve country names
result <- dbSendQuery(db, "SELECT 	*
                      FROM countries")
country_names <- fetch(result,n=-1)


#num indicators and countries
N <- dim(distinct(wb_data, IndicatorCode))[1]
C <- dim(distinct(country, CountryCode))[1]

#indicator codes
countries <- distinct(wb_data,CountryCode)
availability <- matrix(0,nrow=N,ncol=C)

#create table with availability each indicator
for(i in 1:N){
  availability[i,match(filter(wb_data, IndicatorCode == indics_names[i,1] & 
                              !is.na(IndicatorValue))$CountryCode,countries[,1])] <- 1
}

#add availability of google's two indicators
tmp_row <- matrix(0,nrow=1,ncol=C)
tmp_row[match(fixedbb_data$CountryCode,countries[,1])] <- 1
availability <- rbind(availability,tmp_row)
tmp_row <- matrix(0,nrow=1,ncol=C)
tmp_row[match(mobilebb_data$CountryCode,countries[,1])] <- 1
availability <- rbind(availability,tmp_row)

#add availability ITU indicators
for(i in 1:(dim(itu_indics)[1])){
  tmp_row <- matrix(0,nrow=1,ncol=C)
  tmp_row[match(filter(ITU_data, IndicatorCode == indics_names[56+i,1] & 
                                !is.na(IndicatorValue))$CountryCode,countries[,1])] <- 1
  availability <- rbind(availability,tmp_row)
}


#see effect of including indicators on #LCCs with complete data 
N <- dim(availability)[1]
ordered_indics <- matrix(0,nrow=N,ncol=3)
cond_availability <- availability

#take the indicator with most data available given previous choices
#write indicator, countries with data for it and list countries excl. (formatted)
for(i in 1:N){
        max_row <- which.max(rowSums(cond_availability))
        ordered_indics[i,1] <- max_row 
        ordered_indics[i,2] <- sum(cond_availability[max_row,])
        ordered_indics[i,3] <- paste(country_names$Country[match(countries[cond_availability[max_row,]==0,1],
                                     country_names$CountryCode)],collapse = ", ")
        cond_availability[,as.logical(!cond_availability[max_row,])] <- 0
        cond_availability[max_row,] <- 0
        if(ordered_indics[i,2]==0){
          ordered_indics <- ordered_indics[-i:-N,]
          break
        }
}

#format indicators for output table
ordered_indics[,1] <- indics_names$Description[
  match(indics_names[ordered_indics[,1],1],indics_names$IndicatorCode)]
ordered_indics[-1,1] <- paste("+ ", ordered_indics[-1,1])
ordered_indics[,1] <- sapply(strwrap(ordered_indics[,1], 30, simplify = FALSE), 
                             paste, collapse="\n")
ordered_indics[,3] <- sapply(strwrap(ordered_indics[,3],40, simplify = FALSE),
                             paste, collapse="\n")


output_table = data.frame("Indicators"= ordered_indics[,1],
                          "Data_available"= ordered_indics[,2],
                          "Countries excl."= ordered_indics[,3])
#Output table
g1 <- tableGrob(output_table[1:5,], 
           theme=ttheme_default(base_size = 8, 
           core=list(bg_params = list(fill="darkolivegreen1"))),
           cols = c("Indicators inc.","Data available \n(out of 44 countries)",
                    "Countries excl."))
title <- textGrob("Choice of indicators for the classification algorithm",gp=gpar(fontsize=14))
padding <- unit(2,"cm")
g1_title <- gtable_add_rows(g1,heights = grobHeight(title) + padding,pos = 0)
g1_title <- gtable_add_grob(g1_title, title, 1, 1, 1, ncol(g1_title))

#g1$widths <- unit(c(0.25,0.2,0.4), "npc")
g2 <- tableGrob(output_table[6:9,], 
               theme=ttheme_default(base_size = 8, equal.width=TRUE,
               core=list(bg_params = list(fill="darkolivegreen1"))), 
               cols = c("Indicators inc.","Data available \n(out of 44 countries)",
                        "Countries excl."))
#g2$widths <- unit(c(0.25,0.2,0.4), "npc")
g3 <- tableGrob(output_table[10:13,], 
                theme=ttheme_default(base_size = 8, equal.width=TRUE,
                core=list(bg_params = list(fill=c("darkolivegreen1", "darkolivegreen1", "darkolivegreen1", "grey90"))), 
                cols = c("Indicators inc.","Data available \n(out of 44 countries)",
                         "Countries excl.")))
#g3$widths <- unit(c(0.25,0.2,0.4), "npc")

g4 <- tableGrob(output_table[14:16,], 
                theme=ttheme_default(base_size = 8, equal.width=TRUE), 
                cols = c("Indicators inc.","Data available \n(out of 44 countries)",
                         "Countries excl."))
g5 <- tableGrob(output_table[17:20,], 
                theme=ttheme_default(base_size = 8, equal.width=TRUE), 
                cols = c("Indicators inc.","Data available \n(out of 44 countries)",
                         "Countries excl."))

pdf("Choice_variables.pdf", title = "Choice of indicators for the classification algorithm")
grid.arrange(g1_title)
grid.arrange(g2, newpage = TRUE)
grid.arrange(g3, newpage = TRUE)
grid.arrange(g4, newpage = TRUE)
grid.arrange(g5, newpage = TRUE)
dev.off()
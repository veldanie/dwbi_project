#load libraries
library(RMySQL)
if (!require("dplyr")) install.packages("dplyr", repos='https://cran.rstudio.com')
if (!require("gridExtra")) install.packages("gridExtra", repos='https://cran.rstudio.com')
if (!require("grid")) install.packages("grid", repos='https://cran.rstudio.com')
if (!require("gtable")) install.packages("gtable", repos='https://cran.rstudio.com')
if (!require("tidyr")) install.packages("tidyr", repos='https://cran.rstudio.com')
if (!require("ggplot2")) install.packages("ggplot2", repos='https://cran.rstudio.com')
if (!require("knitr")) install.packages("knitr", repos='https://cran.rstudio.com')
library(knitr);
library(ggplot2)
library(tidyr)
library(grid)
library(dplyr)
library(gtable)
library(gridExtra)

#set wd
setwd("~/BGSE_Classes/Computing_lab/Project")

#######################
# 1 VARIABLE SELECTION#
#######################
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
C <- dim(distinct(wb_data, CountryCode))[1]

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
for(i in 1:3){
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
selected_indics <- ordered_indics[,1]
formatted_indics <- ordered_indics
formatted_indics[,1] <- indics_names$Description[
  match(indics_names[formatted_indics[,1],1],indics_names$IndicatorCode)]
formatted_indics[-1,1] <- paste("+ ", formatted_indics[-1,1])
formatted_indics[,1] <- sapply(strwrap(formatted_indics[,1], 30, simplify = FALSE), 
                             paste, collapse="\n")
formatted_indics[,3] <- sapply(strwrap(formatted_indics[,3],40, simplify = FALSE),
                             paste, collapse="\n")

output_table = data.frame("Indicators"= formatted_indics[,1],
                          "Data_available"= formatted_indics[,2],
                          "Countries excl."= formatted_indics[,3], stringsAsFactors = FALSE)

#Output summary table idnicator choice
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

pdf("Choice_variables_test.pdf", title = "Choice of indicators for the classification algorithm")
grid.arrange(g1_title)
grid.arrange(g2, newpage = TRUE)
grid.arrange(g3, newpage = TRUE)
grid.arrange(g4, newpage = TRUE)
grid.arrange(g5, newpage = TRUE)
dev.off()

#set selected indicators
selected_indics <- indics_names$IndicatorCode[as.integer(selected_indics[1:12])]

####################
# 2 CLASSIFICATION #
####################

# 2.0 Functions to standardize inputs according to 1st quantile of first year passed
training_std <- function(data) {
  
  n_vars <- dim(data)[2]
  y_range <- arrange(distinct(data,IndicatorYear),IndicatorYear)
  n_years <- dim(y_range)[1]
  q[1,] <<- mapply(quantile,data[data$IndicatorYear==y_range[1,1],][,-1:-3],
                  probs=0.25, names=FALSE)
  for(i in 1:(n_years-1)){
  q[1+i,] <<- mapply(quantile,data[data$IndicatorYear==y_range[1+i,1],][,-1:-3],
                    probs=0.25, names=FALSE)
  q[1+i,] <<- q[1,] / q[1+i,]
  n_year <- dim(data[data$IndicatorYear==y_range[1+i,1],])[1]
  data[data$IndicatorYear==y_range[1+i,1],][,-1:-3] <-
    data[data$IndicatorYear==y_range[1+i,1],][,-1:-3] * 
    t(t(matrix(1L,nrow=n_year,ncol=n_vars-3)) * q[1+i,]) 
  }
  return(data)
}
predicting_std <- function(data,year,year_range){
  n_vars <- dim(data)[2]
  n_year <- dim(data)[1]
  i <- match(year,year_range)
  data <- data * t(t(matrix(1L,nrow=n_year,ncol=n_vars)) * q[i,]) 
  
  return(data)
}
## function for the roc-curves, taken from our visiting professor Kosmidis
roc <- function(fit, truth, thresholds,
                plot = FALSE, add = FALSE, col = "black") {
  truepos <- sapply(thresholds, function(pthres) {
    sum((fit > pthres) & (truth == 1))/sum(truth == 1)})
  falsepos <- sapply(thresholds, function(pthres) {
    sum((fit > pthres) & (truth == 0))/sum(truth == 0)})
  correctclass <- sapply(thresholds, function(pthres) {
    (sum((fit > pthres) & (truth == 0)) +
       sum((fit > pthres) & (truth == 1)))/length(fit)})
  if (plot) {
    if (add) points(falsepos, truepos, type = "l", col = col)
    else {
      plot(falsepos, truepos, type = "l", col = col)
      abline(0, 1) }
  }
  invisible(data.frame(thresholds, truepos = truepos,
                       falsepos = falsepos,
                       correctclass = correctclass))
}

# 2.1 format prediction Xs
#take wb_data for countries to be predicted
x_predicted <- filter(wb_data, IndicatorCode %in% selected_indics & !is.na(IndicatorValue))[,-3]
#add ITU data
x_predicted <- rbind(x_predicted, select(filter(ITU_data,IndicatorCode %in% selected_indics & !is.na(IndicatorValue)),
       IndicatorCode, CountryCode, IndicatorValue))
#format
x_predicted <- spread(x_predicted, IndicatorCode, IndicatorValue)
x_predicted <- x_predicted[complete.cases(x_predicted),]
countries_predicted <- x_predicted$CountryCode
x_predicted <- x_predicted[,-1]

# 2.2 fetch and format training values for the 6 years with data on LCCs
year_range <- c(2008,2010:2014)
result <- dbSendQuery(db, paste0("SELECT 	a.IndicatorCode,
                      a.CountryCode,
                      a.IndicatorYear,
                      a. IndicatorValue,
                      b.LCC
                      FROM wb_data a,
                      LCCs b
                      WHERE a.CountryCode = b.CountryCode AND a.IndicatorYear = b.`Year` AND
                      a.IndicatorYear in (",paste0("'",year_range,"'", collapse=","), 
                      ") AND b.LCC IS NOT NULL AND
                      a.IndicatorCode in (",paste0("'",selected_indics,"'", collapse=","),")"))
all_wb_data <- fetch(result,n=-1)

result <- dbSendQuery(db, paste0("SELECT 	a.IndicatorCode,
                      a.CountryCode,
                      a.IndicatorYear,
                      a. IndicatorValue,
                      b.LCC
                      FROM itu_data a,
                      LCCs b
                      WHERE a.CountryCode = b.CountryCode AND a.IndicatorYear = b.`Year` AND
                      a.IndicatorYear in (",paste0("'",year_range,"'", collapse=","), 
                                 ") AND b.LCC IS NOT NULL AND
                      a.IndicatorCode in (",paste0("'",selected_indics,"'", collapse=","),")"))
all_ITU_data <- fetch(result,n=-1)

x_training <- rbind(all_wb_data,all_ITU_data) 
x_training <- spread(x_training, IndicatorCode, IndicatorValue)
x_training <- x_training[complete.cases(x_training),]

#standardize inputs based on quantile across years (ref = 2008)
q <- matrix(0,nrow=length(year_range),ncol=dim(x_predicted)[2])
x_training <- training_std(x_training)
x_training <- x_training[,-1:-2]
x_predicted <- predicting_std(x_predicted,"2014",year_range)

# 2.3 GLM regression: training and fit
formula_training <- formula(paste("LCC ~",
                         paste0(names(x_training)[-1], collapse = " + ")))
glm_fit <- glm(formula_training,data=x_training,family = binomial)
glm_predict <- predict(glm_fit, x_predicted, type = "response", se.fit = TRUE)


# 2.4 write results classification into the database
line <-paste0("(",countries_predicted,",2014,",as.logical(round(glm_predict)), ",TRUE),", collapse = " ")
line <- gsub(".$", " ",line)
resultquey <- dbSendQuery(db, 
                          paste0("INSERT INTO LCCs_completed (CountryCode, `Year`, LCC, estimate) VALUES ",
                                 line, "ON DUPLICATE KEY UPDATE LCC=VALUES(LCC), estimate=VALUES(estimate);"))
dbDisconnect(db)

# 2.5 Some output summary tables and charts
plot1 <- ggplot(output_table,aes(x=1:length(output_table$Data_available), y=as.integer(Data_available)))+
  geom_bar(stat="Identity", fill=c(rep("darkgreen",12),rep("grey",23)))+
  labs(x="# Indicators included",y="Countries to be classified with data available")


c1 <- sapply(strwrap(formatted_indics[,1], 50, simplify = FALSE), 
             paste, collapse="\n")
c1 <- paste0(c1[1:12],collapse = "\n\n") 
c1 <- gsub("+", "",c1,fixed=TRUE)
c2 <- paste0(country_names$Country[match(countries_predicted,country_names$CountryCode)],
             collapse="\n")
#c2 <- sapply(strwrap(c2,10,simplify = FALSE),paste,collapse="\n")
c3 <- paste0(strsplit(ordered_indics[,3][12],",")[[1]],collapse = "\n")

output_table2 = data.frame("c1"= c1, "c2"=c2, "c3"=c3, stringsAsFactors = FALSE)

gt <- tableGrob(output_table2, 
                theme=ttheme_default(base_size = 8, 
                                     core=list(bg_params = list(fill="darkolivegreen1"))),
                cols = c("Indicators inc.","Countries included",
                         "Countries excluded (lack of data)"), rows=NULL)

pdf("Choice_variables_summary.pdf", title = "Choice of indicators for the classification algorithm")
grid.arrange(gt)
grid.arrange(plot1, newpage=TRUE)
dev.off()

mean_values <- as.vector(rowSums(x_training[,-1]*t(t(matrix(1L,nrow=dim(x_training)[1],ncol=12)) * 
                                      glm_fit$coefficients[-1]) + glm_fit$coefficients[1]))


plot_values <- data.frame("avg"=mean_values, "fitted"=glm_fit$fitted.values, 
                          "true"=x_training[,1])
pdf("Classification_fit.pdf")
ggplot(plot_values,aes(avg,fitted))+geom_jitter(height = 0.1, size=0.5)+
  labs(title="Classification: training dataset", x=expression("W " ~ phi * "(x)"), y="Fitted values")
dev.off()
pdf("Classification_fit_zoom.pdf")
ggplot(plot_values,aes(avg,fitted))+geom_jitter(height = 0.1, size=0.5)+xlim(165,185)+
  labs(title="Classification: training dataset (zoom)", x=expression("W " ~ phi * "(x)"), y="Fitted values")+
  stat_smooth(method = "glm",method.args = list(family = "binomial"),se=FALSE,size=0.5,
              col ="red", fullrange = TRUE)
dev.off()

tmp <- anova(glm_fit, test = "LRT")
row.names(tmp)[-1] <- indics_names$Description[match(row.names(tmp)[-1],indics_names$IndicatorCode)]

#Roc curve
roc_curve <- roc(plot_values$fitted, plot_values$true,
            seq(0, 1, length = 100), col = "blue")

pdf("ROC_curve.pdf")
ggplot(roc_curve,aes(x = falsepos, y = truepos)) + geom_line(col="blue")+
  geom_abline(aes(intercept = 0, slope = 1),col="red") +labs(title="ROC curve classification", x = "False positive", y = "True positive") +
  theme_bw()+xlim(0,1)+ylim(0,1)
dev.off()

# How sure we are of our prediction

avg_predicted <- as.vector(rowSums(x_predicted[,]*t(t(matrix(1L,nrow=dim(x_predicted)[1],ncol=12)) * 
                                                   glm_fit$coefficients[-1]) + glm_fit$coefficients[1]))
upper_predicted <- glm_predict$fit+1.96*glm_predict$se.fit 
lower_predicted <- glm_predict$fit-1.96*glm_predict$se.fit
plot_values2 <- data.frame("avg"=avg_predicted, "fitted"=glm_predict$fit,
                           "upper"=upper_predicted,"lower"=lower_predicted)
rownames(plot_values2) <- country_names$Country[match(countries_predicted,country_names$CountryCode)]
rownames(plot_values2)[14] <- "S.Tome"
rownames(plot_values2)[19] <- "Timor"
rownames(plot_values2)[17] <- "  Swaziland"
rownames(plot_values2)[18] <- "  Tajikistan"
rownames(plot_values2)[6] <- "   Haiti"
rownames(plot_values2)[9] <- "New Cal"
pdf("Classification_prediction.pdf")
ggplot(plot_values,aes(avg,fitted))+geom_jitter(height = 0.1, size=0.5)+
  labs(title="Classification: prediction dataset", x=expression("W " ~ phi * "(x)"), y="Fitted values")+
  geom_point(data=plot_values2, aes(x=plot_values2$avg,y=plot_values2$fitted),col="red")+
  xlim(120,190)+
  geom_text(data=plot_values2,aes(label=rownames(plot_values2)),
            nudge_y=-0.1, size=3,hjust="left",vjust="bottom",check_overlap = TRUE)
dev.off()

pdf("Classification_zoom.pdf")
ggplot(plot_values,aes(avg,fitted))+geom_jitter(height = 0.1, size=0.5)+
  labs(title="Classification: prediction dataset", x=expression("W " ~ phi * "(x)"), y="Fitted values")+
  geom_point(data=plot_values2, aes(x=plot_values2$avg,y=plot_values2$fitted),col="red")+
  geom_errorbar(data=plot_values2, aes(x=plot_values2$avg,ymax=plot_values2$upper,ymin=plot_values2$lower),col="darkgreen", width=0.2)+
  xlim(170,180)+
  geom_text(data=plot_values2,aes(label=rownames(plot_values2)),
            nudge_y=-0.1, size=3,hjust="left",vjust="bottom")+
  geom_hline(yintercept = 0.5,col="darkred",linetype="dashed", size=0.5)
dev.off()

ggplot(plot_values2, aes(avg,fitted))+ geom_point()
ggplot(plot_values,aes(avg,fitted))+geom_jitter(height = 0.1, size=0.5)+xlim(165,185)+
  labs(title="Classification: training dataset (zoom)", x=expression("W " ~ phi * "(x)"), y="Fitted values")+
  stat_smooth(method = "glm",method.args = list(family = "binomial"),se=FALSE,size=0.5,
              col ="lightblue", fullrange = TRUE)

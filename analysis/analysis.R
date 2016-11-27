
##1. Packages:
library(RMySQL);library(tidyr);library(dplyr);library(ggplot2);library(gridExtra);library(lars); library(mombf)

## 2. AUXILIARY FUNCTIONS
### Data standarization. We use mean and sd from each year.
data_standardized <- function(data){
  data_std <- data; data_mean_matrix<- data_sd_matrix<- NULL
  years <- sort(unique(data$IndicatorYear))
  for(year in years){
    data_year <- filter(data[,-1],IndicatorYear==year)
    data_mean <- apply(data_year, 2,mean)[-1]
    data_sd <- apply(data_year, 2,sd)[-1]
    if(length(data_sd)>1){
      data_std[data_std$IndicatorYear==year,-c(1,2)] <- as.matrix(data_year[,-1]-rep(1,dim(data_year)[1])%*%t(data_mean))%*%diag(1/data_sd)
    }else{
      data_std[data_std$IndicatorYear==year,-c(1,2)] <- (data_year[,-1]-data_mean)/data_sd
    }
    data_mean_matrix <- rbind(data_mean_matrix,data_mean, deparse.level = 0)
    data_sd_matrix <- rbind(data_sd_matrix, data_sd, deparse.level = 0)
  }
  return(list(data_std=data_std, data_mean=data.frame(IndicatorYear=years, data_mean_matrix), data_sd=data.frame(IndicatorYear=years, data_sd_matrix)))
}

lasso_reg <- function (x, y, mean_y, sd_y, year_predict = NULL, tol=0){
  #x and y are assumed to show countryCode and year in the first two columns.
  if(is.null(year_predict)) year_predict <- max(y$IndicatorYear) 
  model <- lars(x = as.matrix(x[,-c(1,2)]), y = y[,-c(1,2)], type = c('lasso'), normalize = FALSE)
  model_coef <- tail(coef(model),1)
  x_predict <- filter(x, IndicatorYear==year_predict)
  lasso_predict <- predict.lars(model, x_predict[,-c(1,2)], type =c('fit'), mode = 'norm')$fit
  diml <- dim(lasso_predict)
  
  y_predict <- data.frame(filter(y, IndicatorYear==year_predict), IndicatorPred = lasso_predict[,diml[2]])
  mean_pred <- as.numeric(filter(mean_y, IndicatorYear == year_predict)[-1])
  sd_pred <- as.numeric(filter(sd_y, IndicatorYear == year_predict)[-1])
  
  ind_var_sel <- abs(model_coef)>tol
  y_predict <- mutate(y_predict, IndicatorValueUnits = IndicatorValue*sd_pred+mean_pred,  IndicatorPredUnits = IndicatorPred*sd_pred+mean_pred)
  var_selected = data.frame(Variable = colnames(model_coef)[ind_var_sel],Coefficient =model_coef[ind_var_sel])
  return(list(y_predict = y_predict, var_selected = var_selected))  
}

bayesian_reg <- function (x, y, mean_y, sd_y, maxvars = 6, year_predict = NULL){
  #x and y are assumed to show countryCode and year in the first two columns.
  model <- modelSelection(y = y[,-c(1,2)], x = as.matrix(x[,-c(1,2)]), center = TRUE, scale = TRUE, enumerate = TRUE, maxvars = maxvars)
  model_coeff <- model$coef
  var_selected <- names(model$postMode)[model$postMode==1]
  if(is.null(year_predict)) year_predict <- max(y$IndicatorYear) 
  x_predict <- filter(x, IndicatorYear==year_predict)
  y_obs <- filter(y, IndicatorYear==year_predict)
  as.matrix(x_predict[,-c(1,2)])%*%model_coeff
  y_predict <- data.frame(filter(y, IndicatorYear==year_predict), IndicatorPred = as.matrix(x_predict[,-c(1,2)])%*%model_coeff)
  mean_pred <- as.numeric(filter(mean_y, IndicatorYear == year_predict)[-1])
  sd_pred <- as.numeric(filter(sd_y, IndicatorYear == year_predict)[-1])
  y_predict <- mutate(y_predict, IndicatorValueUnits = IndicatorValue*sd_pred+mean_pred,  IndicatorPredUnits = IndicatorPred*sd_pred+mean_pred)
  var_selected = data.frame(Variable = var_selected, Coefficient = model$coef[model$postMode==1])
  return(list(y_predict = y_predict, var_selected = var_selected, year_predict=year_predict))  
}

## 3. DB CONNECTION
db <- dbConnect(MySQL(), user='root', password='root' , dbname='telecom', host='localhost')
#dbDisconnect(db)

########################################################################################################################
## 4. VARIABLE SELECTION
### Variable ranking based on data
wb_var_query <- dbSendQuery(db, "select IndicatorCode from variables_ranking;")
wb_ind <- fetch(wb_var_query, n=-1)
initial_wb_var <- wb_ind$IndicatorCode

# Indicators
ind_wb_query <- dbSendQuery(db, paste0("select * from wb_indicators where IndicatorCode in ","(",paste0("'",initial_wb_var,"'", collapse = ","),");"))
ind_wb_db <- fetch(ind_wb_query, n=-1)

# DB World Bank
data_wb_query <- dbSendQuery(db, paste0("select * from wb_data where IndicatorCode in ","(",paste0("'",initial_wb_var,"'", collapse = ","),");"))
wb_db <- fetch(data_wb_query, n=-1)

wb_data_matrix <- spread(wb_db, IndicatorCode, IndicatorValue)[,-c(1,2)]
corr_matrix <-cor(wb_data_matrix, use  = "pairwise.complete.obs")
#wb_cluster <- hclust(dist(abs(cor(na.omit(corr_matrix)))))
wb_cluster <- hclust(dist(abs(corr_matrix)))

wb_var_order <- names(wb_data_matrix)[wb_cluster$order]
plot(wb_cluster)

wb_ordered_indicators <-ind_wb_db[match(wb_var_order,ind_wb_db$IndicatorCode),]
##wb_selected_indicators <- wb_ordered_indicators[c(2,4,5,6,7,8,10,12,13,15,17,18,21,24,25,26,27,28,30),]
wb_selected_indicators <- wb_ordered_indicators[c(2,4,7,8,9,11,14,15,16,18,19,20,24,25,27,28,29),]

selected_wb_var <- wb_selected_indicators$IndicatorCode

# Table 1. Variables selected: 
#print(wb_selected_indicators)  
########################################################################################################################
# 5. Import data and create matrices.
# DB World Bank
wb_db <- filter(wb_db, IndicatorCode %in% selected_wb_var)

# DB ITU
data_itu_query <- dbSendQuery(db, "select * from itu_data;")
itu_db <- fetch(data_itu_query, n=-1)

# Countries
countries_query <- dbSendQuery(db, "select * from countries;") 
countries <- fetch(countries_query, n=-1)

## Table of Observations:
itu_data <- itu_db %>% filter(IndicatorCode=='IU') %>% select(CountryCode, IndicatorYear, IndicatorValue)
wb_data <- spread(wb_db, IndicatorCode, IndicatorValue)

## 5.1. Data Processing. 
### 1. Eliminate rows with NA values on any variable:
wb_data <- wb_data[apply(is.na(wb_data), 1, function(x) sum(x)==0),]

## 2. Eliminate rows for which the ITU indicator has NA Value:
wb_data <- wb_data[-c(itu_data %>% filter(is.na(IndicatorValue)) %>% select(CountryCode, IndicatorYear) %>% apply(1,paste0, collapse='')%>%
                         match(paste0(wb_data$CountryCode, wb_data$IndicatorYear))%>%intersect(1:length(wb_data[,1]))),]
## 3. itu_data table with the same rows as the wb_data table.
itu_data <- itu_data[match(paste0(wb_data$CountryCode, wb_data$IndicatorYear),paste0(itu_data$CountryCode, itu_data$IndicatorYear)),]

## 5.2. Tables with Standardized Variables

wb_data_std <- data_standardized(wb_data)$data_std
itu_data_std_list <- data_standardized(itu_data)
itu_data_std <- itu_data_std_list$data_std

## 5. Regression Analysis

### 5.1. Lasso Regression:

lasso_result <- lasso_reg(wb_data_std, itu_data_std, itu_data_std_list$data_mean, itu_data_std_list$data_sd, year_predict = NULL)

table_coeff <- lasso_result$var_selected
mutate(table_coeff, Description = wb_selected_indicators$Description[match(Variable, wb_selected_indicators$IndicatorCode)])

ggplot(lasso_result$y_predict, aes(x=IndicatorPredUnits, y=IndicatorValueUnits))+geom_point()+
  geom_abline(slope=1, intercept=0, col='red')#+geom_label(aes(label=CountryCode))


### 5.2. Bayesian Variable Selection:

bayes_result <- bayesian_reg(wb_data_std, itu_data_std, itu_data_std_list$data_mean, itu_data_std_list$data_sd, maxvars = 6, year_predict = NULL)

year_predict <- bayes_result$year_predict
table_y_predict <-bayes_result$y_predict
table_y_predict <- mutate(table_y_predict, Deviation = abs(IndicatorValueUnits-IndicatorPredUnits)>20,
                          Country=countries$Country[match(CountryCode,countries$CountryCode)])

## Plot identifying outliers countries

ggplot(table_y_predict, aes(x=IndicatorPredUnits, y=IndicatorValueUnits, label=Country))+geom_point(aes(color=Deviation))+
geom_abline(slope=1, intercept=0, linetype=2, col='blue')+ggtitle(paste('Internet Users per Country',year_predict))+
scale_x_continuous('Predicted Internet Users') + scale_y_continuous('Internet Users') +
  geom_text(aes(label=ifelse(Deviation,as.character(Country),'')),hjust=1.05,vjust=0)+
theme(panel.background = element_blank(),axis.line.x = element_line(colour = "black"),
      axis.line.y = element_line(colour = "black"),legend.position="none",plot.title = element_text(lineheight=.8, face="bold"))

table_coeff <- bayes_result$var_selected
table_coeff <- mutate(table_coeff, Description = wb_selected_indicators$Description[match(Variable, wb_selected_indicators$IndicatorCode)])
save(table_coeff, file='analysis/table_coef.Rda')

## Plot key variables vs. Internet Users
par(mfrow = c(3,2))
x <- itu_data[itu_data$IndicatorYear==year_predict,c('IndicatorValue')]
for (var in as.character(table_coeff$Variable)){
  y <- wb_data[itu_data$IndicatorYear==year_predict,c(var)]
  plot(x,y, main = var, xlab = var, ylab = 'Internet Users', pch = 16, col = 'red')
}
par(mfrow = c(1,1))


##1. Packages:
library(RMySQL);library(tidyr);library(dplyr);library(ggplot2);library(lars); library(mombf)

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


lasso_reg <- function (x, y, mean_y, sd_y, year_predict = NULL){
  #x and y are assumed to show countryCode and year in the first two columns.
  if(is.null(year_predict)) year_predict <- max(y$IndicatorYear) 
  model <- lars(x = as.matrix(x[,-c(1,2)]), y = y[,-c(1,2)], type = c('lasso'))
  x_predict <- filter(x, IndicatorYear==year_predict)
  lasso_predict <- predict.lars(model, x_predict[,-c(1,2)], type =c('fit'), mode = 'norm')$fit
  diml <- dim(lasso_predict)
  
  y_predict <- data.frame(filter(y, IndicatorYear==year_predict), IndicatorPred = lasso_predict[,diml[2]])
  mean_pred <- as.numeric(filter(mean_y, IndicatorYear == year_predict)[-1])
  sd_pred <- as.numeric(filter(sd_y, IndicatorYear == year_predict)[-1])
  
  y_predict <- mutate(y_predict, IndicatorValueUnits = IndicatorValue*sd_pred+mean_pred,  IndicatorPredUnits = IndicatorPred*sd_pred+mean_pred)
  return(list(y_predict = y_predict))  
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
  return(list(y_predict = y_predict, var_selected = data.frame(Variable = var_selected, Coef = model$coef[model$postMode==1])))  
}

## 3. DB CONNECTION
db <- dbConnect(MySQL(), user='root', password='root' , dbname='telecom', host='localhost')
dbDisconnect(db)

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
wb_cluster <- hclust(dist(abs(cor(na.omit(corr_matrix)))))
wb_var_order <- names(wb_data_matrix)[wb_cluster$order]
plot(wb_cluster)

wb_ordered_indicators <-ind_wb_db[match(wb_var_order,ind_wb_db$IndicatorCode),]
wb_selected_indicators <- wb_ordered_indicators[c(2,4,5,6,7,8,10,12,13,15,17,18,21,24,25,26,27,28,30),]
selected_wb_var <- wb_selected_indicators$IndicatorCode

# Table 1. Variables selected: 
print(wb_selected_indicators)  
########################################################################################################################
# 5. Import data and create matrices.
# DB World Bank
data_wb_query <- dbSendQuery(db, paste0("select * from wb_data where IndicatorCode in ","(",paste0("'",selected_wb_var,"'", collapse = ","),");"))
wb_db <- fetch(data_wb_query, n=-1)

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

ggplot(lasso_result$y_predict, aes(x=IndicatorPredUnits, y=IndicatorValueUnits))+geom_point()+
  geom_abline(slope=1, intercept=0, col='red')#+geom_label(aes(label=CountryCode))


### 5.2. Bayesian Variable Selection:

bayes_result <- bayesian_reg(wb_data_std, itu_data_std, itu_data_std_list$data_mean, itu_data_std_list$data_sd, year_predict = NULL)

table_coeff <- bayes_result$var_selected
mutate(table_coeff, Description = wb_selected_indicators$Description[match(Variable, wb_selected_indicators$IndicatorCode)])

ggplot(bayes_result$y_predict, aes(x=IndicatorPredUnits, y=IndicatorValueUnits))+geom_point()+
  geom_abline(slope=1, intercept=0, col='red')#+geom_label(aes(label=CountryCode))

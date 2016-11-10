
setwd("/Users/veldanie/Documents/bgse/Data Warehousing and Business Intelligence/dwbi_project")

#WB Data file from website:
#wdi_data=read.csv("wb_csv_in/WDI_Data.csv", header=TRUE, check.names = FALSE, colClasses = "character")

#Country names:
country_names=read.csv("data/country_names.csv", header=TRUE, colClasses="character", sep=";")

wb_countries=unique(country_names$WB_names[country_names$WB_names!=""])
#wb_countries_all=unique(wdi_data$"Country Name")

#Data Dim Reduction. Potential variable we should eliminate base on unexistant data for representative countries.
ind_na_total<-c()
rep_countries<-c("United States", "China", "South Africa", "Zambia", "Colombia", "Brazil", "Spain")
for(cn in rep_countries){
pos_country=which(wdi_data[,1]==cn)
pos_na=which(apply(wdi_data[pos_country,c(4,45:60)]=='',1,sum)==16)
ind_na=unique(wdi_data[pos_country[pos_na],4])
ind_na_total<-c(ind_na_total,ind_na)
}
ind_na_total<-unique(ind_na_total)

##Modify North Koreas name:
#wdi_data$"Country Name"[which(wdi_data$"Country Name"=="Korea, Dem. People\x92s Rep.")]="Korea, Dem. Peoples Rep."


#Countries not found:
#countries_not_found<-wb_countries[which(is.na(match(wb_countries,wb_countries_all)))]
#print(countries_not_found)

##Indicators:
n_ind<-length(unique(wdi_data$"Indicator Code"))
n_count<-length(wb_countries)
print(paste("Number of indicators:",n_ind))
print(paste("Number of Countries:",n_count))

##Table 1: Columns (IndicatorCode, Description)
wb_ind_codes<-unique(wdi_data$"Indicator Code")
table_wb_indicators<-data.frame(Code=wb_ind_codes,Description=wdi_data$"Indicator Name"[match(wb_ind_codes,wdi_data$"Indicator Code")])
write.table(table_wb_indicators,"data/table_wb_indicators.csv", sep=";", col.names=TRUE, row.names=FALSE, quote=FALSE)

##Table 2: Columns (Country, IndicatorCode, IndicatorYear, IndicatorValue)
library(dplyr)
wb_countries<-wb_countries[!wb_countries%in%countries_not_found]
file.remove("data_backup/table_wb_data.csv")
col_names<-TRUE
countryCode=country_names$CountryCode[match(wb_countries, country_names$WB_names)]
for (cn in wb_countries){
  for(wb_ind in wb_ind_codes){
    ind_series<-as.character(wdi_data %>% filter(`Country Name`==cn & `Indicator Code`==wb_ind) %>% select(`2000`:`2015`))
    country_df<-data.frame(CountryCode=country_names$CountryCode[which(cn==country_names$WB_names)],IndicatorCode=wb_ind, IndicatorYear=2000:2015, IndicatorValue=ind_series)
    write.table(country_df, "data_backup/table_wb_data.csv", sep=";", col.names=col_names, row.names = FALSE, quote=FALSE, append=TRUE) 
    col_names<-FALSE
  }
}

wb_data<-read.csv("data_backup/table_wb_data.csv", header=TRUE, colClasses="character", sep=";")
wb_indicators<-read.csv("data/table_wb_indicators.csv", header=TRUE, sep=";")

##Data Dim. Reduction. We eliminate variables based on `ind_na_total`
wb_data2<-wb_data[!wb_data$IndicatorCode%in%ind_na_total,]
wb_data2$IndicatorValue[wb_data2$IndicatorValue==""]="NULL"
write.table(wb_data2, "data/table_wb_data.csv", sep=";", col.names=TRUE, row.names = FALSE, quote=FALSE)

#####DATA DUMP WORLD BANK DATA
wb_data<-read.csv("data/table_wb_data.csv", header=TRUE, colClasses="character", sep=";")
wb_indicators<-read.csv("data/table_wb_indicators.csv", header=TRUE, sep=";")

l1<-paste("INSERT INTO", "wb_indicators", "(IndicatorCode,",'Description)', "VALUES")
write.table(l1,"db/wb_data_dump.sql", col.names=FALSE, row.names=FALSE, quote=FALSE, append=FALSE)

data_merge <- paste("(",paste0("'",wb_indicators[,1],"',","'",wb_indicators[,2],"'"),")",",")
last_val<-tail(data_merge,1)
data_merge[length(data_merge)]<-paste0(substr(last_val,1,nchar(last_val)-1),";")

write.table(data_merge,"db/wb_data_dump.sql", col.names=FALSE, row.names=FALSE, quote=FALSE, append=TRUE)

##Data Dump - World Bank Data
l1<-paste("INSERT INTO", "wb_data", "(CountryCode,", "IndicatorCode,", "IndicatorYear,", 'IndicatorValue)', "VALUES")
write.table(l1,"db/wb_data_dump.sql", col.names=FALSE, row.names=FALSE, quote=FALSE, append=TRUE)

data_merge <- paste("(",paste0(wb_data[,1],",","'",wb_data[,2],"',",wb_data[,3],",",wb_data[,4]),")",",")
last_val<-tail(data_merge,1)
data_merge[length(data_merge)]<-paste0(substr(last_val,1,nchar(last_val)-1),";")

write.table(data_merge,"db/wb_data_dump.sql", col.names=FALSE, row.names=FALSE, quote=FALSE, append=TRUE)


##########
##ITU

 fts=read.csv('data_backup/FTS.csv', header=TRUE, colClasses='character', check.names=FALSE)[, c(1,20:35)]
 mts=read.csv('data_backup/MTS.csv', header=TRUE, colClasses='character', check.names=FALSE)[, c(1,19:34)]
 iu=read.csv('data_backup/IU.csv', header=TRUE, colClasses='character', check.names=FALSE)

 year=2000:2015
 files=list(fts,mts,iu)
 files_names=c('FTS','MTS','IU')
 col_names=TRUE
 file.remove("data/table_itu_data.csv")
 for (j in 1:3){
  filei<- files[[j]]
  for (i in 1:length(filei[,1])){
     country_df=data.frame(CountryCode=i, IndicatorCode=files_names[j], IndicatorYear=year, IndicatorValue=as.character(filei[i,-1]))
     write.table(country_df, "data/table_itu_data.csv", sep=";", col.names=col_names, row.names = FALSE, quote=FALSE, append=TRUE)
     col_names<-FALSE
  }
}


##Country Names 
country_names=read.csv('data/country_names.csv', header=TRUE, sep=";", colClasses='character')
country_names$CountryCode=1:length(country_names$ITU_names)
write.table(country_names, 'data/country_names.csv', col.names=TRUE, row.names = FALSE, quote=FALSE, sep=";")

table_country_names=data.frame(Country=country_names$ITU_names, CountryCode=country_names$CountryCode)
write.table(table_country_names, 'data/table_country_names.csv', col.names=TRUE, row.names = FALSE, quote=FALSE, sep=";")

###DATA DUMP COUNTRY_NAMES, ITU INDICATORS
itu_data<-read.csv("data/table_itu_data.csv", header=TRUE, colClasses="character", sep=";")
itu_data$IndicatorValue[itu_data$IndicatorValue==""]="NULL"
itu_indicators<-read.csv("data/table_itu_indicators.csv", header=TRUE, sep=",", colClasses = "character")

l1<-paste("INSERT INTO", "itu_indicators", "(IndicatorCode,",'Description)', "VALUES")
write.table(l1,"db/itu_data_dump.sql", col.names=FALSE, row.names=FALSE, quote=FALSE, append=FALSE)

data_merge <- paste("(",paste0("'",itu_indicators[,1],"',","'",itu_indicators[,2],"'"),")",",")
last_val<-tail(data_merge,1)
data_merge[length(data_merge)]<-paste0(substr(last_val,1,nchar(last_val)-1),";")

write.table(data_merge,"db/itu_data_dump.sql", col.names=FALSE, row.names=FALSE, quote=FALSE, append=TRUE)

##Data Dump - Itu Indicators
l1<-paste("INSERT INTO", "itu_data", "(CountryCode,", "IndicatorCode,", "IndicatorYear,", 'IndicatorValue)', "VALUES")
write.table(l1,"db/itu_data_dump.sql", col.names=FALSE, row.names=FALSE, quote=FALSE, append=TRUE)

data_merge <- paste("(",paste0(itu_data[,1],",","'",itu_data[,2],"',",itu_data[,3],",",itu_data[,4]),")",",")
last_val<-tail(data_merge,1)
data_merge[length(data_merge)]<-paste0(substr(last_val,1,nchar(last_val)-1),";")

write.table(data_merge,"db/itu_data_dump.sql", col.names=FALSE, row.names=FALSE, quote=FALSE, append=TRUE)


##DATA DUMP COUNTRIES

countries<-read.csv('data/table_country_names.csv', header=TRUE, colClasses="character", sep=";")
l1<-paste("INSERT INTO", "countries", "(Country,",'CountryCode)', "VALUES")
write.table(l1,"db/countries_data_dump.sql", col.names=FALSE, row.names=FALSE, quote=FALSE, append=FALSE)

data_merge <- paste("(",paste0("'",countries[,1],"',",countries[,2]),")",",")
last_val<-tail(data_merge,1)
data_merge[length(data_merge)]<-paste0(substr(last_val,1,nchar(last_val)-1),";")

write.table(data_merge,"db/countries_data_dump.sql", col.names=FALSE, row.names=FALSE, quote=FALSE, append=TRUE)

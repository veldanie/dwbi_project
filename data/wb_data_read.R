
setwd("/Users/veldanie/Documents/bgse/Data Warehousing and Business Intelligence/dwbi_project")

#WB Data:
wdi_data=read.csv("wb_csv_in/WDI_Data.csv", header=TRUE, check.names = FALSE, colClasses = "character")

##Modify North Koreas name:
#wdi_data$"Country Name"[which(wdi_data$"Country Name"=="Korea, Dem. People\x92s Rep.")]="Korea, Dem. Peoples Rep."

#Country names:
country_names=read.csv("country_names.csv", header=TRUE, colClasses="character", sep=";")

wb_countries=unique(country_names$WB_names[country_names$WB_names!=""])
wb_countries_all=unique(wdi_data$"Country Name")

#Countries not found:
countries_not_found<-wb_countries[which(is.na(match(wb_countries,wb_countries_all)))]
print(countries_not_found)

##Indicators:
n_ind<-length(unique(wdi_data$"Indicator Code"))
n_count<-length(wb_countries)
print(paste("Number of indicators:",n_ind))
print(paste("Number of Countries:" ))

##Table 1: Columns (Indicator Code, Indicator Description)
wb_ind_codes<-unique(wdi_data$"Indicator Code")
table_wb_indicators<-data.frame(Code=wb_ind_codes,Description=wdi_data$"Indicator Name"[match(wb_ind_codes,wdi_data$"Indicator Code")])
write.table(table_wb_indicators,"data/table_wb_indicators.csv", sep=";", col.names=TRUE, row.names=FALSE, quote=FALSE)

##Table 2: Columns (Country, Indicator Code, Year, Value)
library(dplyr)
wb_countries<-wb_countries[!wb_countries%in%countries_not_found]
file.remove("wb_csv_out/table_wb_data.csv")
col_names<-TRUE
for (cn in wb_countries){
  for(wb_ind in wb_ind_codes){
    ind_series<-wdi_data %>% filter(`Country Name`==cn & `Indicator Code`==wb_ind) %>% select(`2000`:`2015`)
    country_df<-data.frame(Country=country_names$ITU_names[which(cn==country_names$WB_names)],IndicatorCode=wb_ind, Year=2000:2015, Value=t(country_data))
    write.table(country_df, "data/table_wb_data.csv", sep=",", col.names=col_names, row.names = FALSE, quote=FALSE, append=TRUE) 
    col_names<-FALSE
  }
}

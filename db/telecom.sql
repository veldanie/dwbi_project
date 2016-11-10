-- Data Warehousing and Cumputer Lab Project 

-- Create Database

drop database if exists telecom;
create database telecom;

-- select the database

use telecom;

-- create the required tables
-- Countries
create table countries (

Country nchar(10) not null,
CountryCode int not null,

primary key (CountryCode)
);


-- World Bank Data

drop table if exists wb_indicators;
create table wb_indicators (

IndicatorCode nchar(20) not null,
Description varchar(4000),

primary key (IndicatorCode)
);

drop table if exists wb_data;
create table wb_data (
CountryCode int not null,
IndicatorCode nvarchar(13) not null,
IndicatorYear int not null,
IndicatorValue double,

primary key (CountryCode, IndicatorCode, IndicatorYear),
foreign key (IndicatorCode) references wb_indicators (IndicatorCode) on delete no action on update no action
foreign key (CountryCode) references countries (CountryCode) on delete no action on update no action
);

-- Itu Indicators
create table itu_indicators (

IndicatorCode nchar(20) not null,
Description varchar(4000),

primary key (IndicatorCode)
);

create table itu_data (
CountryCode int not null,
IndicatorCode nvarchar(13) not null,
IndicatorYear int not null,
IndicatorValue double,

primary key (CountryCode, IndicatorCode, IndicatorYear),
foreign key (IndicatorCode) references itu_indicators (IndicatorCode) on delete no action on update no action
foreign key (CountryCode) references countries (CountryCode) on delete no action on update no action

);

drop table if exists fixedbb_prices;
create table fixedbb_prices(
Country nchar(15) not null,
`Year` int not null,
Price numeric(10,3) not null,
Speed numeric(10,3) not null,
Cap nvarchar(15) not null,
Operator nvarchar(70) not null,

primary key (Country, `Year`, Operator, Price)  
); 


drop table if exists mobilebb_prices;
create table mobilebb_prices(
Country nchar(15) not null,
`Year` int not null,
Price numeric(10,3) not null,
Cap nvarchar(15) not null,
Validity int not null,
Contract nvarchar(15) not null,  
Operator nvarchar(70) not null,

primary key (Country, `Year`, Operator, Price)  
);
-- end of file

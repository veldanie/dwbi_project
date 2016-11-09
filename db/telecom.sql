-- Data Warehousing and Cumputer Lab Project 

-- Create Database

drop database if exists telecom;
create database telecom;

-- select the database

use telecom;

-- create the required tables
drop table if exists wb_indicators;
create table wb_indicators (

IndicatorCode nchar(13) not null,
Description varchar(4000),

primary key (IndicatorCode)
);

drop table if exists wb_data;
create table wb_data (
Country nchar(15) not null,
IndicatorCode nvarchar(13) not null,
`Year` int not null,
`Value` double,

primary key (Country, IndicatorCode, `Year`),
foreign key (IndicatorCode) references wb_indicators (IndicatorCode) on delete no action on update no action
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
) ;
-- end of file

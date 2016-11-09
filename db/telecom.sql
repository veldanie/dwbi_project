-- Data Warehousing and Cumputil Lab Project 

-- Create Database

drop database telecom;
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
create table wb_indicators (

IndicatorCode nchar(20) not null,
Description varchar(4000),

primary key (IndicatorCode)
);

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


-- end of file

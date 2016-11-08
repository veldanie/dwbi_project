-- Data Warehousing and Cumputil Lab Project 

-- Create Database

drop database telecom;
create database telecom;

-- select the database

use telecom;

-- create the required tables

create table wb_indicators (

IndicatorCode nchar(13) not null,
Description varchar(4000),

primary key (IndicatorCode)
);

create table wb_data (
Country nchar(10) not null,
IndicatorCode nvarchar(13) not null,
Year int not null,
Value double,

primary key (Country, IndicatorCode, Year),
foreign key (IndicatorCode) references wb_indicators (IndicatorCode) on delete no action on update no action
);


-- end of file

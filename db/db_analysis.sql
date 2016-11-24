

use telecom;

-- Ranking by number of null values per indicator. 

select IndicatorCode, count(*)/(16*211) as perc_count
from wb_data
where IndicatorValue is not null
group by IndicatorCode
order by perc_count desc
limit 20;	

-- Ranking by indicator coverage of countries and years.

select IndicatorCode, avg(a.perc_country) as avg_perc_country, count(*)/16 as avg_perc_year,  avg(a.perc_country)*count(*)/16 as avg_total_cover
from (select IndicatorCode, IndicatorYear, count(distinct CountryCode)/211 as perc_country
from wb_data
where IndicatorValue is not null
group by IndicatorCode, IndicatorYear
order by perc_country desc) a
group by IndicatorCode
order by avg_total_cover desc
limit 20;	


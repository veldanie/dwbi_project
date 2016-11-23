

use telecom;

select IndicatorCode, count(*)/(16*211) as perc_count, count(distinct CountryCode)/211 as perc_country, 
	   count(distinct IndicatorYear)/16 as perc_year
from wb_data
where IndicatorValue is not null
group by IndicatorCode
order by perc_count desc;	


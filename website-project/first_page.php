<?php $page_title = 'Page 1'; include('header.php') ?>

<h1><center>Indicator selection for Q1</center></h1>

<p>
Our goal is to identify key macroeconomic indicators strongly related to ICT development. The World Bank (WB) publishes information for 1440 indicators and 211 countries. The period under analysis is 2000-2015. ICT development is measured using the indicator "Percentage of Internet users per country" for each year. Other indicators would be possible (e.g. mobile penetration rate) and even combinations of indicators (e.g. ITU's ICT Development Index); the methodology developed in our project could also be applied to these other indicators, the only change would be the dependent variable used in the regression phase. 

In order to identify the key macroeconomic indicators used as explanatory variable we implemented the following procedure:
</p>
<br>
<ol>
<li>First, the indicators were filtered based on the data available for a group of representative countries from all regions of the globe. If the data for a given indicator was not available for these countries, the indicator was discarded. By means of this procedure, 745 variables were discarded. Out of the remaining variables, we selected 54 indicators that potentially have a significant relation with the percentage of Internet users.</li> 
<br>
<li>In the next step, the 54 preliminary variables were ranked considering the number of years and countries for which we had non-null observations. Based on this criterion, we selected 30 variables. These are the indicators for which the number of non-null observations is greater than 70% of the total number of observations.</li>
<br>
<li>In order to avoid multicollinearity, we clustered the 30 variables chosen in the previous step based on the absolute value of their correlations. The cluster analysis allowed us to make a final selection in which we avoided including two strongly correlated variables.</li>
<li>The final step of the variable selection process relied on bayesian model selection.</li> 
</ol>
<br>
<img src="img/clustering.png" width="100%"><br>

<h2><center>Bayesian model selection</center></h2>

We performed a regression analysis in a bayesian setting. Percentage of Internet users was modeled as a linear function of the macroeconomic indicators. We assigned a prior probability to the coefficients of the explanatory variables, assuming a Zellner prior. Then,

<ol type="i">
<br>
<li> First, we defined a maximum number of variables n, and enumerated the models containing i explanatory variables, for i=1,...,n. </li>
<br>
<li> For each model, we estimated the posterior probability, i.e the marginal density times the prior probability of the model. Every model had the same prior probability.</li>
<br>
<li> We selected the model with highest posterior probability.</li>
</ol>

<p>We concluded that the variables included in the model with highest posterior probability corresponded to the most influential macroeconomic indicators.</p>

<h1><center>Indicator selection for Q2</center></h1>

<p>A second objective of the analysis was to fill in the data gaps for those countries with no data available on telecommunication performance.</p>

<p> In particular, the list of least connected countries (LCCs) published by ITU was considered. Countries in the LCC list were coded as ones and countries with data but not considered LCCs were coded as 0. The classification algorithm fitted a generalized linear model (of the type binomial) on these data, and used the results to predict the LCC status for 44 countries with unknown LCC status in 2014 (latest year with data available). The procedure was as follows:</p>

<ol type="a">
<li> The 54 variables pre-selected for the regression analysis from the WB, Google’s data on broadband prices (step 2 above) and ITU’s data on Internet users, mobile subscriptions and fixed-telephone subscriptions were extracted for the years 2008, 2010, 2011, 2012, 2013 and 2014 (i.e. years with a published LCC list).</li>
<br>
<li> The bottleneck in this regression exercise is the lack of data for the countries under consideration. Therefore, the variables selected in the previous step were ordered according to their availability for the countries to be classified, considering that the inclusion of a variable in the model implies that the countries where the variable is missing for the target year (2014) will be excluded from the model. Twelve indicators were selected, thus striking a balance between precision in the classification and countries covered (22 out of 44).</li>
<br>
<img src="img/sel_clas.png" style="float: left; width: 49%; margin-right: 1%; margin-bottom: 0.5em;">
<img src="img/table_clas.png" style="float: left; width: 49%; margin-bottom: 0.5em;">
<p style="clear: both;">
<br>
<li> All observations of countries with known LCC status were used to fit the GLM model. Time was not considered as a variable and this required a prior transformation of the data. Indeed, the LCC status of a country is determined based on the relative performance of all other countries in the same year, i.e. the lowest quartile is classified as LCC. Therefore, the variables used to fit the model were adjusted according to the value of the lowest quartile in each year. For example, 1st_Quartile_Indicator1_2008 = k; Indicator1_2010 = Indicator1_2010 * k / 1st_Quartile_Indicator1_2010; Indicator1_2011 = Indicator1_2011 * k / 1st_Quartile_Indicator1_2011 etc. </li>
<br>
<li> The fitted GLM model was used to predict the LCC status of 22 countries with unknown value in 2014.</li>
</ol>

<?php include('footer.php') ?>

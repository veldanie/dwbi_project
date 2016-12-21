<?php $page_title = 'Page 1'; include('header.php') ?>

<h1><center>Macroeconomic Factors</center></h1>

<p>
Our goal is to identify key macroeconomic indicators strongly related to telecom development. The World Bank (WB) publishes information for 1440 indicators and 211 countries. The period under analysis is 2000-2015. Telecom development is measured as percentage of internet users per country and year. In order to identify key macroeconomic indicators we implemented the following procedure:
</p>
<br>
<ul>
<li>First, the indicators were filtered based on the data available for a group of representative countries from all regions of the globe. If the data for a given indicator was not available for these countries, the indicator was discarded. By means of this procedure, 745 variables were discarded. Out of the remaining variables, we selected 54 indicators that potentially have a significant relation with the percentage of Internet users.</li> 
<br>
<li>In the next step, the 54 preliminary variables were ranked considering the number of years and countries for which we had non-null observations. Based on this criterion, we selected 30 variables. These are the indicators for which the number of non-null observations is greater than 70% of the total number of observations.</li>
<br>
<li>In order to avoid multicollinearity, we clustered the 30 variables chosen in the previous step based on the absolute value of their correlations. The cluster analysis allowed us to make a final selection in which we avoid including two strongly correlated variables.</li>
<br>
<li>The final step of the variable selection process relies on bayesian model selection.</li> 
</ul>


<h2><center>Bayesian model selection</center></h2>

We perform a regression analysis in a bayesian setting. Percentage of internet users is modeled as a linear function of macroeconomic indicators. We assign a prior probability to the coefficients of the explanatory variables.  In particular we assume a zellner prior. Then,

<ul>
<br>
<li> First, we define a maximun number of variables n, and enumerate the models containing i explanatory variables, for i=1,...,n. </li>
<br>
<li> For each model, we estimate the posterior probability, i.e the marginal density times the prior probability of the model. Every model has the same prior probability.</li>
<br>
<li> We select the model with highest posterior probability.</li>
</ul>

<p>We conclude that the variables included in the model with highest posterior probability correspond to the most influential macroeconomica indicators.</p>


<?php include('footer.php') ?>

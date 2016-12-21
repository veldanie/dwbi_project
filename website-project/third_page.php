<?php $page_title = 'Page 3'; include('header.php') ?>

<h1><center>Least connected countries (LCC)</center></h1>

<p>ITU identifies annually a number of countries as being the world’s least connected countries (LCCs) based on their performance on a combination of ICT indicators. About 40 countries are LCCs out of a total of 165 countries with data available. These data serve to identify priority countries for the ICT development aid and thus guide the investment of international donors, including development banks. </p>

<p>Unfortunately, a number of developing countries do not produce enough ICT statistics for ITU to determine their LCC status, and therefore it is not known whether they are LCCs or not. The following map shows the LCC status of countries worldwide in 2014, as well as the data gaps.</p>

<img src="img/LCC_NotEstimated.png" width="100%"><br>

<p>For several of the countries with unknown LCC status, data from the World Bank database and Google's price dataset are available. These data were used to fit a GLM model (family: binomial, link: logit) and  predict the LCC status of 22 countries with unknown value in 2014. </p>

<p>The ROC curve of the model shows that fit is rather good: almost 90 per cent of LCCs are identified without any false positive. Indeed, as we can see in the following charts, the separation of the observations using the logit model is almost complete and this explains the good results of the ROC curve.</p>

<img src="img/model_fit.png" style="float: left; width: 49%; margin-right: 1%; margin-bottom: 0.5em;">
<img src="img/roc_curve.png" style="float: left; width: 49%; margin-bottom: 0.5em;">
<p style="clear: both;">

<p>Applying the model to the 22 countries with unknown LCC status, we obtain the map below with the blanks filled in. We are assuming a decision boundary of 0.5, that is, a symmetric loss function. Indeed, we are considering that the misclassification penalty is the same both ways (i.e. for an LCC country classified as for a non-LCC and a non-LCC classified as LCC). If we were to consider that predicting a country as LCC when it is not an LCC is a worse type of error than the contrary, we could adjust the results by simply raising the decision threshold from 0.5 to a higher value based on the maximum Type I error we want to ensure.</p>
<img src="img/LCC_Estimated_final.png" width="100%"><br>

<p>In order to asses the reliability of the fit for the countries with unknown LCC status, we analyze how they are placed in the logit model. We can see that we are rather certain that countries like Bahamas or French Polynesia are not LCCs, and that Burundi and Haiti are LCCs. </p>

<p>Focusing on the predicted countries that are closest to the decision boundary, and considering the confidence intervals associated with their fir, we see that the prediction is rather uncertain for Iraq, Sao Tome and Principe, Swaziland, Tajikistan and Yemen. In particular, the probabilities of Iraq and Tajikistan being LCCs under our model are almost the same as for them not being LCCs, therefore we cannot be conclusive about their status.</p>
<img src="img/model_fit2.png" width="100%"><br>


<?php include('footer.php') ?>

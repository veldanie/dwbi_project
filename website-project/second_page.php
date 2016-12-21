<?php $page_title = "Page 2"; include('header.php'); ?>

<h1><center>Influential Macro Economic Indicators</center></h1>

<p> In order to indetify key macroeconomic indicators, percentage of internet users is modeled as a linear function of macroeconomic indicators. We implement a bayesian variable selection pocedure that allow us to indentify the most influential macro indicators. The following table exhibits the variables selected and the conrresponding regression coefficients. 
</p>
<br>

<?php
 include('connect_db.php');

$result = mysqli_query($conn, "SELECT * FROM regression_coeff");

echo "<table id='regression_coeff' class='dataTable display cell-border'>";
echo "<thead><tr><th>Variable</th><th>Coefficient</th><th>Description</th></tr></thead>";
echo "<tbody>";
while($row = mysqli_fetch_array($result)) {
    $Variable = $row['Variable'];
    $Coefficient = $row['Coefficient'];
    $Description = $row['Description'];
    
    echo "<tr><td>".$Variable."</td><td>".$Coefficient."</td><td>".$Description."</td><tr>";
}
echo "</tbody>";
echo "</table>";

mysqli_close($conn);
?>
<script>
$(document).ready( function () {
    $('#myTable').DataTable();
} );
</script>

<br>
<br>
The following figure shows the four most relevant macro economic indicators plotted against the percentage of internet users. 

<img src="img/iu_vs_var.png" width="100%"><br>

<br>
<br>

<h1><center>Outliers</center></h1>

<p> Another goal of the analysis is to detect outliers, which in this context does not have a negative connotation but rather indicates the countries that are under- or outperforming. That is, an outlier represents a country that, in a particular year, exhibits poor socioeconomic performance but high telecom improvement or viceversa. We identify outliers when observe a relevant deviation between the model prediction and the actual observation. 
</p>

<img src="img/outliers.png" width="80%"><br>
<?php include('footer.php') ?>
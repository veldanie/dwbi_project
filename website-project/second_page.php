<?php $page_title = "Page 2"; include('header.php'); ?>

<h1><center>Socio-Economic factors affecting the Digital Divide</center></h1>

<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi consectetur lectus quis leo viverra iaculis. Donec at turpis orci. Cras odio ante, venenatis sed condimentum a, lobortis a nibh. Fusce aliquam metus vel ipsum ultricies dictum. Mauris ac tellus tincidunt eros pharetra dictum a vel nisi. Quisque quis est feugiat ex hendrerit facilisis a vel felis. Praesent eleifend lacinia rhoncus. Nunc ac dui diam. Duis sodales volutpat maximus. Vivamus laoreet bibendum consequat. Sed tempus lacus vitae magna ultrices aliquam.</p>

<?php
include('connect_db.php');

$result = mysqli_query($conn, "SELECT * FROM LCCs");

echo "<table id='myTable' class='dataTable display cell-border'>";
echo "<thead><tr><th>CountryCode</th><th>Year</th><th>LCChaita</th></tr></thead>";
echo "<tbody>";
while($row = mysqli_fetch_array($result)) {
    $CountryCode = $row['CountryCode'];
    $Year = $row['Year'];
    $LCC = $row['LCC'];
    
    echo "<tr><td>".$CountryCode."</td><td>".$Year."</td><td>".$LCC."</td><tr>";
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

<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi consectetur lectus quis leo viverra iaculis. Donec at turpis orci. Cras odio ante, venenatis sed condimentum a, lobortis a nibh. Fusce aliquam metus vel ipsum ultricies dictum. Mauris ac tellus tincidunt eros pharetra dictum a vel nisi. Quisque quis est feugiat ex hendrerit facilisis a vel felis. Praesent eleifend lacinia rhoncus. Nunc ac dui diam. Duis sodales volutpat maximus. Vivamus laoreet bibendum consequat. Sed tempus lacus vitae magna ultrices aliquam.</p>

<?php include('footer.php') ?>
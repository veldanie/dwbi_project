<?php

$servername = "127.0.0.1";
$username = "root";
$password = "root";
$dbname = "telecom";

// Create connection
$conn = mysqli_connect($servername, $username, $password, $dbname);
if (mysqli_connect_errno()) { echo "Failed to connect to MySQL: " . mysqli_connect_error(); }

?>
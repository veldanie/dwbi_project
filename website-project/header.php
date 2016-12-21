<!doctype html>
<!--[if lt IE 7]>      <html class="no-js lt-ie9 lt-ie8 lt-ie7" lang=""> <![endif]-->
<!--[if IE 7]>         <html class="no-js lt-ie9 lt-ie8" lang=""> <![endif]-->
<!--[if IE 8]>         <html class="no-js lt-ie9" lang=""> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js" lang=""> <!--<![endif]-->
	<head>
		<meta charset="utf-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
		<title>Digital Divide</title>
		<meta name="description" content="">
		<meta name="viewport" content="width=device-width, initial-scale=1">

		<link rel="stylesheet" href="css/normalize.min.css">
		<link rel="stylesheet" href="css/bootstrap.min.css">
		<link rel="stylesheet" href="https://cdn.datatables.net/v/dt/dt-1.10.12/r-2.1.0/datatables.min.css"/>
		<link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Open+Sans">
		<link rel="stylesheet" href="css/main.css">

		<script src="js/vendor/modernizr-2.8.3.min.js"></script>
		<script src="js/vendor/jquery-1.11.2.min.js"></script>
		<script src="js/vendor/jquery.tablesorter.min.js"></script>
		<script src="js/vendor/bootstrap.min.js"></script>
		<script src="https://cdn.datatables.net/v/dt/dt-1.10.12/r-2.1.0/datatables.min.js"></script>
		<script src="js/main.js"></script>
	</head>
	<body>
		<!--[if lt IE 8]>
			<p class="browserupgrade">You are using an <strong>outdated</strong> browser. Please <a href="http://browsehappy.com/">upgrade your browser</a> to improve your experience.</p>
		<![endif]-->
		<nav class="navbar navbar-inverse">
		  <div class="container-fluid">
				<div class="navbar-header">
				  <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#myNavbar">
						<span class="icon-bar"></span>
						<span class="icon-bar"></span>
						<span class="icon-bar"></span> 
				  </button>
				</div>
				<div class="collapse navbar-collapse text-center" id="myNavbar">
				  <ul class="nav navbar-nav center-block text-center">
				  	<li <?php if ($page_title == "Home")   echo 'class="active"';?>><a href="/">Home</a></li>
					<li <?php if ($page_title == "Page 1") echo 'class="active"';?>><a href="/first_page.php">Variable Selection Process</a></li>
					<li <?php if ($page_title == "Page 2") echo 'class="active"';?>><a href="/second_page.php">Influential Macroeconomic Indicators</a></li> 
					<li <?php if ($page_title == "Page 3") echo 'class="active"';?>><a href="/third_page.php">LCC</a></li> 
				  </ul>
				</div>
		  </div>
		</nav>
		<section id="wrapper">
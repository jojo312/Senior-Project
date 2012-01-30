<?
session_start();
?>
<!DOCTYPE html>
<html>
<head>
    <title>Device Monitoring System</title>
    <meta charset="UTF-8" />
    <link href="stylesheets/style.css" rel="stylesheet" type="text/css" media="screen" />
    <link href="stylesheets/home_style.css" rel="stylesheet" type="text/css" media="screen" />
</head>
<body>
    <nav>
        <a href="/~mjholden/DMS/">Home</a>
        <?php
        if(isset($_SESSION['signed_in']) && $_SESSION['signed_in']) // User is logged in
        {
        ?>
        <a href="devices">Devices</a>
        <a href="settings" class="signin">Settings</a>
        <a href="process.php" class="signin">Sign Out</a>
        <?
        }
        else
        {
        ?>
        <a href="register" class="signin">Register</a>
        <a href="signin" class="signin">Sign In</a>
        <?
        }
        ?>
    </nav>
    <div class="maindiv">
        <h1>Device Monitoring System</h1>
        <p>Have you ever had your computer stolen?<br />Or maybe you lost it and want to be able to find it. Maybe you
        just want to keep an eye on your network. If that's the case then I have a solution!</p>
        <p>This device monitoring system tracks your computer's location allowing you to track it down if it is ever
        lost or stolen.</p>
        <p>Hopefully that will never be a concern, but if it is, will you be prepared?</p>
    </div>
</body>
</html>

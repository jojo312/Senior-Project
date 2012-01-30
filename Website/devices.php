<?php
/*
 devices.php
 
 The webpage that shows a user's devices
*/
require_once('includes/database.php');
session_start();
if(isset($_SESSION['signed_in']) && !$_SESSION['signed_in'])
{
    header("Location: /~mjholden/DMS/signin");
}
else
{
?>
<!DOCTYPE HTML>
<html>
<head>
    <title>Devices</title>
    <meta charset="UTF-8" />
    <link href="stylesheets/style.css" rel="stylesheet" type="text/css" media="screen" />
    <link href="stylesheets/device_style.css" rel="stylesheet" type="text/css" media="screen" />
</head>
<body>
    <nav>
        <a href="/~mjholden/DMS/">Home</a>
        <a href="/~mjholden/DMS/devices">Devices</a>
        <a href="/~mjholden/DMS/settings" class="signin">Settings</a>
        <a href="/~mjholden/DMS/process.php" class="signin">Sign Out</a>
    </nav>
    <div class="maindiv">
        <h1>Devices</h1>
        <?
        if(isset($_SESSION['email']))
        {
            $email = $_SESSION['email'];
            $database->cleanVar($email);
            $result = $database->getUserDevices($email);
            while($row = mysql_fetch_row($result))
            {
            ?>
            <div id="device">
                <a href="/~mjholden/DMS/device/<? echo $row['device_id']; ?>"><? echo $row['device_name']; ?></a>
                <a href="/~mjholden/DMS/device/<? echo $row['device_id']; ?>">Reports</a>
            </div>
            <hr />
            <?
            }
        }
        ?>
    </div>
</body>
</html>
<?
}
?>
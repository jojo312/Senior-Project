<?php
require_once('includes/database.php');

if(isset($_POST['email']) && isset($_POST['password']) && isset($_POST['devname']))
{
    if($database->checkUserPass($_POST['email'],$_POST['password']))
    {
        $result = $database->createDevice($_POST['email'],$_POST['devname']);
        echo $result;
    }
}
?>
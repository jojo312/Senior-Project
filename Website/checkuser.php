<?php
require_once('includes/database.php');

if(isset($_POST['email']) && isset($_POST['password']))
{
    if($database->checkUserPass($_POST['email'],$_POST['password']))
        echo "true";
}
?>
<?php
require_once('includes/database.php');
if(isset($_POST['email']) && isset($_POST['password']) && isset($_POST['devid']))
{
    if($database->checkUserPass($_POST['email'],$_POST['password']))
    {
        $retval = $database->isLost($_POST['email'],$_POST['devid']);
        if($retval == false)
            echo '0';
        else
            echo $retval;
    }
    else
        echo '0';
}
else
    echo '0';
?>
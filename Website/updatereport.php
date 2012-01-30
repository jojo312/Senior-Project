<?php
require_once('includes/database.php');

if(isset($_POST['email']) && isset($_POST['password']) && isset($_POST['repid'])
   && isset($_POST['snappath']) && isset($_POST['screenpath'])
   && isset($_POST['location']) && isset($_POST['extip']) && isset($_POST['intip'])
   && $database->checkUserPass($_POST['email'],$_POST['password']))
{
    $retval = $database->updateReport($_POST['repid'],$_POST['extip'],$_POST['intip'],$_POST['screenpath'],$_POST['snappath'],$_POST['location']);
    echo $retval;
}
else
    echo 0;
?>
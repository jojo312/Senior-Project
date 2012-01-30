<?php
require_once('includes/database.php');

if(isset($_POST['email']) && isset($_POST['password']) && $database->checkUserPass($_POST['email'],$_POST['password']))
{
    if((($_FILES['file']['type'] == 'image/gif')
        || ($_FILES['file']['type'] == 'image/jpeg')
        || ($_FILES['file']['type'] == 'image/png'))
       && ($_FILES['file']['size'] < 20000))
    {
        if($_FILES['file']['error'] > 0)
            echo $_FILES['file']['error'];
        else
        {
            if(!file_exists('/~mjholden/DMS/pics/'.$_FILES['file']['name']))
            {
                move_uploaded_file($_FILES['file']['tmp_name'],'/~mjholden/DMS/pics/'.$_FILES['file']['name']);
                echo 0;
            }
        }
    }
}

?>
<?php
/*
 mailer.php
 
 A class that handles the sending of emails to users when:
    -a new account is created
    -a new report is available
    -a device is marked as missing
 
 @author: Micah Holden
*/

class Mailer
{
    /*
     sendWelcome - Sends an email to the newly created user
     params:    $email, user's email
                $first, user's first name
                $last, user's last name
     returns: true if email is accepted for delivery, false otherwise
    */
    function sendWelcome($email, $first, $last)
    {
        $from = "From: ".EMAIL_NAME." <".EMAIL_ADDR.">";
        $subject = "Welcome to CMS";
        $body = "Hello, ".$first." ".$last."!\n\n".
                "You have successfully registered with CMS.\n".
                "To log in, please visit:\n".
                HOME_URL."\n\n".
                "- DMS";
        return mail($email,$subject,$body,$from);
    }
    
    /*
     sendReport - Notifies the user that a new report is available for viewing
     params:    $email, user's email
                $first, user's first name
                $device, device name
     returns: true if email is accepted for delivery, false otherwise
    */
    function sendReport($email, $first, $device)
    {
        $from = "From: ".EMAIL_NAME." <".EMAIL_ADDR.">";
        $subject = "New CMS Report Available";
        $body = $first.",\n\n".
                "A new report is available for the missing device, ".$device.".\n\n".
                "You can access it by logging in at:\n".
                HOME_URL."\n\n".
                "- DMS";
        return mail($email,$subject,$body,$from);
    }
    
    /*
     sendLost - Notifies the user that they reported their device as lost
     params:    $email, user's email
                $first, user's first name
                $device, device name
     returns: true if email is accepted for delivery, false otherwise
    */
    function sendLost($email, $first, $device)
    {
        $from = "From: ".EMAIL_NAME." <".EMAIL_ADDR.">";
        $subject = "CMS Device Lost";
        $body = $first.",\n\n".
                "You have flagged your device, ".$device.", as lost.\n\n".
                "A report should be generated soon.\n\n".
                "You can log in to view it at:\n".
                HOME_URL."\n\n".
                "- DMS";
        return mail($email,$subject,$body,$from);
    }
}
$mailer = new Mailer();
?>
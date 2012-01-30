<?php
/*
 process.php
 
 A class that handles the processing of submitted forms, redirecting to correct
 pages if there are errors or if the form is successful, signs the user out,
 sets session variables.
*/
require_once('includes/database.php');
require_once('includes/mailer.php');

class Process
{
    /* The class constructor */
    function Process()
    {
        session_start();
        extract($_POST);
        if(isset($subsignin))
            $this->signin($email,$password,isset($remember));
        elseif(isset($subregister))
            $this->register($first_name,$last_name,$email,$password1,$password2);
        elseif(isset($_SESSION['signed_in']) && $_SESSION['signed_in'])
            $this->signout();
        else
            header("Location: /~mjholden/DMS/");
    }
    
    /*
     generateToken - Generates a random string for the token value.
    */
    function generateToken()
    {
        return md5(uniqid(rand().time(),true));
    }
    
    /*
     signin - Signs in the user if the submitted values are correct.
     params: $email, user's email, $pass, user's password, $remember, whether
        the user wants to remember the password on next login.
    */
    function signin($email, $pass, $remember)
    {
        global $database;
        $errors = '';
        // Check email
        if(!$email || strlen($email = trim($email)) == 0)
            $errors .= '* Email not entered|';
        // Check password
        if(empty($pass))
            $errors .= '* Password not entered|';
        // Check that user is in the database
        $result = $database->checkUserPass($email,$pass);
        // Check error codes
        if(!$result)
            $errors .= '* Email or password invalid|';
        // If there are errors, redirect to show errors
        if(!empty($errors))
        {
            $_SESSION['signed_in'] = false;
            $_SESSION['error'] = $errors;
        }
        else
        {
            $userinfo = $database->getUserInfo($email);
            $_SESSION['email'] = $userinfo['user_email'];
            $_SESSION['first'] = $userinfo['user_first_name'];
            $_SESSION['token'] = $this->generateToken();
            $database->updateUserField($_SESSION['email'],'user_token',$_SESSION['token']);
            if($remember)
            {
                setcookie("cookname",$_SESSION['email'],time()+COOKIE_TIMEOUT,COOKIE_PATH);
                setcookie("cookid",$_SESSION['token'],time()+COOKIE_TIMEOUT,COOKIE_PATH);
            }
            $_SESSION['signed_in'] = true;
        }
        header("Location: /~mjholden/DMS/signin");
    }
    
    /*
     signout - Signs out the user
    */
    function signout()
    {
        // Delete cookies
        if(isset($_COOKIE['cookname']) && isset($_COOKIE['cookid']))
        {
            setcookie("cookname","",time()-COOKIE_TIMEOUT,COOKIE_PATH);
            setcookie("cookid","",time()-COOKIE_TIMEOUT,COOKIE_PATH);
        }
        // Unset session variables
        $_SESSION = array();
        $_SESSION['signed_in'] = false;
        header("Location: /~mjholden/DMS/");
    }
    
    /*
     register - Registers the user if the submitted values are valid
     params: $first, user first name, $last, user last name,
        $email, user email, $pass, user password
    */
    function register($first, $last, $email, $pass1,$pass2)
    {
        global $database, $mailer;
        $errors = '';
        // Check email
        if(!$email || strlen($email = trim($email)) == 0)
            $errors .= '* Email not entered|';
        else
        {
            if($database->checkEmail($email))
                $errors .= '* Email already in use|';
        }
        // Check password
        if(empty($pass1) || empty($pass2))
            $errors .= '* Password not entered|';
        elseif($pass1 != $pass2)
            $errors .= '* Passwords do not match|';
        else
        {
            if(strlen($pass1) < 6)
                $errors .= '* Password too short|';
            elseif(!eregi("^[0-9a-z])+$", ($pass1 = trim($pass1))))
                $errors .= '* Password not alphanumeric|';
        }
        if($database->createUser($first,$last,$email,$pass1))
        {
            $userinfo = $database->getUserInfo($email);
            $_SESSION['regemail'] = $userinfo['user_email'];
            $_SESSION['regfirst'] = $userinfo['user_first_name'];
            $_SESSION['regsuccess'] = true;
            $mailer->sendWelcome($userinfo['user_email'],$userinfo['user_first_name'],$userinfo['user_last_name']);
        }
        else
        {
            $_SESSION['regemail'] = $email;
            $_SESSION['regsuccess'] = false;
        }
        if(!empty($errors))
        {
            $_SESSION['error'] = $errors;
            header("Location: /~mjholden/DMS/register");
        }
    }
}
$process = new Process();
?>
<?php
/*
 database.php
 
 A class that handles all interactions with the database from the website.
 
 @author: Micah Holden
*/
require_once('constants.php');

class Database
{
    var $dblink;
    
    /* Database constructor */
    function Database()
    {
        $this->dblink = mysql_connect(DB_HOST,DB_USER,DB_PASS) or die(mysql_error());
        mysql_select_db(DB_NAME, $this->dblink) or die(mysql_error());
    }
    
    /*
     cleanVar - Cleans the given variable by applying proper slashes
     param: $var, the variable to be cleaned
    */
    function cleanVar(&$var)
    {
        if(get_magic_quotes_gpc())
            $var = is_array($var) ? array_map('stripslashes',$var) : stripslashes($var);
        $var = is_array($var) ? array_map('mysql_real_escape_string',$var) : mysql_real_escape_string($var);
    }
    
    /*
     checkUserPass - Checks whether the given email is in the database
     and that the passwords match
     params: $email, the email to be checked, $pass, the password to be checked
     returns: true if successful, false otherwise
    */
    function checkUserPass($email, $pass)
    {
        $this->cleanVar($email);
        $this->cleanVar($pass);
        $query =   "SELECT `user_password`,`user_salt`
                    FROM ".DB_NAME.".".TBL_USERS."
                    WHERE `user_email` = '$email'";
        $result = mysql_query($query, $this->dblink);
        if(!$result || mysql_num_rows($result) < 1)
            return false; // Invalid email
        $assoc = mysql_fetch_assoc($result);
        if(md5(md5($pass).$assoc['user_salt']) == $assoc['user_password'])
            return true; // Valid email and password
        return false; // Invalid password
    }
    
    /*
     checkUserID - Checks whether the randomly generated user login id is valid
     params: $email, the user's email, $token, the token to be checked
     returns: 0 if successful, 1 on email failure, 2 on userid failure
    */
    function checkUserToken($email, $token)
    {
        $this->cleanVar($email);
        $this->cleanVar($token);
        $query =   "SELECT `user_token`
                    FROM ".DB_NAME.".".TBL_USERS."
                    WHERE `user_email` = '$email';";
        $result = mysql_query($query, $this->dblink);
        if(!$result || mysql_num_rows($result) < 1)
            return 1; // Invalid email
        $info = mysql_fetch_assoc($result);
        if($token == $info['user_token'])
            return 0; // Success
        return 2; // Invalid token
    }
    
    /*
     checkEmail - Checks if the given email is already in the database
     param: $email, the email to be checked
     returns: true if it is already in use, false otherwise
    */
    function checkEmail($email)
    {
        $this->cleanVar($email);
        $query =   "SELECT COUNT(`user_email`) AS `count`
                    FROM ".DB_NAME.".".TBL_USERS."
                    WHERE `user_email` = '$email'";
        $result = mysql_query($query,$this->dblink);
        $assoc = mysql_fetch_assoc($result);
        if($assoc['count'] == 1) return true;
        return false;
    }
    
    /*
     createUser - Creates a new user and adds them to the database
     params: $first, user first name, $last, user last name,
             $email, the email to insert, $pass, the password for the user
     returns: true if successful, false otherwise
    */
    function createUser($first, $last, $email, $pass)
    {
        $this->cleanVar($first);
        $this->cleanVar($last);
        $this->cleanVar($email);
        $this->cleanVar($pass);
        if((!$first || strlen($first = trim($first)) == 0)
           || (!$last || strlen($last = trim($last)) == 0)
           || (!$email || strlen($email = trim($email)) == 0)
           || (!$pass || strlen($pass = trim($pass)) == 0))
            return false;
        if($this->checkEmail($email))
            return false; // Email already in database
        // Create salt and password hash
        $salt = md5(date(DATE_RFC2822));
        $passthesalt = md5(md5($pass).$salt);
        $this->begin();
        $query =   "INSERT INTO ".DB_NAME.".".TBL_USERS."
                    VALUES (NULL, '$first', '$last', '$email', '$passthesalt', '$salt', '0','1','1','".time()."')";
        $result = mysql_query($query,$this->dblink);
        if($result)
        {
            $this->commit();
            return true; // Successful registration
        }
        $this->rollback();
        return false;
    }
    
    /*
     updateUserField - Updates the given field to the new value
     params: $email, the user's email, $field, the field to update, $value, the new value
    */
   function updateUserField($email, $field, $value)
   {
      $email = $this->cleanVar($email);
      $value = $this->cleanVar($value);
      $q = "UPDATE ".DB_NAME.".".TBL_USERS." SET `".$field."` = '$value' WHERE `user_email` = '$email'";
      return mysql_query($q, $this->dblink);
   }
    
    /*
     createDevice - Creates a new device for the specified user and adds
     it to the database
     params: $email, the user's email
     returns: the new device id if successful, false otherwise
    */
    function createDevice($email,$devname)
    {
        $this->cleanVar($email);
        $this->cleanVar($devname);
        if(!$this->checkEmail($email))
            return false; // Invalid email
        // Create a new device
        $query =   "CALL ".DB_NAME."."."CreateDevice('$email','$devname');";
        $this->begin();
        mysql_query($query,$this->dblink);
        $result = mysql_query("SELECT LAST_INSERT_ID() AS `device_id`",$this->dblink);
        if(!$result || mysql_num_rows($result) < 1)
        {
            $this->rollback();
            return false; // Insert failed
        }
        $this->commit();
        $retval = mysql_fetch_assoc($result);
        return $retval['device_id']; // Success
    }
    
    /*
     createReport - Creates a report for the specified user device.
     params: $email, the user's email, $devid, the device id
     returns: the new report id if successful, false otherwise
    */
    function createReport($devid)
    {
        $this->cleanVar($devid);
        // Create new report
        $query = "CALL ".DB_NAME.".CreateReport($devid);";
        $this->begin();
        mysql_query($query,$this->dblink);
        $result = mysql_query("SELECT LAST_INSERT_ID() AS `report_id`",$this->dblink);
        if(!$result || mysql_num_rows($result) < 1)
        {
            $this->rollback();
            return false; // Insert failed
        }
        $this->commit();
        $retval = mysql_fetch_assoc($result);
        return $retval['report_id']; // Success
    }
    
    /*
     isLost - Checks if the given device is lost
     params: $email, the user's email, $devid, the device id
     returns: the new report id if the device is lost, false otherwise
    */
    function isLost($email, $devid)
    {
        $this->cleanVar($email);
        $this->cleanVar($devid);
        if(!$this->checkEmail($email))
            return false; // Invalid email
        // Check if device is lost
        $query =   "SELECT u.`user_email`, d.`device_lost`
                    FROM ".DB_NAME.".".TBL_USERS." u
                    JOIN ".DB_NAME.".".TBL_USER_DEVICES." ud
                    ON u.`user_id` = ud.`user_id`
                    JOIN ".DB_NAME.".".TBL_DEVICES." d
                    ON d.`device_id` = ud.`device_id`
                    AND d.`device_id` = $devid
                    WHERE u.`user_email` = '$email'";
        $result = mysql_query($query,$this->dblink);
        if(mysql_num_rows($result) > 0)
        {
            $assoc = mysql_fetch_assoc($result);
            if($assoc['device_lost'] == 1)
                return $this->createReport($devid);
        }
        return false;
    }
    
    /*
     updateUser - Updates a user's info in the database
     params: $email, the user's email, $field, the field to be updated, $value,
     the new value of the field
     returns: true if successful, false otherwise
    */
    function updateUser($email, $field, $value)
    {
        $this->cleanVar($email);
        $this->cleanVar($value);
        $query =   "UPDATE ".DB_NAME.".".TBL_USERS." SET `".$field."` = '$value'
                    WHERE `user_email` = '$email'";
        return mysql_query($query,$this->dblink);
    }
    
    /*
     updateReport - Updates a report in the database
     params: $repid, the report id, $field, the field to be updated, $value,
     the new value of the field
     returns: true if successful, false otherwise
    */
    function updateReport($repid, $extip, $intip, $snap, $screen, $location)
    {
        $this->cleanVar($repid);
        $this->cleanVar($value);
        $query =   "UPDATE ".DB_NAME.".".TBL_REPORTS." SET `report_ext_ip` = '$extip',
                    `report_int_ip` = '$intip',`report_snap_path` = '$snap',
                    `report_screen_path` = '$screen',`report_location` = '$location' 
                    WHERE `report_id` = '$repid';";
        return mysql_query($query,$this->dblink);
    }
    
    /*
     getUserInfo - Gets the user's info to store in the session
     param: $email, the user's email
     returns: an associative array containing the user's info
    */
    function getUserInfo($email)
    {
        $this->cleanVar($email);
        $query =   "SELECT *
                    FROM ".DB_NAME.".".TBL_USERS."
                    WHERE `user_email` = '$email'";
        $result = mysql_query($query, $this->dblink);
        if(!$result || mysql_num_rows($result) < 1)
            return NULL;
        return mysql_fetch_assoc($result);
    }
    
    /*
     getUserDevices - Gets the devices associated with the given email
     param: $email, the user's email
     returns:   1 if invalid email
                2 if invalid query
                otherwise, the result with the user's devices
    */
    function getUserDevices($email)
    {
        $this->cleanVar($email);
        if(!$this->checkEmail($email))
            return 1; // Invalid email
        $query =   "SELECT u.user_email, d.device_name
                    FROM ".DB_NAME.".".TBL_USERS." u
                    JOIN ".DB_NAME.".".TBL_USER_DEVICES." ud
                    ON u.`user_id`=ud.`user_id`
                    JOIN ".DB_NAME.".".TBL_DEVICES." d
                    ON d.`device_id`=ud.`device_id`
                    WHERE u.`user_email`='$email';";
        $result = mysql_query($query,$this->dblink);
        if($result)
            return $result; // Success
        return 2; // Invalid query
    }
    
    /*
     getUserDevice - Gets the specified device associated with the given email
     params: $email, the user's email, $devid, the device's id
     returns:   1 if invalid email
                2 if invalid device id
                3 if invalid query
                otherwise, an associative array with the specified device info
    */
    function getUserDevice($email, $devid)
    {
        $this->cleanVar($email);
        $this->cleanVar($devid);
        if(!$this->checkEmail($email))
            return 1; // Invalid email
        if(!$devid || strlen($devid = trim($devid)) == 0)
            return 2; // Invalid device id
        $query =   "SELECT u.user_email, d.*
                    FROM ".DB_NAME.".".TBL_DEVICES." d
                    JOIN ".DB_NAME.".".TBL_USER_DEVICES." ud
                    ON d.`device_id`=ud.`device_id`
                    JOIN ".DB_NAME.".".TBL_USERS." u
                    ON u.`user_id`=ud.`user_id`
                    WHERE u.`user_email`='$email' AND d.`device_id` = $devid;";
        $result = mysql_query($query,$this->dblink);
        if($result)
            return mysql_fetch_assoc($result); // Success
        return 3; // Invalid query
    }
    
    /*
     getDeviceReports - Gets all the reports associated with a given
     email and device
     params: $email, the user's email, $devid, the device's id
     returns:   1 if invalid email
                2 if invalid device id
                3 if invalid query
                otherwise, the result with the reports for a given device
    */
    function getDeviceReports($email, $devid)
    {
        $this->cleanVar($email);
        $this->cleanVar($devid);
        if(!$this->checkEmail($email))
            return 1; // Invalid email
        if(!$devid || strlen($devid = trim($devid)) == 0)
            return 2; // Invalid device id
        $query =   "SELECT u.user_email, d.device_name, r.report_timestamp
                    FROM ".DB_NAME.".".TBL_USERS." u
                    JOIN ".DB_NAME.".".TBL_USER_DEVICES." ud
                    ON u.`user_id`=ud.`user_id`
                    JOIN ".DB_NAME.".".TBL_DEVICES." d
                    ON d.`device_id`=ud.`device_id`
                    JOIN ".DB_NAME.".".TBL_DEVICE_REPORTS." dr
                    ON d.`device_id`=dr.`device_id`
                    JOIN ".DB_NAME.".".TBL_REPORTS." r
                    ON r.`report_id`=dr.`report_id`
                    WHERE u.`user_email`='$email' AND d.`device_id`=$devid;";
        $result = mysql_query($query,$this->dblink);
        if($result)
            return $result; // Success
        return 3; // Invalid query
    }
    
    /*
     getDeviceReport - Gets the specified report for the given email and device
     params: $email, the user's email, $devid, the device's id, $repid, the report id
     returns:   1 if invalid email
                2 if invalid device id
                3 if invalid report id
                4 if invalid query
                otherwise, an associative array containing the info for the specified report
    */
    function getDeviceReport($email, $devid, $repid)
    {
        $this->cleanVar($email);
        $this->cleanVar($devid);
        $this->cleanVar($repid);
        if(!$this->checkEmail($email))
            return 1; // Invalid email
        if(!$devid || strlen($devid = trim($devid)) == 0)
            return 2; // Invalid device id
        if(!$repid || strlen($repid = trim($repid)) == 0)
            return 3; // Invalid report id
        $query =   "SELECT u.user_email, d.device_name, r.*
                    FROM ".DB_NAME.".".TBL_USERS." u
                    JOIN ".DB_NAME.".".TBL_USER_DEVICES." ud
                    ON u.`user_id`=ud.`user_id`
                    JOIN ".DB_NAME.".".TBL_DEVICES." d
                    ON d.`device_id`=ud.`device_id`
                    JOIN ".DB_NAME.".".TBL_DEVICE_REPORTS." dr
                    ON d.`device_id`=dr.`device_id`
                    JOIN ".DB_NAME.".".TBL_REPORTS." r
                    ON r.`report_id`=dr.`report_id`
                    WHERE u.`user_email`='$email' AND d.`device_id`=$devid AND r.`report_id`=$repid;";
        $result = mysql_query($query,$this->dblink);
        if($result)
            return mysql_fetch_assoc($result); // Success
        return 4; // Invalid query
    }
    
    /*
     query - Runs the given query on the database
     params: $query, the query to be run
     returns: the result from the database
    */
    function query($query)
    {
        return mysql_query($query, $this->dblink);
    }
    
    /*
     begin - Begins a database transaction
    */
    function begin()
    {
        mysql_query("BEGIN",$this->dblink);
    }
    
    /*
     commit - Commits a database transaction
    */
    function commit()
    {
        mysql_query("COMMIT",$this->dblink);
    }
    
    /*
     rollback - Rolls back a database transaction
    */
    function rollback()
    {
        mysql_query("ROLLBACK",$this->dblink);
    }
}

$database = new Database();
?>
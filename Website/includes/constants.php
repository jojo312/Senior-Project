<?php
/*
 constants.php
 
 Contains the constants that will be used to access the database,
 session, cookies, and emailing the user.
 
 Author: Micah Holden
*/
/**/

/* Database Constants */
define('DB_HOST','mysql.cis.ksu.edu');
define('DB_USER','mjholden');
define('DB_PASS','password'); // This is not my password
define('DB_NAME','mjholden');

/* Database Table Constants */
define('TBL_USERS','DMS_USER');
define('TBL_DEVICES','DMS_DEVICE');
define('TBL_USER_DEVICES','DMS_USER_DEVICES');
define('TBL_REPORT','DMS_REPORT');
define('TBL_DEVICE_REPORTS','DMS_DEVICE_REPORTS');

/* Session/Cookie Constants */
define('SESSION_TIMEOUT',30); // 30 minute sessions
define('COOKIE_NAME','dmscookie');
define('COOKIE_TIMEOUT',60*60*24*30); // Expires in 30 days
define('COOKIE_PATH','/~mjholden/CIS598/');

/* Email Constants */
define('EMAIL_NAME','Micah Holden');
define('EMAIL_ADDR','mjholden@k-state.edu');

/* Other Constants */
define('HOME_URL','/~mjholden/CIS598/');
define('PRIVATE_KEY','pF?74Z6-q3');
?>
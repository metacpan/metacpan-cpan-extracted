use lib '../../conf';
require 'config.pl';
require "../../drivers/db_flat.pl";

###################################################
#!!! CONFIGURE "config.pl" BEFORE RUN THAT FILE !!!
#!!! Update: user,password,database and tables  !!!
###################################################

$admin_user = 'admin';             # !!!EDIT!!!
$admin_pass = 'adminpassword';     # !!!EDIT!!!

 $dbh = sql_connect();
 $tab = << "TERMI";
 $sql_sessions_table (
        ID LONG,
        S_ID VARCHAR(255),
        IP VARCHAR(20),
        EXPIRE INT,
        FLAG CHAR(1),
        DATA VARCHAR(1048576)
        )
TERMI
 sql_create_db($tab,$dbh);
$tab = << "TERMI";
 $sql_user_table (
        ID LONG,
        USER VARCHAR(50),
        PASSWORD VARCHAR(50),
        ACTIVE CHAR(1),
        DATA VARCHAR(1048576),
        CREATED DATETIME,
        FNAME VARCHAR(50),
        LNAME VARCHAR(50),
        EMAIL VARCHAR(120)
        )
TERMI
 sql_create_db($tab,$dbh);
 my $tm = time();
 sql_query("insert into $sql_user_table values(MAXVAL('ID|$sql_user_table'),'$admin_user','$admin_pass','Y','',$tm,'Admin','','');",$dbh);
use lib '../../conf/';
require '../../conf/config.pl';
require "../../drivers/db_access.pl";

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
        EXPIRE LONG,
        FLAG CHAR(1),
        DATA MEMO
        )
TERMI
 sql_create_db($tab,$dbh);
$tab = << "TERMI";
 $sql_user_table (
        ID LONG,
        USER VARCHAR(50),
        PASSWORD VARCHAR(50),
        ACTIVE CHAR(1),
        DATA MEMO,
        CREATED LONG,
        FNAME VARCHAR(50),
        LNAME VARCHAR(50),
        EMAIL VARCHAR(120)
        )
TERMI
 sql_create_db($tab,$dbh);
 my $tm = time();
 # sql_query("insert into $sql_user_table values(NULL,'$admin_user','$admin_pass','Y','',$tm,'Admin','','');",$dbh);

# NOTE:  "ID" fields must be of type "AutoNumber"
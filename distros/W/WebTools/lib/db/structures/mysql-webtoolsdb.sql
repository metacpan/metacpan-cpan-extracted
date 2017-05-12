####################################
# Create DataBase structure!
# config_db_name - name of database
# setup it into config.pl!!!
# Usage:
# >mysql -u USER -p < this_file.SQL
####################################

create database webtoolsdb;   # Database is a good idea to be named on same way as it is in config.pl!
use webtoolsdb;

# There is session's records..
# S_ID is session ID string indentifying current session
# IP is IP address of visitor if only IP restriction mode were set!
# EXPIRE expiration time of session
# FLAG locking flag
# DATA user's data

create table webtools_sessions (
        ID BIGINT(1) not null auto_increment primary key,
        S_ID VARCHAR(255) binary not null,
        IP VARCHAR(20) binary default 'xxx.xxx.xxx.xxx',
        EXPIRE DATETIME not null,
        FLAG char(1) binary default '0',
        DATA longblob
        );

# USER - user name (case sensetive)
# PASSWORD - it's password
# DATA private user's data
# TODO: filed EXPIRE (expiration of account)

create table webtools_users (
        ID INT(1) not null auto_increment primary key,
        USER VARCHAR(50) binary not null,
        PASSWORD VARCHAR(50) binary default '',
        ACTIVE CHAR(1),
        DATA longblob,
        CREATED DATETIME not null,
        FNAME VARCHAR(50),
        LNAME VARCHAR(50),
        EMAIL VARCHAR(120),
        unique(USER)
        );

# Default user of system: Must be changed!
insert into webtools_users values(NULL,'admin','adminpassword','Y','',NOW(),'Admin','','');


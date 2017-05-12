-- ========================================================================
-- mysql SQL DDL Script File
-- ========================================================================

-- You can dump this into mysql with a command like this:
-- cat mysql_schema.sql | mysql -u youruser -p -h localhost yourdbname

-- Your database and database user must already be setup. See the 
-- mysql documentation for more information.

-- sessions
create table sessions (
  username                  varchar(127) not null,
  address                   varchar(255),
  ticket                    varchar(255),
  point                     varchar(255)
);
create index idx_sessions on sessions (username);

-- Users
create table Users (
  uid                       int not null auto_increment,
  login                     varchar(255) not null,
  passwd                    varchar(255) not null,
  Disabled                  char(1) default '0',
  constraint pk_Users primary key (uid)
) ;
create index idx_users on Users (login) ;

-- Groups
create table Groups (
  gid                       int not null auto_increment,
  Name                      char(31) not null,
  constraint pk_Groups primary key (gid)
) ;

-- UserGroups
create table UserGroups (
  gid                       int not null,
  uid                       int not null,
  accessbit                 char(1) default '0' not null,
  constraint pk_UserGroups primary key (gid,uid)
) ;


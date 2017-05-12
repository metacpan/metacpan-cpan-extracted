
#Create database
DROP DATABASE IF EXISTS $database;
CREATE DATABASE $database DEFAULT CHARACTER SET utf8;
USE $database;

#Creating MySQL tables
#All tables use UTF-8
#
#Summary tables '^'=primary key, '*'=key:
#TABLE hdb: recordid^, type, dates, server, title, ip, ...
#TABLE links: recordid*, mynetlocid*, urlid*, netlocid*, linktype, anchor  (netlocid for urlid!!)
#TABLE meta: recordid*,  name, value
#TABLE html: recordid^, html
#TABLE analys: recordid*, name, value
#TABLE topic: recordid*, notation*, absscore, relscore, terms, algorithm
#TABLE localtags: netlocid, urlid, name, value
#TABLE search: recordid^, stext*
#
#(TABLE netlocalias: netlocid*, netlocstr^)
#(TABLE urlalias: urlid*, urlstr^)
#TABLE topichierarchy: node^, father*, notation*, caption, level
#TABLE netlocs: netlocid^, netlocstr^, retries
#TABLE urls: netlocid*, urlid^, urlstr^, path
#TABLE urldb: netlocid*, urlid^, urllock, harvest*, retries, netloclock
#TABLE newlinks urlid^, netlocid
#TABLE recordurl: recordid*, urlid^, lastchecked, md5*, fingerprint*^
#TABLE admin: status, queid, schedulealgorithm
#TABLE log: pid, id, date, message
#TABLE que: queid^, urlid, netlocid
#TABLE robotrules: netlocid*, rule, expire
#TABLE oai: recordid, md5^, date*, status
#TABLE exports: host, port, last

#Data tables
CREATE TABLE hdb (
  recordid int(11) NOT NULL default '0',
  type varchar(50) default NULL,
  title text,
  mdate timestamp NOT NULL,
  expiredate datetime default NULL,
  length int(11) default NULL,
  server varchar(50) default NULL,
  etag varchar(25) default NULL,
  nheadings int(11) default NULL,
  nlinks int(11) default NULL,
  headings mediumtext,
  ip mediumblob,
  PRIMARY KEY  (recordid)
) ENGINE=MyISAM AVG_ROW_LENGTH = 20000 MAX_ROWS = 10000000 DEFAULT CHARACTER SET=utf8;

CREATE TABLE html (
  recordid int(11) NOT NULL default '0',
  html mediumblob,
  PRIMARY KEY  (recordid)
) ENGINE=MyISAM AVG_ROW_LENGTH = 20000 MAX_ROWS = 10000000 DEFAULT CHARACTER SET=utf8;

CREATE TABLE links (
  recordid int(11) NOT NULL default '0',
  mynetlocid int(11) default NULL,
  urlid int(11) default NULL,
  netlocid int(11) default NULL,
  anchor text,
  linktype varchar(50) default NULL,
  KEY recordid (recordid),
  KEY urlid (urlid),
  KEY mynetlocid (mynetlocid),
  KEY netlocid (netlocid)
) ENGINE=MyISAM MAX_ROWS = 1000000000 DEFAULT CHARACTER SET=utf8;

CREATE TABLE meta (
  recordid int(11) NOT NULL default '0',
  name varchar(50) default NULL,
  value text,
  KEY recordid (recordid)
) ENGINE=MyISAM MAX_ROWS = 1000000000 DEFAULT CHARACTER SET=utf8;

CREATE TABLE analys (
  recordid int(11) NOT NULL default '0',
  name varchar(100) NOT NULL,
  value varchar(100),
  KEY recordid (recordid)
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE topic (
  recordid int(11) NOT NULL default '0',
  notation varchar(50) default NULL,
  abscore int(11) default NULL,
  relscore int(11) default NULL,
  terms text default NULL,
  algorithm varchar(25),
  KEY notation (notation),
  KEY recordid (recordid)
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE localtags (
  netlocid int(11) NOT NULL DEFAULT '0',
  urlid int(11) NOT NULL DEFAULT '0',
  name varchar(100) NOT NULL,
  value varchar(100) NOT NULL,
  PRIMARY KEY tag (netlocid,urlid,name(100),value(100))
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE search (
  recordid int(11) NOT NULL default '0',
  stext mediumtext,
  PRIMARY KEY (recordid),
  FULLTEXT (stext)
) ENGINE=MyISAM AVG_ROW_LENGTH = 20000 MAX_ROWS = 10000000 DEFAULT CHARACTER SET=utf8;


#Administrative tables
CREATE TABLE netlocalias (
  netlocid int(11),
  netlocstr varchar(150) NOT NULL,
  KEY netlocid (netlocid),
  PRIMARY KEY netlocstr (netlocstr)
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE urlalias (
  urlid int(11),
  urlstr tinytext,
  KEY urlid (urlid),
  PRIMARY KEY urlstr (urlstr(255))
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

#topichierarchy have to initialized manually
CREATE TABLE topichierarchy (
  node int(11) NOT NULL DEFAULT '0',
  father int(11) DEFAULT NULL,
  notation varchar(50) NOT NULL DEFAULT '',
  caption varchar(255) DEFAULT NULL,
  level int(11) DEFAULT NULL,
  PRIMARY KEY node (node),
  KEY father (father),
  KEY notation (notation)
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE netlocs (
  netlocid int(11) NOT NULL auto_increment,
  netlocstr varchar(150) NOT NULL,
  retries int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (netlocstr),
  UNIQUE INDEX netlockid (netlocid)
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE urls (
  netlocid int(11) NOT NULL DEFAULT '0',
  urlid int(11) NOT NULL auto_increment,
  urlstr tinytext,
  path tinytext,
  PRIMARY KEY urlstr (urlstr(255)),
  INDEX netlocid (netlocid),
  UNIQUE INDEX urlid (urlid)
) ENGINE=MyISAM MAX_ROWS = 1000000000 DEFAULT CHARACTER SET=utf8;

CREATE TABLE urldb (
  netlocid int(11) NOT NULL default '0',
  netloclock int(11) NOT NULL default '0',
  urlid int(11) NOT NULL default '0',
  urllock int(11) NOT NULL default '0',
  harvest tinyint(1) NOT NULL default '0',
  retries int(11) NOT NULL default '0',
  score int(11) NOT NULL default '0',
  PRIMARY KEY  (urlid),
  KEY netlocid (netlocid),
  KEY harvest (harvest)
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE newlinks (
  urlid int(11) NOT NULL,
  netlocid int(11) NOT NULL,
  PRIMARY KEY  (urlid)
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE recordurl (
  recordid int(11) NOT NULL auto_increment,
  urlid int(11) NOT NULL default '0',
  lastchecked timestamp NOT NULL,
  md5 char(32),
  fingerprint char(50),
  KEY md5 (md5),
  KEY fingerprint (fingerprint),
  PRIMARY KEY (urlid),
  KEY recordid (recordid)
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE admin (
  status enum('closed','open','paused','stopped') default NULL,
  schedulealgorithm enum('default','bigdefault','advanced') default 'default',
  queid int(11) NOT NULL default '0'
) ENGINE=MEMORY DEFAULT CHARACTER SET=utf8;

#advanced means use config variable SchedulingAlgorithm
#Initialise admin to 'open' status
INSERT INTO admin VALUES ('open','default',0)
CREATE TABLE log (
  pid int(11) NOT NULL default '0',
  id varchar(50) default NULL,
  date timestamp NOT NULL,
  message varchar(255) default NULL
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE que (
  netlocid int(11) NOT NULL default '0',
  urlid int(11) NOT NULL default '0',
  queid int(11) NOT NULL auto_increment,
  PRIMARY KEY  (queid)
) ENGINE=MEMORY DEFAULT CHARACTER SET=utf8;

CREATE TABLE robotrules (
  netlocid int(11) NOT NULL default '0',
  expire int(11) NOT NULL default '0',
  rule varchar(255) default '',
  KEY netlocid (netlocid)
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE oai (
  recordid int(11) NOT NULL default '0',
  md5 char(32),
  date timestamp,
  status enum('created', 'updated', 'deleted'),
  PRIMARY KEY (md5),
  KEY date (date)
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;

CREATE TABLE exports (
  host varchar(30),
  port int,
  last timestamp DEFAULT '1999-12-31'
) ENGINE=MyISAM DEFAULT CHARACTER SET=utf8;


#Create user dbuser with required priviligies
GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,
   ALTER,LOCK TABLES ON $database.* TO $dbuser;

GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,
   ALTER,LOCK TABLES ON $database.* TO $dbuser\@localhost;


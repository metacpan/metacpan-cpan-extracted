CREATE TABLE types (
  type			varchar(32) NOT NULL,
  description		varchar(128),
  PRIMARY KEY (type)
);

CREATE TABLE blocks (
  blockname		varchar(32) NOT NULL,
  title			varchar(64),
  description		text,
  body			mediumtext,
  PRIMARY KEY (blockname)
);

CREATE TABLE groups (
  groupname		varchar(32) NOT NULL,
  type			varchar(32),
  title			varchar(64),
  description		text,
  date			datetime default '0000-00-00 00:00:00',
  PRIMARY KEY (groupname)
);

CREATE TABLE group2item (
  groupname		varchar(32) NOT NULL,
  itemname		varchar(32) NOT NULL,
  PRIMARY KEY (groupname,itemname)
);

CREATE TABLE items (
  itemname		varchar(32) NOT NULL,
  type			varchar(32),
  title			varchar(255),
  description		text,
  author_name		varchar(64),
  author_email		varchar(64),
  date			datetime default '0000-00-00 00:00:00',
  body			mediumtext,
  PRIMARY KEY (itemname),
  FULLTEXT (type,title,description,author_name,author_email,body)
);

CREATE TABLE item2multimedia (
  itemname		varchar(32) NOT NULL,
  multimedianame	varchar(32) NOT NULL,
  number		smallint(5) unsigned NOT NULL auto_increment,
  PRIMARY KEY (itemname,number)
);

CREATE TABLE multimedia (
  multimedianame	varchar(32) NOT NULL,
  type			varchar(32),
  title			varchar(128),
  description		text,
  date			datetime default '0000-00-00 00:00:00',
  mime_type		varchar(128),
  location		varchar(128),
  thumbnail		varchar(128),
  author_name		varchar(64),
  author_email		varchar(64),
  PRIMARY KEY (multimedianame)
);

CREATE TABLE users (
  username		varchar(32) NOT NULL,
  pwd			varchar(32),
  PRIMARY KEY (username)
);

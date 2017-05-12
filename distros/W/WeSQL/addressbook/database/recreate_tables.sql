create table logins (
	pkey bigint(20) unsigned not null auto_increment,
	id bigint(20) unsigned not null,

	uid bigint(20) unsigned not null,
	suid bigint(20) unsigned not NULL default '0',
	epoch bigint unsigned not null,
	status tinyint default '1' NOT NULL,

	userid bigint(20) unsigned not null,
	hash varchar(16) default '' not null,
	primary key (pkey)
);

create table sessions (
	pkey bigint(20) unsigned not null auto_increment,
	id bigint(20) unsigned not null,

	uid bigint(20) unsigned not null,
	suid bigint(20) unsigned not NULL default '0',
	epoch bigint unsigned not null,
	status tinyint default '1' NOT NULL,

	hash varchar(16) default '' not null,
	primary key (pkey)
);

create table sessiondata (
	pkey bigint(20) unsigned not null auto_increment,
	id bigint(20) unsigned not null,

	uid bigint(20) unsigned not null,
	suid bigint(20) unsigned not NULL default '0',
	epoch bigint unsigned not null,
	status tinyint default '1' NOT NULL,

	sessionid bigint(20) unsigned not null,
	name varchar(50) default '' not null,
	value text default '' not null,
	primary key (pkey)
);

create table users (
	pkey bigint(20) unsigned not null auto_increment,
	id bigint(20) unsigned not null,

	uid bigint(20) unsigned not null,
	suid bigint(20) unsigned not NULL default '0',
	epoch bigint unsigned not null,
	status tinyint default '1' NOT NULL,
	active tinyint default '1' NOT NULL,

	login varchar(50) default '' not null,
	password varchar(50) default '' not null,
	superuser tinyint default '0' NOT NULL,
	primary key (pkey)
);

create table people (
	pkey bigint(20) unsigned not null auto_increment,
	id bigint(20) unsigned not null,

	uid bigint(20) unsigned not null,
	suid bigint(20) unsigned not NULL default '0',
	epoch bigint unsigned not null,
	status tinyint default '1' NOT NULL,

	firstname varchar(50) default '' not null,
	lastname varchar(50) default '' not null,
	mobile varchar(50) default '' not null,
	email varchar(100) default '' not null,
	im varchar(200) default '' not null,
	birthday varchar(10) default '01-01-1970' not null,
	
	primary key (pkey)
);

create table addresses (
	pkey bigint(20) unsigned not null auto_increment,
	id bigint(20) unsigned not null,

	uid bigint(20) unsigned not null,
	suid bigint(20) unsigned not NULL default '0',
	epoch bigint unsigned not null,
	status tinyint default '1' NOT NULL,

	peopleid bigint(20) unsigned not NULL default '0',
	name varchar(100) DEFAULT '' NOT NULL,
	phone varchar(100) DEFAULT '' NOT NULL,
	fax varchar(100) DEFAULT '' NOT NULL,
	email varchar(100) default '' not null,
	street varchar(255) DEFAULT '' NOT NULL,
	number varchar(20) DEFAULT '' NOT NULL,
	adrs1 varchar(255) DEFAULT '' NOT NULL,
	adrs2 varchar(255) DEFAULT '' NOT NULL,
	zip varchar(20) DEFAULT '' NOT NULL,
	city varchar(100) DEFAULT '' NOT NULL,
	country varchar(100) DEFAULT '' NOT NULL,

	primary key (pkey)
);


CREATE TABLE `editor` (
  `id` int(11) NOT NULL auto_increment,
  `login` varchar(127) default NULL,
  `email` varchar(255) default NULL,
  `name` varchar(255) default NULL,
  `active` tinyint(1) default '1',
  PRIMARY KEY  (`id`)
) DEFAULT CHARSET=utf8;

CREATE TABLE `keyword2message` (
  `keyword_id` int(11) NOT NULL,
  `message_id` int(11) NOT NULL,
  `id` int(11) NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  KEY `keyword_id_key` (`keyword_id`),
  KEY `message_id_key` (`message_id`)
) DEFAULT CHARSET=utf8;

CREATE TABLE `keywords` (
  `id` int(11) NOT NULL auto_increment,
  `keyword` varchar(255) default NULL,
  `uri` varchar(255) default '',
  PRIMARY KEY  (`id`),
  KEY `i_keyword_uri` (`uri`)
) DEFAULT CHARSET=utf8;

CREATE TABLE `message` (
  `id` int(11) NOT NULL auto_increment,
  `uri` varchar(255) default NULL,
  `title` text,
  `content` text,
  `date` datetime default NULL,
  `is_published` tinyint(1) default '0',
  `site_id` int(11) default '1',
  `editor_id` int(11) default NULL,
  `modified` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `i_message_uri` (`uri`),
  KEY `i_published_message` (`is_published`,`site_id`,`uri`),
  FULLTEXT KEY `content` (`content`,`title`)
) DEFAULT CHARSET=utf8;

CREATE TABLE `word` (
  `id` int(11) NOT NULL auto_increment,
  `word` varchar(50) default NULL,
  `frequency` int(11) default '1',
  PRIMARY KEY  (`id`),
  KEY `i_word` (`word`)
) DEFAULT CHARSET=utf8;

CREATE TABLE `word2message` (
  `word_id` int(11) default NULL,
  `message_id` int(11) default NULL,
  KEY `i_word_message` (`message_id`)
) DEFAULT CHARSET=utf8;

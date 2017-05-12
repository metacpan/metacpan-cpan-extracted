-- MySQL dump 10.8
--
-- Host: localhost    Database: corpus
-- ------------------------------------------------------
-- Server version	4.1.7-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE="NO_AUTO_VALUE_ON_ZERO" */;

--
-- Table structure for table `algorithms`
--

DROP TABLE IF EXISTS `algorithms`;
CREATE TABLE `algorithms` (
  `algorithm_id` int(8) NOT NULL auto_increment,
  `algorithm_name` varchar(24) NOT NULL default '',
  PRIMARY KEY  (`algorithm_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `algorithms`
--


/*!40000 ALTER TABLE `algorithms` DISABLE KEYS */;
LOCK TABLES `algorithms` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `algorithms` ENABLE KEYS */;

--
-- Table structure for table `analysis_protocols`
--

DROP TABLE IF EXISTS `analysis_protocols`;
CREATE TABLE `analysis_protocols` (
  `analysis_protocol_id` int(8) NOT NULL auto_increment,
  `analysis_version_id` int(8) NOT NULL default '0',
  `protocol_id` int(8) NOT NULL default '0',
  `index` int(2) NOT NULL default '0',
  PRIMARY KEY  (`analysis_protocol_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `analysis_protocols`
--


/*!40000 ALTER TABLE `analysis_protocols` DISABLE KEYS */;
LOCK TABLES `analysis_protocols` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `analysis_protocols` ENABLE KEYS */;

--
-- Table structure for table `analysis_versions`
--

DROP TABLE IF EXISTS `analysis_versions`;
CREATE TABLE `analysis_versions` (
  `analysis_version_id` int(8) NOT NULL auto_increment,
  `analysis_version` varchar(24) NOT NULL default '',
  PRIMARY KEY  (`analysis_version_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `analysis_versions`
--


/*!40000 ALTER TABLE `analysis_versions` DISABLE KEYS */;
LOCK TABLES `analysis_versions` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `analysis_versions` ENABLE KEYS */;

--
-- Table structure for table `corpus_types`
--

DROP TABLE IF EXISTS `corpus_types`;
CREATE TABLE `corpus_types` (
  `corpus_type_id` int(8) NOT NULL auto_increment,
  `corpus_type_name` varchar(24) NOT NULL default '',
  PRIMARY KEY  (`corpus_type_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `corpus_types`
--


/*!40000 ALTER TABLE `corpus_types` DISABLE KEYS */;
LOCK TABLES `corpus_types` WRITE;
INSERT INTO `corpus_types` VALUES (1,'Development');
UNLOCK TABLES;
/*!40000 ALTER TABLE `corpus_types` ENABLE KEYS */;

--
-- Table structure for table `corpus_versions`
--

DROP TABLE IF EXISTS `corpus_versions`;
CREATE TABLE `corpus_versions` (
  `corpus_version_id` int(8) NOT NULL auto_increment,
  `corpus_version_name` varchar(24) NOT NULL default '',
  `run_by_user_id` int(8) NOT NULL default '0',
  `total_documents` int(8) NOT NULL default '0',
  `start_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  `end_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`corpus_version_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `corpus_versions`
--


/*!40000 ALTER TABLE `corpus_versions` DISABLE KEYS */;
LOCK TABLES `corpus_versions` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `corpus_versions` ENABLE KEYS */;

--
-- Table structure for table `corpuses`
--

DROP TABLE IF EXISTS `corpuses`;
CREATE TABLE `corpuses` (
  `corpus_id` int(8) NOT NULL auto_increment,
  `corpus_type_id` int(8) NOT NULL default '0',
  `corpus_name` varchar(24) NOT NULL default '',
  `corpus_desc` blob,
  `corpus_path` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`corpus_id`),
  UNIQUE KEY `namendx` (`corpus_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `corpuses`
--


/*!40000 ALTER TABLE `corpuses` DISABLE KEYS */;
LOCK TABLES `corpuses` WRITE;
INSERT INTO `corpuses` VALUES (1,1,'Dev','Dev','/home/roger/projects/corpus/corpus_1'),(107,0,'Test','Shorter','/home/roger/projects/corpus/corpus_107'),(111,0,'Test99','Test 99','/home/roger/projects/corpus/corpus_111');
UNLOCK TABLES;
/*!40000 ALTER TABLE `corpuses` ENABLE KEYS */;

--
-- Table structure for table `document_types`
--

DROP TABLE IF EXISTS `document_types`;
CREATE TABLE `document_types` (
  `document_type_id` int(8) NOT NULL auto_increment,
  `document_type_name` varchar(24) NOT NULL default '',
  PRIMARY KEY  (`document_type_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `document_types`
--


/*!40000 ALTER TABLE `document_types` DISABLE KEYS */;
LOCK TABLES `document_types` WRITE;
INSERT INTO `document_types` VALUES (1,'txt'),(2,'xml'),(3,'pdf');
UNLOCK TABLES;
/*!40000 ALTER TABLE `document_types` ENABLE KEYS */;

--
-- Table structure for table `documents`
--

DROP TABLE IF EXISTS `documents`;
CREATE TABLE `documents` (
  `document_id` int(8) NOT NULL auto_increment,
  `document_type_id` int(8) NOT NULL default '1',
  `corpus_id` int(8) NOT NULL default '0',
  `document_title` varchar(255) default NULL,
  `document_path` varchar(255) NOT NULL default '',
  `document_file_name` varchar(255) NOT NULL default '',
  `compressed_file_name` varchar(255) default NULL,
  `bytes` int(16) NOT NULL default '0',
  `compressed_bytes` int(16) default NULL,
  `enter_date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`document_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `documents`
--


/*!40000 ALTER TABLE `documents` DISABLE KEYS */;
LOCK TABLES `documents` WRITE;
INSERT INTO `documents` VALUES (1,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:29:51'),(2,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:31:06'),(3,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:48:53'),(4,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:49:01'),(5,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:49:51'),(6,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:50:52'),(7,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:52:30'),(8,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:52:43'),(9,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:53:16'),(10,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:58:47'),(11,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:59:12'),(12,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-12 23:59:42'),(13,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-13 00:00:10'),(14,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-13 00:00:31'),(15,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-13 00:00:36'),(16,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-13 00:00:43'),(17,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-13 00:17:18'),(18,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-13 00:31:32'),(19,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2008-12-13 01:05:56'),(20,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-04 21:26:03'),(21,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-05 09:40:40'),(22,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-05 09:42:06'),(23,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2009-03-05 09:44:07'),(24,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-05 09:47:06'),(25,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-05 09:50:21'),(26,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-05 09:50:32'),(27,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-05 09:53:15'),(28,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-05 10:06:36'),(29,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-05 10:08:44'),(30,1,61,NULL,'testing','testing',NULL,14042,NULL,'2009-03-05 15:42:42'),(31,1,62,NULL,'testing','testing',NULL,14042,NULL,'2009-03-05 15:46:17'),(48,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-05 16:07:12'),(49,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2009-03-05 16:07:21'),(51,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-07 01:19:21'),(52,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,16384,NULL,'2009-03-07 01:19:50'),(53,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2009-03-07 01:19:54'),(54,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2009-03-07 01:26:22'),(55,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2009-03-07 01:45:23'),(56,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2009-03-07 01:55:04'),(57,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2009-03-07 01:56:19'),(58,1,1,NULL,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2009-03-07 01:57:14'),(59,1,1,NULL,'','modules',NULL,0,NULL,'2009-03-10 14:13:18'),(60,1,1,NULL,'modules','modules',NULL,0,NULL,'2009-03-10 15:17:42'),(61,1,1,NULL,'modules','modules',NULL,2301,NULL,'2009-03-10 15:19:31'),(62,1,1,NULL,'/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 15:22:46'),(63,1,1,'Modules','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 15:24:00'),(64,1,107,'Modules 2','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 15:24:27'),(65,1,107,'Modules 3','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 15:24:44'),(66,1,1,'','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 15:30:48'),(67,1,1,'Modules','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 15:33:41'),(68,1,1,'Modules 5','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 15:34:06'),(69,1,1,'Modules','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 15:38:04'),(70,1,1,'Modules','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 15:54:38'),(71,1,1,'Modules','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 15:57:09'),(72,1,1,'Modules','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 16:00:28'),(73,1,1,'Moduels 12','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 16:00:40'),(74,1,1,'T102VT1021;2c1;2c1;2cVT102VT102VT102VT1021;2c1;2cVT102VT102VT102VT1021;2c1;2cVT102VT1021;2c1;2c1;2c1;2cVT102VT1021;2c1;2cVT1021;2c1;2cVT1021;2c1;2c1;2c1;2cVT1021;2c1;2cVT1021;2cVT1021;2cVT102VT102VT1021;2c1;2c1;2cVT1021;2cVT1021;2cVT102VT102VT102VT102VT10','/home/roger/perl/text/Text-AL.tar.gz','Text-AL.tar.gz',NULL,13108,NULL,'2009-03-10 16:39:59'),(75,1,1,'TAR','/home/roger/perl/text/Text-AL.tar.gz','Text-AL.tar.gz',NULL,13108,NULL,'2009-03-10 16:41:40'),(76,1,1,'adfsafd','/home/roger/perl/text/modules','modules',NULL,2301,NULL,'2009-03-10 16:42:13'),(77,1,1,'Fours','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 16:47:58'),(78,1,1,'Fours 2','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 17:05:56'),(79,1,1,'Fours 3','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 17:06:27'),(80,1,1,'Forus 4','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 17:07:54'),(81,1,1,'Fours 5','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 17:09:34'),(82,1,1,'Fours 7','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 17:21:54'),(83,1,1,'Fours 8','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 17:22:56'),(84,1,1,'Fours 9','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 18:15:46'),(85,1,1,'Fours 10','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:03:35'),(86,1,1,'Fours','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:05:49'),(87,1,1,'Fours 11','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:07:59'),(88,1,1,'','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:08:47'),(89,1,1,'adfa','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:08:54'),(90,1,1,'fours 12','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:11:01'),(91,1,1,'13','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:13:00'),(92,1,1,'fsadf','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:14:32'),(93,1,1,'13','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:15:20'),(94,1,1,'dfad','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:16:13'),(95,1,1,'14','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-10 19:20:24'),(96,1,1,'Fours 15','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-11 09:11:17'),(97,1,1,'fours 16','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-11 09:20:57'),(98,1,1,'fours 17','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-11 09:49:09'),(99,1,1,'fours 18','/home/roger/fours','fours',NULL,17695,NULL,'2009-03-11 09:52:19');
UNLOCK TABLES;
/*!40000 ALTER TABLE `documents` ENABLE KEYS */;

--
-- Table structure for table `protocol_algorithms`
--

DROP TABLE IF EXISTS `protocol_algorithms`;
CREATE TABLE `protocol_algorithms` (
  `protocol_algorithm_id` int(8) NOT NULL auto_increment,
  `protocol_id` int(8) NOT NULL default '0',
  `algorithm_id` int(8) NOT NULL default '0',
  `index` int(2) NOT NULL default '0',
  PRIMARY KEY  (`protocol_algorithm_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `protocol_algorithms`
--


/*!40000 ALTER TABLE `protocol_algorithms` DISABLE KEYS */;
LOCK TABLES `protocol_algorithms` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `protocol_algorithms` ENABLE KEYS */;

--
-- Table structure for table `protocols`
--

DROP TABLE IF EXISTS `protocols`;
CREATE TABLE `protocols` (
  `protocol_id` int(8) NOT NULL auto_increment,
  `protocol_name` varchar(24) NOT NULL default '',
  PRIMARY KEY  (`protocol_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `protocols`
--


/*!40000 ALTER TABLE `protocols` DISABLE KEYS */;
LOCK TABLES `protocols` WRITE;
UNLOCK TABLES;
/*!40000 ALTER TABLE `protocols` ENABLE KEYS */;

--
-- Table structure for table `submitted_documents`
--

DROP TABLE IF EXISTS `submitted_documents`;
CREATE TABLE `submitted_documents` (
  `submitted_document_id` int(8) NOT NULL auto_increment,
  `submitted_url_id` int(8) default NULL,
  `corpus_id` int(8) NOT NULL default '0',
  `submitted_by_user_id` int(8) NOT NULL default '0',
  `document_path` varchar(255) NOT NULL default '',
  `document_file_name` varchar(255) NOT NULL default '',
  `compressed_file_name` varchar(255) default NULL,
  `bytes` int(16) NOT NULL default '0',
  `compressed_bytes` int(16) default NULL,
  `enter_date` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `exit_date` timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`submitted_document_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `submitted_documents`
--


/*!40000 ALTER TABLE `submitted_documents` DISABLE KEYS */;
LOCK TABLES `submitted_documents` WRITE;
INSERT INTO `submitted_documents` VALUES (12,NULL,1,1,'/home/roger/projects/corpus','Test Corpus',NULL,12384,NULL,'2008-12-13 00:12:57','0000-00-00 00:00:00'),(13,NULL,1,1,'/home/roger/projects/corpus','Test Corpus',NULL,12384,NULL,'2008-12-13 00:14:27','0000-00-00 00:00:00'),(14,NULL,1,1,'/home/roger/projects/corpus','Test Corpus',NULL,12384,NULL,'2008-12-13 00:14:41','0000-00-00 00:00:00'),(15,NULL,1,1,'/home/roger/projects/corpus','Test Corpus',NULL,12384,NULL,'2008-12-13 00:16:16','0000-00-00 00:00:00'),(16,NULL,1,1,'/home/roger/projects/corpus','Test Corpus',NULL,12384,NULL,'2008-12-13 00:16:33','0000-00-00 00:00:00'),(17,NULL,1,1,'/home/roger/projects/corpus','Test Corpus',NULL,12384,NULL,'2008-12-13 00:16:42','0000-00-00 00:00:00'),(18,NULL,1,1,'/home/roger/projects/corpus','Test Corpus',NULL,12384,NULL,'2008-12-13 00:17:18','0000-00-00 00:00:00'),(24,NULL,1,0,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2008-12-13 00:31:32','0000-00-00 00:00:00'),(26,NULL,1,0,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2008-12-13 01:06:04','0000-00-00 00:00:00'),(30,NULL,1,0,'/home/roger/projects/corpus','Test Corpus',NULL,0,NULL,'2009-03-05 09:40:47','0000-00-00 00:00:00');
UNLOCK TABLES;
/*!40000 ALTER TABLE `submitted_documents` ENABLE KEYS */;





DROP TABLE IF EXISTS `document_tokens`;
CREATE TABLE `document_tokens` (
  `document_token_id` int(8) NOT NULL auto_increment,
  `document_token_name` varchar(24) NOT NULL default '',
  PRIMARY KEY  (`document_token_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `token_temps`;
DROP TABLE IF EXISTS `tokens_temp`;
CREATE TABLE `tokens_temp` (
  `token_temp_id` int(8) NOT NULL auto_increment,
  `document_id` int(8),
  `token` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`token_temp_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;


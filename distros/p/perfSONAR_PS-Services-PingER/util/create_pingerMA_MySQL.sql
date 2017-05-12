#
#  pinger beacons ( basically everything about Beacon site  )
#     
#     alias is an alias of the site name  for pingtables ( something like FNAL.GOV for pinger.fnal.gov)
#     dataurl is URL to ping_data.pl CGI sciprt for now, then LS will take over this function
#     traceurl is URL to traceroute.pl CGI sciprt for now, then LS will take over this function
#    
#   Notes: tinyint(1) is used for boolean ( since some DB lacks support for boolean type)
#          If DB supports serial ( auto_increment ) type then all primary keys named as xxx_id should be 
#          changed to serial ( auto_increment)
#  
#
# 
#
CREATE  TABLE beacons (
  ip_name varchar(52) NOT NULL,
  alias    varchar(20),   
  address_id   int,   
  website  varchar(100),
  dataurl  varchar(100),
  traceurl  varchar(100),
  longitude  float,
  latitude  float,
  contact_id int, 
  updated timestamp,
  FOREIGN KEY ( contact_id) references contacts ( contact_id), 
  FOREIGN KEY ( address_id) references address  (  address_id), 
  PRIMARY KEY (ip_name)); 
#
#   the full address of the site , could be couple of sites per address
#
CREATE  TABLE address (
  address_id  int AUTO_INCREMENT,
  institution  varchar(100),
  address_line varchar(200),
  city  varchar(50),
  country  varchar(50),
  region_id  smallint,
  FOREIGN KEY ( region_id) references  regions( region_id), 
  PRIMARY KEY (address_id));

#
#   each site can be assigned to some region of the world( Asia, Europe, North_America etc)
#
CREATE TABLE regions (
  region_id  smallint AUTO_INCREMENT,
  name varchar(20),
  PRIMARY KEY (region_id));
#
#   each site can have multiple contact names and addresses
#
CREATE TABLE contacts (
  contact_id int AUTO_INCREMENT,
  person varchar(100),
  email varchar(100),
  PRIMARY KEY (contact_id));
# 
# ------------------------------------The part above is for beacons and pinger website ( means administering tasks)--
#
#----------------------------------------------- The part below is for collection and pinger MA----------------------
#
# ipaddr  table to keep track on what ip address was assigned with pinger hostname
#   ip_number has length of 64 - to accomodate possible IPv6 
#
CREATE TABLE host (
 ip_name varchar(52) NOT NULL, 
 ip_number varchar(64) NOT NULL,
 comments text, 
 PRIMARY KEY  (ip_name, ip_number) );

#
#     meta data table ( [eriod is an interval, since interval is reserved word )
#
CREATE TABLE  metaData  (
 metaID BIGINT NOT NULL AUTO_INCREMENT,
 ip_name_src varchar(52) NOT NULL,
 ip_name_dst varchar(52) NOT NULL,
 transport varchar(10)  NOT NULL,
 packetSize smallint   NOT NULL,
 count smallint   NOT NULL,
 packetInterval smallint,
 deadline smallint,
 ttl smallint,
 INDEX (ip_name_src, ip_name_dst, packetSize, count),
 FOREIGN KEY (ip_name_src) references host (ip_name),
 FOREIGN KEY (ip_name_dst) references host (ip_name),
 PRIMARY KEY  (metaID));


#
#   pinger data table, some fields have names differnt from XML schema since there where
#   inherited from the current pinger data table
#   its named data_yyyyMM to separate from old format - pairs_yyyyMM
#
CREATE TABLE  data  (
 metaID   BIGINT   NOT NULL,
 minRtt float,
 meanRtt float,
 medianRtt float,
 maxRtt float,
 timestamp bigint(12) NOT NULL,
 minIpd float,
 meanIpd float,
 maxIpd float,
 duplicates tinyint(1),
 outOfOrder  tinyint(1),
 clp float,
 iqrIpd float,
 lossPercent  float,
 rtts text, -- should be stored as csv of ping rtts
 seqNums text, -- should be stored as csv of ping sequence numbers
 INDEX (meanRtt, medianRtt, lossPercent, meanIpd, clp),
 FOREIGN KEY (metaID) references metaData (metaID),
 PRIMARY KEY  (metaID, timestamp));

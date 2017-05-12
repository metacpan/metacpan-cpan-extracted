--
--  pinger beacons ( basically everything about Beacon site  )
--     
--     alias is an alias of the site name  for pingtables ( something like FNAL.GOV for pinger.fnal.gov)
--     dataurl is URL to ping_data.pl CGI sciprt for now, then LS will take over this function
--     traceurl is URL to traceroute.pl CGI sciprt for now, then LS will take over this function
--    
--   Notes: tinyint(1) is used for boolean ( since some DB lacks support for boolean type)
--          If DB supports serial ( auto_increment ) type then all primary keys named as xxx_id should be 
--          changed to serial ( auto_increment)
--  
--
-- 
--

--
--   each site can be assigned to some region of the world( Asia, Europe, North_America etc)
--
CREATE TABLE regions (
  region_id  smallint,
  name varchar(20),
  PRIMARY KEY (region_id));
--
--   each site can have multiple contact names and addresses
--
CREATE TABLE contacts (
  contact_id int,
  person varchar(100),
  email varchar(100),
  PRIMARY KEY (contact_id));
-- 
-- ------------------------------------The part above is for beacons and pinger website ( means administering tasks)--
--

--
--   the full address of the site , could be couple of sites per address
--
CREATE  TABLE address (
  address_id  int,
  institution  varchar(100),
  address_line varchar(200),
  city  varchar(50),
  country  varchar(50),
  region_id  smallint,
  FOREIGN KEY ( region_id) references  regions( region_id), 
  PRIMARY KEY (address_id));

CREATE TRIGGER address_fki 
  BEFORE INSERT ON address FOR EACH ROW
  BEGIN
    SELECT RAISE(ROLLBACK, 'Insert on address violates foreign key on contact_id')
    WHERE 
      NEW.region_id IS NOT NULL 
      AND (SELECT region_id FROM regions WHERE region_id = NEW.region_id)
        IS NULL;
  END;

CREATE TRIGGER address_fku 
  BEFORE UPDATE ON address FOR EACH ROW
  BEGIN
    SELECT RAISE(ROLLBACK, 'Update on address violates foreign key on contact_id')
    WHERE 
      NEW.region_id IS NOT NULL
      AND (SELECT region_id FROM regions WHERE region_id = NEW.region_id)
        IS NULL;
END;

-------- List of beacon sites --------
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

CREATE TRIGGER beacons_fki 
  BEFORE INSERT ON beacons FOR EACH ROW 
  BEGIN
    SELECT RAISE(ROLLBACK, 'Insert on beacons violates foreign key on contact_id')
      WHERE 
        NEW.contact_id IS NOT NULL
        AND (SELECT contact_id FROM contacts WHERE contact_id = NEW.contact_id)
          IS NULL;
    SELECT RAISE(ROLLBACK, 'Insert on beacons violates foreign key on address_id')
      WHERE 
        NEW.address_id IS NOT NULL 
        AND (SELECT address_id FROM address WHERE address_id = NEW.address_id)
          IS NULL;
  END;

CREATE TRIGGER beacons_fku 
  BEFORE UPDATE ON beacons FOR EACH ROW 
  BEGIN
    SELECT RAISE(ROLLBACK, 'Update on beacons violates foreign key on contact_id')
      WHERE 
        NEW.contact_id IS NOT NULL 
        AND (SELECT contact_id FROM contacts WHERE contact_id = NEW.contact_id)
          IS NULL;
    SELECT RAISE(ROLLBACK, 'Update on beacons violates foreign key on address_id')
      WHERE 
        NEW.address_id IS NOT NULL
        AND (SELECT address_id FROM address WHERE address_id = NEW.address_id)
          IS NULL;
  END;

-- Prevent deletion of address and contact records in use by a beacon
CREATE TRIGGER address_fkd
  BEFORE DELETE ON address FOR EACH ROW
  BEGIN
    SELECT RAISE(ROLLBACK, 'Delete from contacts violates foreign key from beacon on address_id')
      WHERE (SELECT address_id from beacons where address_id = OLD.address_id)
        IS NULL;
  END; 

CREATE TRIGGER contacts_fkd
  BEFORE DELETE ON contacts FOR EACH ROW
  BEGIN
    SELECT RAISE(ROLLBACK, 'Delete from contacts violates foreign key from beacon on contact_id')
      WHERE (SELECT contact_id from beacons where contact_id = OLD.contact_id)
        IS NOT NULL;
  END; 

------------------------------------------------- The part below is for collection and pinger MA----------------------
--
-- ipaddr  table to keep track on what ip address was assigned with pinger hostname
--   ip_number has length of 64 - to accomodate possible IPv6 
--
CREATE TABLE host (
 ip_name varchar(52) NOT NULL, 
 ip_number varchar(64) NOT NULL,
 comments text, 
 PRIMARY KEY  (ip_name, ip_number) );


--
--     meta data table ( Period is an interval, since interval is reserved word )
--
CREATE TABLE  metaData  (
 metaID INTEGER PRIMARY KEY, 
 ip_name_src varchar(52) NOT NULL,
 ip_name_dst varchar(52) NOT NULL,
 transport varchar(10)  NOT NULL,
 packetSize smallint   NOT NULL,
 count smallint   NOT NULL,
 packetInterval smallint,
 deadline smallint,
 ttl smallint,
 -- INDEX (ip_name_src, ip_name_dst, packetSize, count),
 FOREIGN KEY (ip_name_src) references host (ip_name),
 FOREIGN KEY (ip_name_dst) references host (ip_name));

CREATE INDEX metaData_idx1 
  ON metaData (ip_name_src, ip_name_dst, packetSize, count);

CREATE TRIGGER metaData_fki
  BEFORE INSERT ON metaData FOR EACH ROW 
  BEGIN
    SELECT RAISE(ROLLBACK, 'Insert on metaData violates foreign key on ip_name_src')
      WHERE (SELECT ip_name FROM host WHERE ip_name = NEW.ip_name_src)
        IS NULL;
    SELECT RAISE(ROLLBACK, 'Insert on metaData violates foreign key on ip_name_dst')
      WHERE (SELECT ip_name FROM host WHERE ip_name = NEW.ip_name_dst)
        IS NULL;
  END;

CREATE TRIGGER metaData_fku 
  BEFORE UPDATE ON metaData FOR EACH ROW 
  BEGIN
    SELECT RAISE(ROLLBACK, 'Update on metaData violates foreign key on ip_name_src')
      WHERE (SELECT ip_name FROM host WHERE ip_name = NEW.ip_name_src)
        IS NULL;
    SELECT RAISE(ROLLBACK, 'Update on metaData violates foreign key on ip_name_dst')
      WHERE (SELECT ip_name FROM host WHERE ip_name = NEW.ip_name_dst)
        IS NULL;
  END;

-- Prevent deletion of host records in use by metaData
CREATE TRIGGER host_fkd
  BEFORE DELETE ON host FOR EACH ROW
  BEGIN
    SELECT RAISE(ROLLBACK, 'Delete from host violates foreign key from metaData.ip_name_src')
      WHERE (SELECT ip_name_src FROM metaData WHERE ip_name_src = OLD.ip_name) IS NOT NULL;
    SELECT RAISE(ROLLBACK, 'Delete from host violates foreign key from metaData.ip_name_dst')
      WHERE (SELECT ip_name_dst FROM metaData WHERE ip_name_dst = OLD.ip_name) IS NOT NULL;
  END;

--   pinger data table, some fields have names differnt from XML schema since there where
--   inherited from the current pinger data table
--   its named data_yyyyMM to separate from old format - pairs_yyyyMM
--
CREATE TABLE  data  (
  metaID   INTEGER,
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
  -- INDEX (meanRtt, medianRtt, lossPercent, meanIpd, clp),
  FOREIGN KEY (metaID) references metaData (metaID),
  PRIMARY KEY  (metaID, timestamp));

CREATE INDEX data_idx1 
  ON data (meanRtt,medianRtt, lossPercent, meanIpd, clp);

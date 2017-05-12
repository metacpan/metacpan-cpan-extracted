-- DSN : DBI:SQLite:dbname=test
--
-- XML::RDB SQL Generation 
-- XML file :  test.xml
-- SQL file :  test_schema.sql
--     date :  2009-09-22 07:50:50
-- 
-- TABLE_PREFIX : gen
--      PK_NAME : id
--      FK_NAME : fk
--   TEXT_WIDTH : 50
 
-------   ONE  to  MANY ------
------------------------------
--	address-book -> entry

-- Gerated Tables
---------------------------------
CREATE TABLE dbix_sequence_state (
  state_id integer   ,
  dataset varchar(50)   
);

CREATE TABLE gen_street (
  gen_street_value varchar(50)   ,
  id integer NOT NULL  ,
  PRIMARY KEY (id)
);

CREATE TABLE gen_root_n_pk (
  pk integer   ,
  root varchar(50)   
);

CREATE TABLE gen_state (
  gen_state_value varchar(50)   ,
  id integer NOT NULL  ,
  PRIMARY KEY (id)
);

CREATE TABLE gen_link_tables (
  one_table varchar(50) NOT NULL  ,
  many_table varchar(50) NOT NULL  
);

CREATE TABLE gen_element_names (
  db_name varchar(50) NOT NULL  ,
  xml_name varchar(50) NOT NULL  
);

CREATE TABLE gen_name (
  gen_name_value varchar(50)   ,
  gen_name_type_attribute varchar(50)   ,
  id integer NOT NULL  ,
  PRIMARY KEY (id)
);

CREATE TABLE dbix_sequence_release (
  released_id integer   ,
  dataset varchar(50)   ,
  id integer NOT NULL  ,
  PRIMARY KEY (id)
);

CREATE TABLE gen_address_book (
  gen_name_id integer   ,
  id integer NOT NULL  ,
  PRIMARY KEY (id)
);

CREATE TABLE gen_entry (
  gen_street_id integer   ,
  gen_name_id integer   ,
  gen_address_book_fk integer   ,
  gen_state_id integer   ,
  id integer NOT NULL  ,
  PRIMARY KEY (id)
);



-- Real XML element names mapping
---------------------------------
INSERT INTO gen_element_names VALUES ('gen_name','name');
INSERT INTO gen_element_names VALUES ('gen_street','street');
INSERT INTO gen_element_names VALUES ('gen_entry','entry');
INSERT INTO gen_element_names VALUES ('gen_address_book','address-book');
INSERT INTO gen_element_names VALUES ('gen_state','state');
INSERT INTO gen_element_names VALUES ('gen_name_type_attribute','type');

-- 1:N table relationship names
-------------------------------
INSERT INTO gen_link_tables VALUES ('gen_address_book','entry');

-- Flattened views of related tables
------------------------------------
-- SELECT 
--   gen_name.gen_name_type_attribute ,
--   gen_name.gen_name_value ,
--   gen_name.gen_name_type_attribute ,
--   gen_name.gen_name_value ,
--   gen_state.gen_state_value ,
--   gen_street.gen_street_value 
-- FROM 
--   (((((gen_address_book  
--        INNER JOIN gen_entry ON    gen_address_book.id = gen_entry.gen_address_book_fk ) 
--         LEFT JOIN gen_name ON   gen_address_book.gen_name_id = gen_name.id ) 
--         LEFT JOIN gen_name ON   gen_entry.gen_name_id = gen_name.id ) 
--         LEFT JOIN gen_state ON   gen_entry.gen_state_id = gen_state.id ) 
--         LEFT JOIN gen_street ON   gen_entry.gen_street_id = gen_street.id ) 
-- LIMIT 500;

-- SELECT 
--   gen_name.gen_name_type_attribute ,
--   gen_name.gen_name_value ,
--   gen_state.gen_state_value ,
--   gen_street.gen_street_value 
-- FROM 
--   (((gen_entry  
--       LEFT JOIN gen_name ON   gen_entry.gen_name_id = gen_name.id ) 
--       LEFT JOIN gen_state ON   gen_entry.gen_state_id = gen_state.id ) 
--       LEFT JOIN gen_street ON   gen_entry.gen_street_id = gen_street.id ) 
-- LIMIT 500;


-- Deploy example:contacts to sqlite

BEGIN;

CREATE TABLE contact (
  id INTEGER PRIMARY KEY NOT NULL,
  person_id integer NOT NULL,
  first_name varchar(24) NOT NULL,
  last_name varchar(48) NOT NULL,
  notes text,
  FOREIGN KEY (person_id) REFERENCES person(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE contact_email (
  id INTEGER PRIMARY KEY NOT NULL,
  contact_id integer NOT NULL,
  address varchar(96) NOT NULL,
  FOREIGN KEY (contact_id) REFERENCES contact(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE contact_phone (
  id INTEGER PRIMARY KEY NOT NULL,
  contact_id integer NOT NULL,
  phone_number varchar(96) NOT NULL,
  FOREIGN KEY (contact_id) REFERENCES contact(id) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMIT;

-- Convert schema '' to '':;

BEGIN;

CREATE TABLE credit_card (
  id INTEGER PRIMARY KEY NOT NULL,
  person_id integer NOT NULL,
  card_number varchar(20) NOT NULL,
  expiration date NOT NULL,
  FOREIGN KEY (person_id) REFERENCES person(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX credit_card_idx_person_id ON credit_card (person_id);

CREATE TABLE person (
  id INTEGER PRIMARY KEY NOT NULL,
  username varchar(48) NOT NULL,
  first_name varchar(24) NOT NULL,
  last_name varchar(48) NOT NULL,
  password varchar(64) NOT NULL
);

CREATE UNIQUE INDEX person_username ON person (username);

CREATE TABLE person_role (
  person_id integer NOT NULL,
  role_id integer NOT NULL,
  PRIMARY KEY (person_id, role_id),
  FOREIGN KEY (person_id) REFERENCES person(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (role_id) REFERENCES role(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX person_role_idx_person_id ON person_role (person_id);

CREATE INDEX person_role_idx_role_id ON person_role (role_id);

CREATE TABLE profile (
  id INTEGER PRIMARY KEY NOT NULL,
  person_id integer NOT NULL,
  state_id integer NOT NULL,
  address varchar(48) NOT NULL,
  city varchar(32) NOT NULL,
  zip varchar(5) NOT NULL,
  birthday date,
  phone_number varchar(32),
  FOREIGN KEY (person_id) REFERENCES state(id),
  FOREIGN KEY (state_id) REFERENCES state(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX profile_idx_person_id ON profile (person_id);

CREATE INDEX profile_idx_state_id ON profile (state_id);

CREATE UNIQUE INDEX profile_id_person_id ON profile (id, person_id);

CREATE TABLE role (
  id INTEGER PRIMARY KEY NOT NULL,
  label varchar(24) NOT NULL
);

CREATE UNIQUE INDEX role_label ON role (label);

CREATE TABLE state (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(24) NOT NULL,
  abbreviation varchar(24) NOT NULL
);

CREATE UNIQUE INDEX state_abbreviation ON state (abbreviation);

CREATE UNIQUE INDEX state_name ON state (name);


COMMIT;


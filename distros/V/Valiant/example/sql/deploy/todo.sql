-- Deploy example:todo to sqlite

BEGIN;

-- XXX Add DDLs here.

CREATE TABLE todo (
  id INTEGER PRIMARY KEY NOT NULL,
  person_id integer NOT NULL,
  title varchar(60) NOT NULL,
  status TEXT CHECK( status IN ('active','completed','archived') )   NOT NULL DEFAULT 'active',
  FOREIGN KEY (person_id) REFERENCES person(id) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMIT;

-- Deploy example:employment to sqlite

BEGIN;

CREATE TABLE employment (
  id INTEGER PRIMARY KEY NOT NULL,
  label varchar(48) NOT NULL
);

INSERT into employment(label) values('unemployed');
INSERT into employment(label) values('full-time');
INSERT into employment(label) values('part-time');
INSERT into employment(label) values('homemaker');

alter table profile ADD column employment_id INTEGER references employment(id);

COMMIT;

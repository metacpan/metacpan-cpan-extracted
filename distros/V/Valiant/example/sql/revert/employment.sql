-- Revert example:employment from sqlite

BEGIN;

ALTER TABLE profile DROP column employment_id;
DROP TABLE employment;

COMMIT;

-- Revert example:more_profile from sqlite

BEGIN;

-- XXX Add DDLs here.
alter table profile drop column status;
alter table profile drop column registered;
COMMIT;

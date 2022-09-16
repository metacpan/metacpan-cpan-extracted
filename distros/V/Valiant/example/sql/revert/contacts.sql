-- Revert example:contacts from sqlite

BEGIN;

drop table contact_email;
drop table contact_phone;
drop table contact;

COMMIT;

-- Deploy example:more_profile to sqlite

BEGIN;

-- XXX Add DDLs here.
alter table profile add column status TEXT CHECK( status IN ('active', 'pending', 'inactive') ) not null default 'pending';
alter table profile add column registered boolean not null default false;

COMMIT;

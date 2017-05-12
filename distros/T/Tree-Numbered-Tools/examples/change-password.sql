-- Run from the command line (assumes that the database 'test' already exists):
-- psql -q -U pgsql -d test -f change-password.sql
--
SET SESSION AUTHORIZATION 'pgsql';
SET search_path = "public", pg_catalog;
ALTER ROLE pgsql WITH PASSWORD 'kokmaB';
ALTER ROLE pgsql VALID UNTIL 'infinity';
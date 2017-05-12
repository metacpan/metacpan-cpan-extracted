-- Run from the command line (assumes that the database 'test' already exists):
-- psql -q -U pgsql -d test -f select-pgsql.sql
--
SET SESSION AUTHORIZATION 'pgsql';
SET search_path = "public", pg_catalog;
SELECT * FROM treetest ORDER BY serial;

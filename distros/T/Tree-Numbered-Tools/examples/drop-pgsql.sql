-- Run from the command line (assumes that the database 'test' already exists):
-- psql -q -U pgsql -d test -f drop-pgsql.sql
--
SET SESSION AUTHORIZATION 'pgsql';
SET search_path = "public", pg_catalog;
DROP TABLE treetest;

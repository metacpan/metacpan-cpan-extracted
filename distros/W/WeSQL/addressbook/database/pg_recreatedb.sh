#!/bin/sh
# Change the 'root' with any user that has dropdb and createdb privileges on your database.
# Alternatively, you can create a user 'root' with the command createuser -P root, after you've su'ed to the postgres user
# Please note that this script will only work with PostgreSQL v7.x! (RPMs and source available from postgresql.org)
dropdb addressbook -Uroot
createdb addressbook -Uroot
cat pg_recreate_tables.sql | psql -Uroot addressbook
cat pg_startdata.sql | psql -Uroot addressbook

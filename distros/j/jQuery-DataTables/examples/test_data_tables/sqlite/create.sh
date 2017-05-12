#!/bin/sh -
rm TestDataTables.db
perl -w create-init-script.pl TestDataTables.db

#!/bin/bash
# Simple script to import the hugo data in to a MySQL database
# It may require some tweaking


# Variables
SCRIPT_NAME="create_database.sh"
DBNAME="hugo"

if [ -n $3$2$1 ]; then 

	echo "Usage $SCRIPT_NAME <dbuser> <table sql file> <source data file>"
	exit -1
fi

echo "Creating database $DBNAME"
mysqladmin -u $1 -p create $DBNAME

echo "Creating tables via SQL Script $2"
mysql -u $1 < $2


echo "Importing data..."
mysqlimport -u $1 -p $DBNAME $3


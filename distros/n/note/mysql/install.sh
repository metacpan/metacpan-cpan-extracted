#!/bin/sh
# installs note
# This is the installer for the mysql version only!

echo "Welcome to note `cat ../VERSION` installation."
echo "the install script will ask you a view questions,"
echo "make sure to answer them correctly!"
echo

/bin/echo -n "creating the note database..."
NAME="_note"
DBNAME="$USER$NAME"
echo "DBNAME=$DBNAME"
mysqladmin create $DBNAME
echo "done."
/bin/echo -n "creating the table structure using defaults..."
mysql $DBNAME < sql

echo "Shall I try to install the required MySQL driver from CPAN?"
read YESNO

case $YESNO in
	"y" | "Y")
		if [ $(id -ru) != 0 ] ; then
			echo "You should be root for that!"
			exit
		fi 
		perl -MCPAN -e shell cpan> install mysql
		;;
esac
echo "done."



#!/bin/bash

if [ "$FLOWER_DB" == "Pg" ]; then
	echo Deleting, creating and populating the Pg flowers database
else
	if [ "$FLOWER_DB" == "SQLite" ]; then
		echo Deleting, creating and populating the SQLite flowers database
	else
		echo "Env var FLOWER_DB must match /^(Pg|SQLite)\$/"

		exit 1
	fi
fi

cp /dev/null log/development.log

perl -Ilib scripts/drop.tables.pl
perl -Ilib scripts/create.tables.pl

if [ "$FLOWER_DB" == "Pg" ]; then
	time perl -Ilib scripts/populate.pg.tables.pl
else
	time perl -Ilib scripts/populate.sqlite.tables.pl
fi

echo Leaving populate.db.sh.

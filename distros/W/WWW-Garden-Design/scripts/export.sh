#!/bin/bash

echo Entered export.sh.

if [ "$FLOWER_DB" == "Pg" ]; then
	echo Exporting the Pg flowers database
else
	if [ "$FLOWER_DB" == "SQLite" ]; then
		echo Exporting the SQLite flowers database
	else
		echo "Env var FLOWER_DB must match /^(Pg|SQLite)\$/"

		exit 1
	fi
fi

echo Checked ENV in export.db.sh.

if [ "$FLOWER_DB" == "Pg" ]; then
	time perl -Ilib scripts/export.all.pg.pages.pl
	time perl -Ilib scripts/export.pg.features.pl
	time perl -Ilib scripts/export.pg.layouts.pl
else
	time perl -Ilib scripts/export.all.sqlite.pages.pl
	time perl -Ilib scripts/export.sqlite.features.pl
	time perl -Ilib scripts/export.sqlite.layouts.pl
fi

cp -r ~/savage.net.au/Flowers* $DR/

echo Leaving export.sh.

#!/bin/bash

echo Import and export. Next, rebuild website.

cp /dev/null log/development.log

scripts/populate.db.sh

grep error log/development.log

if [ "$?" == "0" ]; then
	echo There are errors in log/development.log

	exit
fi

scripts/export.sh

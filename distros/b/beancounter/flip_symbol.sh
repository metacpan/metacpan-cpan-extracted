#!/bin/sh

if [ $# -ne 2 ]
then
    echo "Usage: $0 from_symbol to_symbol"
    echo "Updates beancounter tables replacing the former with the latter."
    exit 1
fi

for table in stockprices stockinfo portfolio indices
do
    echo "update $table set symbol='$2' where symbol='$1';" | \
	psql -e -d beancounter 
done

#!/bin/sh
# Copyright (c) 2010 Index Data, http://www.indexdata.com
#
# irspy-update.sh - wrapper for irspy.pl
#
# run irspy with a smaller set of records in a loop to avoid out-of-memory
#
# for a fast update, run this:
# 	$ env irspy_test=Quick ./irspy-update.sh

home=/usr/local/src/git
cd $home/irspy/bin || exit 2
logdir=../log
lockfile=$logdir/irspy-update.lock
statusfile=$logdir/irspy-last-update.log

# run a full update by default, use Quick for a fast update
: ${irspy_test=Main}

mkdir -p $logdir || exit2

if [ -f $lockfile ]; then
    pid=`cat $lockfile`
    if kill -0 $pid 2>/dev/null; then
	echo "This script is already running with pid: $pid"
	exit 1
    fi
fi
echo $$ > $lockfile || exit 2

weekday=`date '+%w'`
for i in 0 1 2 3 4 5 6
do
   logfile=$logdir/irspy-mod-$i.log.$weekday
   YAZ_LOG=irspy,irspy_test,irspy_task nice -10 time perl -I../lib irspy.pl -n 50 -d -M 3500 -f'cql.allRecords=1 not zeerex.disabled = 1' -t $irspy_test -m 7,$i localhost:8018/IR-Explain---1 > $logfile 2>&1

   sleep 1 # catch ctr-c before compressing the log
   gzip -f $logfile
done

rm -f $lockfile
date > $statusfile


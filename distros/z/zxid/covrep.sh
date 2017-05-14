#!/bin/sh
# 20101024, sampo@iki.fi
#  make gcov
#  make covrep
grep '#####:' *.c.gcov */*.c.gcov >uncovered-gcov
total=`cat *.c.gcov */*.c.gcov | wc -l`
inactive=`grep -e '-:' *.c.gcov */*.c.gcov | wc -l`
uncov=`cat uncovered-gcov | wc -l`
active=`expr $total - $inactive`
percent=`expr $uncov \* 100 / $active`
printf "Total source lines: %d, Active: %d, Not covered: %d (%.2f%%)\n" $total $active $uncov $percent
#EOF
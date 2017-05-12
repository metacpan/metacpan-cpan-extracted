#!/usr/bin/perl -w
cat datab | while read user;
do
cat data | mail -s "this is subject" $user;
done
exit


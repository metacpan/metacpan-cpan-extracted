#!/bin/sh

# $Id: mkstatic_dbshell.sh,v 1.2 2000/12/02 12:02:16 joern Exp $

TO=./static_dbshell.pl

perl -pe 's/$STATIC = 0/$STATIC = 1/' < dbshell.pl > $TO
echo 'BEGIN {' >> $TO
cat ../lib/NewSpirit/SqlShell.pm ../lib/NewSpirit/SqlShell/Text.pm \
    | grep -v 'use NewSpirit::' >> $TO
echo '}' >> $TO
chmod 755 $TO

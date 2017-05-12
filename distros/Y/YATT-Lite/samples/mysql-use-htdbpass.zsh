#!/bin/zsh

set -e

typeset -A dbspec

zparseopts -D -K n=o_dryrun

cd $0:h

dbspec=($(<.htdbpass))

user="'$dbspec[dbuser:]'@'localhost'"

sql="
create user $user identified by '$dbspec[dbpass:]';
grant all on $dbspec[dbname:].* to $user;
"

print $sql

if (($#o_dryrun)); then exit; fi

echo Connecting to mysql as root.

mysql -u root -p <<<$sql

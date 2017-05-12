#!/bin/zsh

bindir=$(cd $0:h && print $PWD);

db=$bindir/web/cover_db
driver=$bindir/web/cgi-bin/yatt.lib/t/covered-runtests.zsh

$driver --db=$db "$@"


#!/bin/sh

# This code is a part of tux_perl, and is released under the GPL.
# Copyright 2002 by Yale Huang<mailto:yale@sdf-eu.org>.
# See README and COPYING for more information, or see
#   http://tux-perl.sourceforge.net/.
#
# $Id: mksample_conf.sh,v 1.2 2002/11/11 11:15:25 yaleh Exp $

if [ $# -ne 2 ]; then
    echo "Usage: $0 <PREFIX> <INSTALLSITEARCH>" >/dev/stderr
    exit 1
fi

echo imp_lib $2/auto/Tux/tux_perl_imp.so
echo init_log_file $1/var/log/tux_perl_init.log
echo runtime_log_file $1/var/log/tux_perl_runtime.log
echo perl_lib_path $2

for F in Tux/Sample/*.pm; do
    M=`echo $F|awk -F '/' '{print $3}'|awk -F '.' '{print $1}'`
    echo "<perl_module>"
    echo "        name $M"
    echo "        lib Tux::Sample::$M"
    echo "        handler Tux::Sample::$M::handler"
    echo "</perl_module>"
done

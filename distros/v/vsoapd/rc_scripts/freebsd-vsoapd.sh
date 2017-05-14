#!/bin/sh
# $Id: freebsd-vsoapd.sh,v 1.1 2007/01/22 16:33:05 perlstalker Exp $

# PROVIDE: vsoapd
# REQUIRE: DAEMON
# BEFORE: LOGIN
# KEYWORD: shutdown

# Define these vsoapd_* variables in one of
#    /etc/rc.conf
#    /etc/rc.conf.local
#    /etc/rc.conf.d/vsoapd
#
# DO NOT CHANGE THESE VALUES HERE
vsoapd_enable=${vsoapd_enable-"NO"}
vsoapd_flags=${vsoapd_flags-""}

. /usr/local/etc/rc.subr

name="vsoapd"
rcvar=`set_rcvar`
command="/usr/local/sbin/vsoapd"

load_rc_config $name

run_rc_command "$1"

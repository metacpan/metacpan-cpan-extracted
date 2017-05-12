#! /bin/sh

# Shell script to start and stop the onindex daemon.

# $Id: onindex.sh,v 1.3 2005/07/26 19:52:36 kiesling Exp $

NAME="onindex"
ONSEARCHBINDIR=@inst_onsearchbindir@
PIDFILE="/usr/local/var/run/onsearch/onindex.pid"

case "$1" in
  start)
        if [ -f $PIDFILE ]; then
	    echo "$NAME is already running, PID `cat $PIDFILE`."
	else 
	    echo "Starting $NAME."
	    $ONSEARCHBINDIR/$NAME &
	    while [ ! -f $PIDFILE ]; do
		sh -c "true"
	    done
	fi
	;;
  stop)
	if [ -f $PIDFILE ]; then
	    echo "Stopping $NAME"
	    kill `cat $PIDFILE` 2>&1
        fi
	;;
  restart)
        if [ -f $PIDFILE ]; then
	    echo "Restarting $NAME."
            kill -HUP `cat $PIDFILE` 2>&1
        fi
	;;
  index)
        if [ -f $PIDFILE ]; then
            echo "Indexing now."
            kill -USR1 `cat $PIDFILE` 2>&1
	else 
	    echo "Starting $NAME."
	    $ONSEARCHBINDIR/$NAME &
	    while [ ! -f $PIDFILE ]; do
		sh -c "true"
	    done
        fi
        ;;
  *)
	echo "Usage: $NAME {start|stop|restart|index}" >&2
	exit 1
	;;
esac

exit 0

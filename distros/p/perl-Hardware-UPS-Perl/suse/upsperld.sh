#! /bin/sh
#
# Copyright (C) 2007 Christian Reile, Unterschleissheim, Germany
#
# /etc/init.d/upsperld
#
#   and symbolic its link
#
# /usr/sbin/rcupsperld
#
### BEGIN INIT INFO
# Provides:       upsperld
# Required-Start: $syslog
# Should-Start:   setserial
# Required-Stop:  $syslog
# Default-Start:  2 3 5
# Default-Stop:   0 6
# Description:    Start the upsperld daemon
### END INIT INFO

UPSPERLD_BIN=/usr/bin/upswatch.pl
test -x ${UPSPERLD_BIN} || exit 5

UPSPERLD_SYSCONFIG=/etc/sysconfig/upsperld
test -f ${UPSPERLD_SYSCONFIG} && . ${UPSPERLD_SYSCONFIG} || exit 5

export UPS_MAILTO UPS_PORT UPS_TCPPORT

UPSAGENT_BIN=/usr/bin/upsagent.pl
test -x ${UPSAGENT_BIN} || exit 5
UPSAGENT_PIDFILE=/var/run/upsagent.pid

if [ "${UPS_START_AGENT}" = "yes" ]; then
   UPSAGENT_OPT="-p ${UPSAGENT_PIDFILE}"
   if [ -z "${UPS_WATCH_OPTIONS}" ]; then
      UPS_WATCH_OPTIONS="-r"
   else
      UPS_WATCH_OPTIONS="${UPS_WATCH_OPTIONS} -r"
   fi
else
   if [ ! -z "${UPS_AGENT_HOST}" ]; then
      if [ -z "${UPS_WATCH_OPTIONS}" ]; then
         UPS_WATCH_OPTIONS="-r ${UPS_AGENT_HOST}"
      else
         UPS_WATCH_OPTIONS="${UPS_WATCH_OPTIONS} -r ${UPS_AGENT_HOST}"
      fi
   fi
fi

UPSPERLD_PIDFILE=/var/run/upswatch.pid

if [ -z "${UPS_WATCH_OPTIONS}" ]; then
   UPSPERLD_OPT="-p ${UPSPERLD_PIDFILE}"
else
   UPSPERLD_OPT="${UPS_WATCH_OPTIONS} -p ${UPSPERLD_PIDFILE}"
fi

. /etc/rc.status

# Shell functions sourced from /etc/rc.status:
#      rc_check         check and set local and overall rc status
#      rc_status        check and set local and overall rc status
#      rc_status -v     ditto but be verbose in local rc status
#      rc_status -v -r  ditto and clear the local rc status
#      rc_failed        set local and overall rc status to failed
#      rc_reset         clear local rc status (overall remains)
#      rc_exit          exit appropriate to overall rc status

# First reset status of this service
rc_reset

case "$1" in
   start)
      if [ "${UPS_START_AGENT}" = "yes" ]; then

         echo -n "Starting UPSPERL agent"
         ## Start daemon with startproc(8). If this fails
         ## the echo return value is set appropriate.

         startproc -q -t 10 -p ${UPSAGENT_PIDFILE} ${UPSAGENT_BIN} ${UPSAGENT_OPT}

	      # Remember status and be verbose
	      rc_status -v || rc_exit

      fi

      echo -n "Starting UPSPERL monitor"
      ## Start daemon with startproc(8). If this fails
      ## the echo return value is set appropriate.

      startproc -q -p ${UPSPERLD_PIDFILE} ${UPSPERLD_BIN} ${UPSPERLD_OPT}

      # Remember status and be verbose
      rc_status -v
      ;;
   stop)
      echo -n "Shutting down UPSPERL monitor"
      ## Stop daemon with killproc(8) and if this fails
      ## set echo the echo return value.

      killproc -p ${UPSPERLD_PIDFILE} -TERM ${UPSPERLD_BIN} >/dev/null 2>&1

      # Remember status and be verbose
      rc_status -v

      if [ "${UPS_START_AGENT}" = "yes" ]; then

         echo -n "Shutting down UPSPERL agent"
         ## Stop daemon with killproc(8) and if this fails
         ## set echo the echo return value.

         killproc -p ${UPSAGENT_PIDFILE} -TERM ${UPSAGENT_BIN} >/dev/null 2>&1

         # Remember status and be verbose
         rc_status -v

      fi
      ;;
   try-restart)
      ## Stop the service and if this succeeds (i.e. the 
      ## service was running before), start it again.
      $0 status >/dev/null &&  $0 restart

      # Remember status and be quiet
      rc_status
      ;;
   restart)
      ## Stop the service and regardless of whether it was
      ## running or not, start it again.
      $0 stop
      $0 start

      # Remember status and be quiet
      rc_status
      ;;
   force-reload)
      ## Signal the daemon to reload its config. Most daemons
      ## do this on signal 1 (SIGHUP).
      ## If it does not support it, restart.

      echo -n "Reload service UPSPERL"

      $0 stop && $0 start

      rc_status -v
      ;;
   reload)
      ## Like force-reload, but if daemon does not support
      ## signalling, do nothing (!)

      if [ "${UPS_START_AGENT}" = "yes" ]; then

         echo -n "Reload UPSPERL agent"
         killproc -p ${UPSAGENT_PIDFILE} -HUP ${UPSAGENT_BIN} >/dev/null 2>&1

	      # Remember status and be verbose
	      rc_status -v || rc_exit

      fi

      echo -n "Reoload UPSPERL monitor"
      killproc -p ${UPSPERLD_PIDFILE} -HUP ${UPSPERLD_BIN} >/dev/null 2>&1

	   rc_status -v
      ;;
   status)
      if [ "${UPS_START_AGENT}" = "yes" ]; then

         echo -n "Checking for UPSPERL agent"
         ## Check status with checkproc(8), if process is running
         ## checkproc will return with exit status 0.

         # Status has a slightly different for the status command:
         # 0 - service running
         # 1 - service dead, but /var/run/  pid  file exists
         # 2 - service dead, but /var/lock/ lock file exists
         # 3 - service not running

         checkproc -p ${UPSAGENT_PIDFILE} ${UPSAGENT_BIN}
         rc_status -v

      fi

      echo -n "Checking for UPSPERL monitor"
      ## Check status with checkproc(8), if process is running
      ## checkproc will return with exit status 0.

      # Status has a slightly different for the status command:
      # 0 - service running
      # 1 - service dead, but /var/run/  pid  file exists
      # 2 - service dead, but /var/lock/ lock file exists
      # 3 - service not running

      checkproc -p ${UPSPERLD_PIDFILE} ${UPSPERLD_BIN}
      rc_status -v
      ;;
   *)
      echo "Usage: $0 {start|stop|status|try-restart|restart|force-reload|reload}"
      exit 1
      ;;
esac
rc_exit

#! /bin/sh
#
# start/stop vyperlogix_site

### BEGIN INIT INFO
# Provides:          vyperlogix_site
# Required-Start:    $network
# Required-Stop:     $network
# Should-Start:      $named
# Should-Stop:       $named
# Default-Start:     S 2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start the vyperlogix_site
# Description:       Start the vyperlogix_site
### END INIT INFO

PATH=/home/raychorn/bin/
DAEMON=/home/raychorn/bin/start_vyperlogix.sh
NAME=vyperlogix_site

. /lib/lsb/init-functions

set -e

test -x $DAEMON || exit 0

PIDFILE=/var/run/vyperlogix_site.pid


case "$1" in
  start)	
	printf "Starting django fastcgi site: %s\t" "$NAME"
	start-stop-daemon --start --oknodo --pidfile $PIDFILE --exec $DAEMON -b
	;;

  stop)
	printf "Stopping django fastcgi site: %s\t" "$NAME"
	start-stop-daemon --stop --oknodo --pidfile $PIDFILE --exec $DAEMON
	rm -f $PIDFILE
	;;

  restart)
	$0 stop
	sleep 1
	$0 start
	;;

  reload|force-reload)
	printf "Reloading django fastcgi site: %s\t" "$NAME"
	if [ -f $PIDFILE ]
	    then
	    PID=$(cat $PIDFILE)
	    if ps p $PID | grep $NAME >/dev/null 2>&1
	    then
		kill -HUP $PID
	    else
		echo "PID present, but $NAME not found at PID $PID - Cannot reload"
		exit 1
	    fi
	else
	    echo "No PID file present for $NAME - Cannot reload"
	    exit 1
	fi
	;;

  status)
	# Strictly, LSB mandates us to return indicating the different statuses,
	# but that's not exactly Debian compatible - For further information:
	# http://www.freestandards.org/spec/refspecs/LSB_1.3.0/gLSB/gLSB/iniscrptact.html
	# http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=208010
	# ...So we just inform to the invoker and return success.
	printf "%s web server status:\t" "$NAME"
	if [ -e $PIDFILE ] ; then
	    PROCNAME=$(ps -p $(cat $PIDFILE) -o comm=)
	    if [ "x$PROCNAME" = "x" ]; then
		printf "Not running, but PID file present \t"
	    else
		if [ "$PROCNAME" = "$NAME" ]; then
		    printf "Running\t"
		else
		    printf "PID file points to process '%s', not '%s'\t" "$PROCNAME" "$NAME"
		fi
	    fi
	else
	    if PID=$(pidofproc cherokee); then
		printf "Running (PID %s), but PIDFILE not present\t" "$PID"
	    else
		printf "Not running\t"
	    fi
	fi
	;;

  *)
	N=/etc/init.d/$NAME
	echo "Usage: $N {start|stop|restart|reload|force-reload|status}" >&2
	exit 1
	;;
esac

if [ $? = 0 ]; then
        echo .
        exit 0
else
        echo failed
        exit 1
fi

exit 0

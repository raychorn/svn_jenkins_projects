#!/bin/bash

#if [ -f /root/bin/PYTHONPATH ]; then
#	. /root/bin/PYTHONPATH
#fi

python=$(which python | awk '{print $1}' | tail -n 1)
if [ -f "$python" ]; then 

	ret=`python -c 'import sys; print("%i" % (sys.hexversion<0x03000000))'`
	if [ $ret -eq 0 ]; then
		echo "we require python version <3"
		exit 1
	else 
		echo "python version is <3"
	fi
	
else
    echo "Cannot find python. Aborting."
	exit 1
fi

fpath="/var/local/nsca_helper_daemon"
DAEMON="$python $fpath/nsca-helper-daemon.py 0.0.0.0:15667"
echo "DAEMON is $DAEMON"

PIDFILE=/var/run/nsca-helper-daemon.pid
echo "PIDFILE is $PIDFILE"

if [ -f "$PIDFILE" ]; then
    pid=$(cat $PIDFILE)
    echo "pid is ($pid)"
    if [ X"" == X"$pid" ]; then
        echo "Removing empty $PIDFILE"
        rm -f $PIDFILE
    else
        echo "Cleaning-up the place."
        kill -9 $pid
        rm -f $PIDFILE
    fi
fi

nohup $DAEMON > $fpath/nsca-helper-daemon_nohup2.out 2>&1&
sleep 5
ps aux | grep nsca-helper-daemon.py | grep -v grep | awk '{print $2}' | tail -n 1 > $PIDFILE
pid=$(cat $PIDFILE)
echo "pid is $pid"



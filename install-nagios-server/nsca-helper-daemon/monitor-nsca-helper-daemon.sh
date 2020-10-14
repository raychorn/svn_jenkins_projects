#!/bin/bash

echo $(date)

PIDFILE=/var/run/nsca-helper-daemon.pid
echo "PIDFILE is $PIDFILE"

helper=$(which start-nsca-helper-daemon.sh)
echo "helper is $helper"

if [ -f "$PIDFILE" ]; then
    pid=$(cat $PIDFILE)
    echo "pid is ($pid)"
    if [ X"" == X"$pid" ]; then
        echo "Removing empty $PIDFILE"
        rm -f $PIDFILE
		$helper
    else
        echo "Verify the pid."
		p=$(ps aux | grep nsca-helper-daemon.py | grep -v grep | awk '{print $2}' | tail -n 1)
        if [ X"$pid" == X"$p" ]; then
            echo "All is good."
        else
            echo "Kill stale process and restart after cleaning-up."
            echo "p is $p"
            kill -9 $p
            rm -f $PIDFILE
            $helper
        fi
    fi
else
    echo "Start the helper."
    $helper
fi

truncate="/var/local/nsca_helper_daemon/truncate-helper-daemon-logs.sh"
if [ -f "$truncate" ]; then
    $truncate
else
    echo "Cannot locate the truncate script at $truncate."
fi

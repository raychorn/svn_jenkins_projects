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
DAEMON="$python $fpath/truncate-helper-daemon-logs /root/monitor-nsca-helper-daemon.log"
echo "DAEMON is $DAEMON"

nohup $DAEMON > $fpath/nsca-helper-daemon_nohup2.out 2>&1&



#!/bin/bash

PIDFILE=/var/run/nsca-helper-daemon.pid
pid=$(cat $PIDFILE)

echo $pid

kill -9 $pid

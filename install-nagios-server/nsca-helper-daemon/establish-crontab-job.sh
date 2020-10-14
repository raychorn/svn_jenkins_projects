#!/bin/bash

crontab=$(crontab -l | grep monitor-nsca-helper-daemon | awk '{print $1}' | tail -n 1)

echo "crontab is $crontab"

monitor="/var/local/nsca_helper_daemon/monitor-nsca-helper-daemon.sh"

if [ -f "$monitor" ]; then
    if [ X"" == X"$crontab" ]; then
        echo "Creating entry in crontab for helper"
        crontab -l > /tmp/mycron
        echo "*/5 * * * * $monitor >> ~/monitor-nsca-helper-daemon.log 2>&1" >> /tmp/mycron
        crontab /tmp/mycron
        rm /tmp/mycron
    fi
else
    echo "monitor is missing in $monitor"
fi



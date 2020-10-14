#!/bin/bash

pids=$(ps -ef | grep nagios | awk '{print $2}')

for p in $pids
    do
        echo "DEBUG: (p --> $p)"
        killtree $p 9
        break
    done

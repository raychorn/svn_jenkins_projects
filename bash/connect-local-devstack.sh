#!/bin/bash

pk="$HOME/Dropbox/Ray Horn/#SSH/Amazon AWS+EC2/windows-micro-05-11-2011.pem"
if [ -f "$pk" ]; then 
    echo "$pk exists"
    chmod 0600 "$pk"
else
    echo "$pk does not exist so Aborting."
    exit 1
fi

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=10 -i "$pk" raychorn@10.211.55.16 -p 22


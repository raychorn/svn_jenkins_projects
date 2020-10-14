#!/bin/bash

pk="$HOME/Dropbox/Ray Horn/#SSH/Amazon AWS+EC2/windows-micro-05-11-2011.pem"
if [ -f "$pk" ]; then 
    echo "$pk exists"
    chmod 0400 "$pk"
else
    echo "$pk does not exist so Aborting."
    exit 1
fi

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=10 -i "$pk" $1@63.135.170.109 -p 22


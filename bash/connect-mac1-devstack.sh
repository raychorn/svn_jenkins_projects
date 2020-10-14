#!/bin/bash

pk="$HOME/.vagrant.d/insecure_private_key"
if [ -f "$pk" ]; then 
	echo "$pk exists"
else
	echo "$pk does not exist so Aborting."
    exit 1
fi

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=10 -i "$pk" vagrant@192.168.1.84 -p 22


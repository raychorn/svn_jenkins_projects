#!/bin/bash
echo "your password today is vagrant"

pk="$HOME/id_rsa_vagrant_designate_workshop"
if [ -f "$pk" ]; then 
	echo "$pk exists"
else
	echo "$pk does not exist so Aborting."
    exit 1
fi

ip="192.168.122.1"
#ip="192.168.1.18"
ssh -o UserKnownHostsFile=/dev/null -o TCPKeepAlive=yes -o ServerAliveInterval=10 -i "$pk" -o StrictHostKeyChecking=no vagrant@$ip -p 22

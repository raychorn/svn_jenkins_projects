#!/bin/bash

pk="$HOME/Dropbox/Ray Horn/#SSH/key-pair-6a (att)/raychorn-dnsaas-dbaas_qa-openstack.cer"
if [ -f "$pk" ]; then 
    echo "$pk exists"
    chmod 0600 "$pk"
else
    echo "$pk does not exist so Aborting."
    exit 1
fi

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=10 -i "$pk" root@108.244.166.45 -p 22


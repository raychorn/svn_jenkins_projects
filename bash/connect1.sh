#!/bin/bash
echo "your password today is peekab00"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=10 raychorn@192.168.15.152 -p 22


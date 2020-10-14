#!/bin/bash
echo "your password today is sisko@7660$boo"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=10 raychorn@192.168.122.1 -p 22


#!/bin/bash
echo "your password today is sisko@7660$boo"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o TCPKeepAlive=yes -o ServerAliveInterval=10 raychorn@10.211.55.12 -p 22


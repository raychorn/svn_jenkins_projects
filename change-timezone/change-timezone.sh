#!/bin/bash

mv /etc/localtime /etc/localtime.bak

ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime


#!/bin/bash

echo "file1 is $1"
echo "file2 is $2"

if [ -f "$1" ]; then 
	echo "$1 exists."
else
	echo "Cannot locate $1. Aborting."
	exit 1
fi

if [ -f "$2" ]; then 
	echo "$2 exists."
else
	echo "Cannot locate $2. Aborting."
	exit 1
fi

if diff $1 $2 >/dev/null ; then
  echo Same
else
  echo Different
fi

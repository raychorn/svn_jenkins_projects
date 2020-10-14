#!/bin/bash

OS_VERSION_FILE=/proc/version
OS=`uname`
if [ "${OS}" = "Linux" ]; then
	if [ -r ${OS_VERSION_FILE} ]; then
		grep -i centos ${OS_VERSION_FILE} 1>/dev/null 2>&1
		if [ $? -eq 0 ]; then
			LINUX_VERSION=centos
		else
			grep -i ubuntu ${OS_VERSION_FILE} 1>/dev/null 2>&1
			if [ $? -eq 0 ]; then
				LINUX_VERSION=ubuntu
			else
				fail 2 "${SCRIPT} only supports CentOS and Ubuntu at this time."
			fi
		fi
	else
		fail 3 "Unable to find ${OS_VERSION_FILE}."
	fi
else
	fail 4 "${SCRIPT} only supports Linux at this time."
fi

r=$(lsb_release -d)
IFS=': ' read -a array <<< "$r"
distro=""
count=0
for item in $r
	do
	if [ $count -gt 0 ]; then
		distro="$distro $item"
		echo "item --> $item"
	fi
	count=1
done

if [ "${LINUX_VERSION}" = "centos" ]; then
	echo "OS is $distro"
elif [ "${LINUX_VERSION}" = "ubuntu" ]; then
	echo "OS is $distro"
fi

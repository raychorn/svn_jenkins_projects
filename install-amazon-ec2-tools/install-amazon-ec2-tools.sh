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

if [ "${LINUX_VERSION}" = "centos" ]; then
	echo "Installing for CentOS."
	#yum install -y monit
elif [ "${LINUX_VERSION}" = "ubuntu" ]; then
	echo "Installing for Ubuntu"
	#apt-get install --yes monit
	apt-add-repository --yes ppa:awstools-dev/awstools
	sed -i.dist 's,universe$,universe multiverse,' /etc/apt/sources.list
	apt-get update --yes
	apt-get install --yes ec2-api-tools ec2-ami-tools iamcli rdscli
fi

workspace=$1
echo "workspace is $workspace."
ServerName=$2
echo "ServerName is $ServerName."

executable=$(which iam-virtualmfadevicecreate)
if [ -f "$executable" ]; then 
	echo "$executable exists"
else
	echo "Cannot locate executable in $executable.  Aborting."
    #exit 1
fi

echo "All if GOOD !!!"

exit 0

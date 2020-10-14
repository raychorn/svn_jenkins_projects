#!/bin/bash

BUILD_DIR=~/downloads/monit

function dirname()
 {
   local dir="${1%${1##*/}}"
   "${dir:=./}" != "/" && dir="${dir%?}"
   echo "$dir"
 }
 
function basename()
 {
   local name="${1##*/}"
   echo "${name%$2}"
 }

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
	yum install -y monit
elif [ "${LINUX_VERSION}" = "ubuntu" ]; then
	echo "Installing for Ubuntu"
	apt-get install --yes monit # install monit 5.x but probably not the latest.
fi

workspace=${1}
echo "workspace is $workspace."
ServerName=${2}
echo "ServerName is $ServerName."
MONIT_VERSION=${3}
echo "MONIT_VERSION is $MONIT_VERSION"
MONIT_PORT=${4}
echo "MONIT_PORT is $MONIT_PORT"
MONIT_MAIL_FROM=${5}
echo "MONIT_MAIL_FROM is $MONIT_MAIL_FROM"
MONIT_ADMIN_USER=${6}
echo "MONIT_ADMIN_USER is $MONIT_ADMIN_USER"
MONIT_ADMIN_PASSWORD=${7}
echo "MONIT_ADMIN_PASSWORD is $MONIT_ADMIN_PASSWORD"
MONIT_MAILSERVER=${8}
echo "MONIT_MAILSERVER is $MONIT_MAILSERVER"
MONIT_MAILSERVER_PORT=${9}
echo "MONIT_MAILSERVER_PORT is $MONIT_MAILSERVER_PORT"
MONIT_MAIL_USER=${10}
echo "MONIT_MAIL_USER is $MONIT_MAIL_USER"
MONIT_MAIL_USER_PASSWORD=${11}
echo "MONIT_MAIL_USER_PASSWORD is $MONIT_MAIL_USER_PASSWORD"

echo "LINUX_VERSION --> ${LINUX_VERSION}"
if [ "${LINUX_VERSION}" = "centos" ]; then
	echo "Installing for CentOS."
elif [ "${LINUX_VERSION}" = "ubuntu" ]; then
	echo "Installing for Ubuntu"
fi

rm -f -R $BUILD_DIR
mkdir $BUILD_DIR
cd $BUILD_DIR

is_x86_64=$(uname -a | grep x86_64)
for item in $is_x86_64
	do
	echo "DEBUG: (item --> $item)"
	if [ "${item}" = "x86_64" ]; then
		echo "x86_64 detected."
		is_x86_64=1
		break;
	fi
done

if [ -f "./monit-$MONIT_VERSION-linux-x86.tar.gz" ]; then 
    echo "monit-$MONIT_VERSION-linux-x86.tar.gz exists in $pwd."
else
	echo "LINUX_VERSION --> ${LINUX_VERSION}"
	if [ "${is_x86_64}" = "1" ]; then
		echo "x86_64."
		monit_tar="monit-$MONIT_VERSION-linux-x64.tar.gz"
		monit_dir="monit-$MONIT_VERSION"
		wget http://mmonit.com/monit/dist/binary/$MONIT_VERSION/monit-$MONIT_VERSION-linux-x64.tar.gz
	else
		echo "x86"
		monit_tar="monit-$MONIT_VERSION-linux-x86.tar.gz"
		monit_dir="monit-$MONIT_VERSION"
		wget http://mmonit.com/monit/dist/binary/$MONIT_VERSION/monit-$MONIT_VERSION-linux-x86.tar.gz
	fi
fi

echo "monit_tar is $monit_tar"
if [ -f "./$monit_tar" ]; then 
    echo "monit_tar exists in $monit_tar."
else
    echo "monit_tar cannot be found. Aborting."
	exit 1
fi

tar zxvf ./$monit_tar

echo "monit_dir is $monit_dir"
if [ -d "./$monit_dir" ]; then 
    echo "monit_dir exists in $monit_dir."
else
    echo "monit_dir cannot be found. Aborting."
	exit 1
fi

# This is a pre-compiled binary rather than the sources...
monit=$(which monit)

if [ -f "$monit" ]; then 
    echo "monit exists in $monit."
else
    echo "monit cannot be found. Aborting."
	exit 1
fi

ls -latr $monit_dir

if [ -f "$monit_dir/bin/monit" ]; then 
    echo "monit_dir/bin/monit exists in $monit_dir/bin/monit."
else
    echo "monit_dir/bin/monit cannot be found. Aborting."
	exit 1
fi

if [ -f "/etc/monit/monitrc" ]; then 
    echo "/etc/monit/monitrc exists."
else
    echo "/etc/monit/monitrc cannot be found. Aborting."
	exit 1
fi

if [ -f "$workspace/monitrc.mine" ]; then 
    echo "$workspace/monitrc.mine exists."
else
    echo "$workspace/monitrc.mine cannot be found. Aborting."
	exit 1
fi

if [ -d "$workspace/conf.d" ]; then 
    echo "$workspace/conf.d exists."
else
    echo "$workspace/conf.d cannot be found. Aborting."
	exit 1
fi

if [ -d "/etc/monit/conf.d" ]; then 
    echo "/etc/monit/conf.d exists."
else
    echo "/etc/monit/conf.d cannot be found. Aborting."
	exit 1
fi

if [ -f "/etc/sysconfig/network" ]; then 
    echo "/etc/sysconfig/network exists."
	hostname=$(cat /etc/sysconfig/network | awk -F'=' '{print $2}')
	if [ "${hostname}" = "${ServerName}" ]; then
		echo "HOSTNAME is $ServerName in /etc/sysconfig/network so nothing to do about this."
	else
		echo "HOSTNAME is not $ServerName in /etc/sysconfig/network so making it so."
		echo "HOSTNAME=${ServerName}" > /etc/sysconfig/network
	fi
fi

if [ -f "/etc/hostname" ]; then 
    echo "/etc/hostname exists."
	hostname=$(cat /etc/hostname)
	if [ "${hostname}" = "${ServerName}" ]; then
		echo "HOSTNAME is $ServerName in /etc/hostname so nothing to do about this."
	else
		echo "HOSTNAME is not $ServerName in /etc/hostname so making it so."
		echo "${ServerName}" > /etc/hostname
		hostname=$(cat /etc/hostname)
		echo "/etc/hostname has $hostname."
	fi
fi

files=$(find $workspace/conf.d/*.monitrc)
for item in $files
	do
	bname=$(basename $item)
	echo "DEBUG: (item --> $item) --> ${bname}"
	if [ "${bname}" = "crond.monitrc" ]; then
		echo "crond.monitrc detected."
		cp $item /etc/monit/conf.d
	fi
	if [ "${bname}" = "datafs.monitrc" ]; then
		echo "datafs.monitrc detected."
		rm -f /etc/monit/conf.d/partition_*.monitrc
		TARGET_PARTITIONS=$(awk '{print $4}' /proc/partitions | sed -e '/name/d' -e '/^$/d' -e '/[1-9]/!d')
		echo "TARGET_PARTITIONS is $TARGET_PARTITIONS"
		for i in $TARGET_PARTITIONS
			do
			partition=$(parted -l | grep $i | awk '{print $2}' | sed -r 's/://g')
			echo "$i --> ${i} --> ${partition}"
			cat > /etc/monit/conf.d/partition_$i.monitrc <<EOF3A
check device root.disk with path ${partition}
  if space usage > 95% for 15 times within 20 cycles then alert
  if inode usage > 95% for 15 times within 20 cycles then alert
  group partitions
EOF3A
		done
	fi
	if [ "${bname}" = "ubuntu.monitrc" ]; then
		echo "ubuntu.monitrc detected."
		rm -f /etc/monit/conf.d/domain_*.monitrc
		cat > /etc/monit/conf.d/domain_$ServerName.monitrc <<EOF3B
check system $ServerName
  if loadavg(1min) > 90 for 8 times within 10 cycles then alert
  if loadavg(5min) > 80 for 8 times within 10 cycles then alert
  if memory usage > 80% for 8 times within 10 cycles then alert
  if cpu usage (user) > 95% for 8 times within 10 cycles then alert
  if cpu usage (system) > 80% for 8 times within 10 cycles then alert
  if cpu usage (wait) > 95% for 16 times within 20 cycles then alert
  group system
EOF3B
	fi
	if [ "${bname}" = "sshd.monitrc" ]; then
		echo "sshd.monitrc detected."
		items=$(find /var/run/*.pid)
		for pidfile in $items
			do
			bname=$(basename $pidfile)
			pname=$(echo "$bname" | awk -F'.' '{print $1}')
			monitrc="/etc/monit/conf.d/process_$pname.monitrc"
			echo "$pidfile --> $bname --> $pname --> $monitrc"
			if [ -f "$monitrc" ]; then 
				echo "$monitrc exists."
			else
				echo "$monitrc does not exists."
				if [ -f "/etc/init.d/$pname" ]; then 
					echo "/etc/init.d/$pname exists so making $monitrc."
					cat > $monitrc <<EOF3C
check process $pname with pidfile $pidfile
   start program = "/etc/init.d/$pname start"
   stop program = "/etc/init.d/$pname stop"
   if 5 restarts within 5 cycles then restart
   if 10 restarts within 10 cycles then timeout
   group process
EOF3C
				else
					echo "WARNING: /etc/init.d/$pname cannot be found so cannot make $monitrc."
				fi
			fi
		done
	fi
done


#####################################################
#  $workspace/monitrc.mine -> /etc/monit/monitrc
#####################################################

if [ -f "/etc/monit/monitrc.theirs" ]; then 
    echo "/etc/monit/monitrc.theirs exists."
else
    echo "/etc/monit/monitrc.theirs cannot be found. Create it, first installation."
	cp /etc/monit/monitrc /etc/monit/monitrc.theirs
fi

cp $workspace/monitrc.mine /etc/monit/monitrc

python=$(which python | awk '{print $1}' | tail -n 1)
if [ -f "$python" ]; then 

	ret=`python -c 'import sys; print("%i" % (sys.hexversion<0x03000000))'`
	if [ $ret -eq 0 ]; then
		echo "we require python version <3"
		exit 1
	else 
		echo "python version is <3"
	fi
	
else
    echo "Cannot find python. Aborting."
	exit 1
fi

if [ -f "$workspace/fix_monitrc.py" ]; then 
	echo "$workspace/fix_monitrc.py exists..."
else
    echo "Cannot find $workspace/fix_monitrc.py. Aborting."
	exit 1
fi

if [ -f "$python" ]; then 
	echo "Running $workspace/fix_monitrc.py..."
	$python $workspace/fix_monitrc.py -p $MONIT_PORT -m $MONIT_MAIL_FROM -a $MONIT_ADMIN_USER -w $MONIT_ADMIN_PASSWORD -s $MONIT_MAILSERVER -o $MONIT_MAILSERVER_PORT -u $MONIT_MAIL_USER -d $MONIT_MAIL_USER_PASSWORD
else
    echo "Cannot find python so could not execute $workspace/fix_monitrc.py. Aborting."
	exit 1
fi

#####################################################
#  $workspace/monitrc.mine -> /etc/monit/monitrc
#####################################################

if [ -f "/etc/monitrc" ]; then 
    echo "/etc/monitrc exists."
else
    echo "/etc/monitrc cannot be found. Making it."
	ln -s /etc/monit/monitrc /etc/monitrc
fi

monit_v=$(monit -V | grep version | awk '{print $5}' | tail -n 1)

if [ "${monit_v}" = "${MONIT_VERSION}" ]; then
    echo "Nothing to do; at the proper version which is ${monit_v}.  Success !!!"
	echo "Stop and Start the Service to make sure the configuration is correct."
	service monit stop
	sleep 5
	service monit start
	sleep 5
	exit 0
else
	monit -V

	service monit stop
	sleep 5

	echo "--> cp $monit_dir/bin/monit $monit"
	cp $monit_dir/bin/monit $monit

	service monit start
	sleep 5

	monit -V
fi

exit 0

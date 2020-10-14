#!/bin/bash

NSCA_VERSION=$1
LIBMCRYPT_VERSION=$2
#Directory where the nagios and plugins software is stored. This might be different for each vm
BUILD_DIR=~/downloads
NAGIOS_SERVER_IP=$3
fix_nsca_command_file=$4
echo "fix_nsca_command_file is $fix_nsca_command_file."

echo "NSCA_VERSION is $NSCA_VERSION"
echo "LIBMCRYPT_VERSION is $LIBMCRYPT_VERSION"
echo "BUILD_DIR is $BUILD_DIR"

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
	yum install -y gawk
elif [ "${LINUX_VERSION}" = "ubuntu" ]; then
	echo "Installing for Ubuntu"
	apt-get install --yes gawk libmcrypt4 libmcrypt-dev nsca
fi

NAGIOS_SERVER_IP=$(ping -c 1 $NAGIOS_SERVER_IP | gawk -F'[()]' '/PING/{print $2}')

echo "NAGIOS_SERVER_IP is $NAGIOS_SERVER_IP"

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    echo "$stat"
    return $stat
}

if [ "$NAGIOS_SERVER_IP" = "" ] ; then
        echo "Nagios server Ip not specified. Aborting"
        exit 1
elif [ "$BUILD_DIR" = "" ] ; then
        echo "Build Dir ($BUILD_DIR) (location of nagios and plugin software) is not specified. Aborting."
        exit 1
fi

if [ -d "$BUILD_DIR" ]; then 
	echo "BUILD DIR ($BUILD_DIR) exists."
else
    mkdir "$BUILD_DIR"
fi

if [ -d "$BUILD_DIR" ]; then 
	echo "BUILD DIR ($BUILD_DIR) exists."
else
    echo "Build Dir ($BUILD_DIR) (location of nagios and plugin software) is not specified. Aborting."
    exit 1
fi

is_valid=$(valid_ip "$NAGIOS_SERVER_IP")
echo "is_valid=$is_valid"
if [ "$is_valid" = "0"  ] ; then
    echo "NAGIOS_SERVER_IP $NAGIOS_SERVER_IP is valid."
else
    echo "Nagios server Ip ($NAGIOS_SERVER_IP) not specified or not valid. Aborting"
    exit 1
fi

echo "NAGIOS_SERVER_IP=$NAGIOS_SERVER_IP"

UNAME=nagios
PASSWD=nagios
if id -u $UNAME >/dev/null 2>&1; then
    echo "User $UNAME exists."
else
    echo "Creating nagios account"
    useradd -c "$UNAME" -p "$PASSWD"
fi

cd "$BUILD_DIR"
#################################################################################################

if [ "${LINUX_VERSION}" = "centos" ]; then
	if [ -f "libmcrypt-$LIBMCRYPT_VERSION.tar.gz" ]; then 
		echo ""
	else
		wget "http://sourceforge.net/projects/mcrypt/files/Libmcrypt/$LIBMCRYPT_VERSION/libmcrypt-$LIBMCRYPT_VERSION.tar.gz/download" -O libmcrypt-$LIBMCRYPT_VERSION.tar.gz
	fi

	if [ -f "libmcrypt-$LIBMCRYPT_VERSION.tar.gz" ]; then 
		echo "libmcrypt-$LIBMCRYPT_VERSION.tar.gz exists."
	else
		echo "(1) Cannot locate (libmcrypt-$LIBMCRYPT_VERSION.tar.gz). Aborting."
		exit 1
	fi

	if [ -f "libmcrypt-$LIBMCRYPT_VERSION.tar.gz" ]; then 
		if [ -d "libmcrypt-$LIBMCRYPT_VERSION" ]; then 
			echo ""
		else
			tar -zxvf "libmcrypt-$LIBMCRYPT_VERSION.tar.gz"
		fi
	else
		echo ""
	fi

	if [ -d "libmcrypt-$LIBMCRYPT_VERSION" ]; then 
		echo "(libmcrypt-$LIBMCRYPT_VERSION) exists."
	else
		echo "(2) Cannot locate (libmcrypt-$LIBMCRYPT_VERSION). Aborting."
		exit 1
	fi

	cd "libmcrypt-$LIBMCRYPT_VERSION"

	if [ -f "config.log" ]; then 
		rm config.log
	fi

	./configure --prefix=/usr/local/libmcrypt --disable-posix-threads

	if [ -f "config.log" ]; then 
		echo "config.log exists."
	else
		echo "Cannot locate (config.log). Aborting."
		exit 1
	fi

	results=$(cat ./config.log | grep error | awk '{print $0}' | tail -n 1)
	echo "./configure $results"

	make

	make install

	if [ -d "/usr/local/libmcrypt/lib" ]; then 
		echo "Found /usr/local/libmcrypt/lib."
		cat << 'EOFLIBCRYPT' > /etc/ld.so.conf.d/libmcrypt-x86_64.conf
/usr/local/libmcrypt/lib

EOFLIBCRYPT

	fi

	if [ -f "/etc/ld.so.conf.d/libmcrypt-x86_64.conf" ]; then 
		echo "Found /etc/ld.so.conf.d/libmcrypt-x86_64.conf."
		content=$(cat /etc/ld.so.conf.d/libmcrypt-x86_64.conf)
		echo "$content"
	fi
fi

#################################################################################################

cd "$BUILD_DIR"

if [ "${LINUX_VERSION}" = "centos" ]; then
	if [ -f "nsca-$NSCA_VERSION.tar.gz" ]; then 
		echo ""
	else
		wget "http://prdownloads.sourceforge.net/sourceforge/nagios/nsca-$NSCA_VERSION.tar.gz"
	fi

	if [ -f "nsca-$NSCA_VERSION.tar.gz" ]; then 
		echo "nsca-$NSCA_VERSION.tar.gz exists."
	else
		echo "Cannot locate (nsca-$NSCA_VERSION.tar.gz). Aborting."
		exit 1
	fi

	if [ -f "nsca-$NSCA_VERSION.tar.gz" ]; then 
		if [ -d "nsca-$NSCA_VERSION" ]; then 
			echo ""
		else
			tar -zxvf "nsca-$NSCA_VERSION.tar.gz"
		fi
	else
		echo ""
	fi

	if [ -d "nsca-$NSCA_VERSION" ]; then 
		echo "(nsca-$NSCA_VERSION) exists."
	else
		echo "Cannot locate ("nsca-$NSCA_VERSION"). Aborting."
		exit 1
	fi

	cd "nsca-$NSCA_VERSION"

	if [ -f "configure" ]; then 
		echo "configure exists."
	else
		echo "Cannot locate (configure). Aborting."
		exit 1
	fi

	if [ -f "config.log" ]; then 
		rm config.log
	fi

	make devclean

	./configure

	if [ -f "config.log" ]; then 
		echo "config.log exists."
	else
		echo "Cannot locate (config.log). Aborting."
		exit 1
	fi

	results=$(cat ./config.log | grep error | awk '{print $0}' | tail -n 1)
	echo "./configure $results"

	make all

	if [ -f "./src/nsca" ]; then 
		echo "nsca exists."
	else
		echo "Cannot locate (nsca). Aborting."
		exit 1
	fi

	if [ -f "./src/send_nsca" ]; then 
		echo "send_nsca exists."
	else
		echo "Cannot locate (send_nsca). Aborting."
		exit 1
	fi

	make install

	nagios="/usr/local/nagios/etc"
	if [ -d "$nagios" ]; then 
		echo "($nagios) exists."
	else
		nagios="/etc/nagios"
		if [ -d "$nagios" ]; then 
			echo "($nagios) exists."
		else
			echo "Cannot locate nagios config files. Aborting."
			exit 1
		fi
	fi

	nsca=$(which nsca | grep nsca | awk '{print $1}')

	if [ -f "$nsca" ]; then 
		echo "$nsca exists."
	else
		cp ./src/nsca "$nagios/nsca"
		chmod +x "$nagios/nsca"
	fi


fi

nagioscfg=""

nagios=$(whereis nagios | grep nagios | awk '{print $2}')
if [ -d "$nagios" ]; then 
	echo "$nagios directory exists."
	echo "========================================================================"
	items=$(find $nagios -iname nagios.cfg)
	for item in $items
		do
		echo "item --> $item"
		if [ -f "$item" ]; then 
			nagioscfg="$item"
			break;
		fi
	done
	echo "========================================================================"
    nagioscmdfile=$(cat $nagioscfg | grep command_file | awk '{print $1}')
	items=$(find /usr/local/nagios -iname nagios | grep nagios)
	for item in $items
		do
		echo "item --> $item"
		if [ -f "$item" ]; then 
			nagios="$item"
			break;
		fi
	done
else
	echo "(+++) Cannot locate nagios. Aborting."
	exit 1
fi

if [ -f "$nagios" ]; then 
	echo "nagios exists in $nagios."
else
	echo "ERROR: Cannot locate nagios. Aborting."
	exit 1
fi

nsca=$(which nsca | grep nsca | awk '{print $1}')
if [ -f "$nsca" ]; then 
	echo "$nsca exists."
else
	echo "Cannot locate nsca. Aborting."
	exit 1
fi

chknsca=$(ls -la $nsca | awk '{print $3}')

if [ X$chknsca != X"nagios" ]; then 
    echo "Adjusting chown for $nsca"
    chown nagios:nagios $nsca
fi

sendnsca=$(which send_nsca | grep send_nsca)

if [ "${LINUX_VERSION}" = "centos" ]; then
	if [ -f "$sendnsca" ]; then 
		echo "(+++) $sendnsca exists."
	else
		cp ./src/send_nsca "$nagios/send_nsca"
		chmod +x "$nagios/send_nsca"
	fi
fi

sendnscacfg=$(find /etc send_nsca.cfg | grep send_nsca.cfg | awk '{print $1}')
if [ -f "$sendnscacfg" ]; then 
    echo "(1) $sendnscacfg exists."
else
    sendnscacfg=$(find /usr send_nsca.cfg | grep send_nsca.cfg | awk '{print $1}')
fi
if [ -f "$sendnscacfg" ]; then 
    echo "(2) $sendnscacfg exists."
	echo "Setting password in $sendnscacfg."
    sed -i 's/^#password=/password=nag10s-s3cr3t/' $sendnscacfg
else
    echo "Cannot find send_nsca.cfg. Aborting."
	exit 1
fi

nsca=$(which nsca | grep nsca | awk '{print $1}')
echo "(+++) nsca is $nsca"
if [ -f "$nsca" ]; then 
    echo "(1) $nsca exists."
else
    echo "Cannot find nsca. Aborting."
	exit 1
fi

chksendnsca=$(ls -la $sendnsca | awk '{print $3}')

if [ X$chksendnsca != X"nagios" ]; then 
    echo "Adjusting chown for $sendnsca"
    chown nagios:nagios $sendnsca
fi

echo "========================================================================"
echo "nagioscmdfile --> $nagioscmdfile"
nscadir=${nsca%/*}
echo "nscadir --> $nscadir"
echo "========================================================================"

nscacfg=""
echo "========================================================================"
items=$(find / -iname nsca.cfg)
for item in $items
	do
	echo "item --> $item"
	if [ -f "$item" ]; then 
	    sample=$(echo $item | grep sample)
		if [ X"$sample" = X"" ]; then 
			nscacfg="$item"
			break;
		fi
	fi
done
echo "========================================================================"

if [ -f "$nscacfg" ]; then 
    echo "$nscacfg exists."
else
    echo "(1) Cannot locate ($nscacfg). Aborting."
    exit 1
fi

sed -i 's/'192.168.1.1.*'/'"0.0.0.0"'/' $nscacfg
sed -i 's/^#server_address=/server_address=/' $nscacfg
sed -i 's/^#password=/password=nag10s-s3cr3t/' $nscacfg
#sed -i 's/^#command_file=/command_file=$nagioscmdfile/' $nscacfg

python=$(which python | awk '{print $1}' | tail -n 1)

if [ -f "$python" ]; then 
	echo "Running fix_nsca_command_file.py..."
	$python $fix_nsca_command_file "$nscacfg" "$nagioscmdfile"
else
    echo "Cannot find python. Aborting."
	exit 1
fi

nscacmdfile=$(cat $nscacfg | grep command_file | awk '{print $1}')

echo "========================================================================"
echo "nagioscmdfile --> $nagioscmdfile"
echo "nscacmdfile --> $nscacmdfile"
echo "========================================================================"

nscainitd=""
echo "========================================================================"
items=$(find /etc/init.d -iname nsca)
for item in $items
	do
	echo "item --> $item"
	if [ -f "$item" ]; then 
		nscainitd="$item"
		break;
	fi
done
echo "========================================================================"

if [ -f "$nscainitd" ]; then 
    echo "nsca init.d exists in $nscainitd"
else
	cat << 'EOF' > $nscainitd
	#!/bin/bash
	#
	# Init file for Nagios NSCA
	#
	# Written by Ray C Horn <rh4142@att.com>.
	#
	# chkconfig: - 80 20
	# description: Nagios NSCA daemon
	#
	# processname: nsca
	# config: /etc/nagios/nsca.cfg
	# pidfile: /var/run/nsca

	source /etc/rc.d/init.d/functions

	### Default variables
	CONFIG="/etc/nagios/nsca.cfg"

	[ -x /usr/sbin/nsca ] || exit 1
	[ -r "$CONFIG" ] || exit 1

	RETVAL=0
	prog="nsca"
	desc="Nagios NSCA daemon"

	start() {
		echo -n $"Starting $desc ($prog): "
		daemon $prog -c "$CONFIG" -d
		RETVAL=$?
		echo
		[ $RETVAL -eq 0 ] && touch /var/lock/subsys/$prog
		return $RETVAL
	}

	stop() {
		echo -n $"Shutting down $desc ($prog): "
		killproc $prog
		RETVAL=$?
		echo
		[ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/$prog
		return $RETVAL
	}

	restart() {
		stop
		start
	}

	reload() {
		echo -n $"Reloading $desc ($prog): "
		killproc $prog -HUP
		RETVAL=$?
		echo
		return $RETVAL
	}

	case "$1" in
	  start)
		start
		;;
	  stop)
		stop
		;;
	  restart)
		restart
		;;
	  reload)
		reload
		;;
	  condrestart)
		[ -e /var/lock/subsys/$prog ] && restart
		RETVAL=$?
		;;
	  status)
		status $prog
		RETVAL=$?
		;;
	  *)
		echo $"Usage: $0 {start|stop|restart|reload|condrestart|status}"
		RETVAL=1
	esac

	exit $RETVAL
EOF
	chkconfig --level 345 nsca on
fi

if [ -f "$nscainitd" ]; then 
    echo "$nscainitd exists."
	sed -i 's/^OPTS="--daemon -C/OPTS="--daemon -c/' $nscainitd
	#sed -i 's/^CONFIG=.*/CONFIG="$nscacfg"/' $nscainitd
	#sed -i 's/^\/usr\/sbin\/nsca/$nsca/' $nscainitd
else
    echo "Cannot locate nsca init.d in ($nscainitd). Aborting."
    exit 1
fi

echo "========================================================="
pid=$(ps -ef | grep $nsca | awk '{print $2}' | tail -n 1)
echo "(+++) pid is $pid"
echo "========================================================="
pidfile=$(find / -iname nsca.pid | awk '{print $0}' | tail -n 1)
if [ -f "$pidfile" ]; then 
    echo "$pidfile exists."
fi

/etc/init.d/nsca stop

p=$(cat $pidfile)
echo "(1) pid is $pid and p is $p."
if [ X"$pid" != X"$p" ]; then 
    echo "nsca cannot be verified to be running... starting it."
    /etc/init.d/nsca start
fi

echo "========================================================="
pid=$(ps -ef | grep $nsca | awk '{print $2}' | tail -n 1)
echo "(+++) pid is $pid"
echo "========================================================="
pidfile=$(find / -iname nsca.pid | awk '{print $0}' | tail -n 1)
if [ -f "$pidfile" ]; then 
    echo "$pidfile exists."
else
    echo "Cannot locate pid file in ($pidfile). Aborting."
    exit 1
fi

p=$(cat $pidfile)
echo "(2) pid is $pid and p is $p."
if [ X"$pid" = X"$p" ]; then 
    echo "nsca has been verified to be running... stopping it."
    /etc/init.d/nsca stop
else
    echo "ERROR: Cannot verify the nsca service is installed and running."
	exit 1
fi

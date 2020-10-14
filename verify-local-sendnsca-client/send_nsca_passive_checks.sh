#!/bin/bash

PLUGINS='/usr/lib/nagios/plugins'
NAGIOS=$1
NSCA_PORT=$2
HOST=$3
nagios_config_file=$4
nagios_config_fixer=$5
update_nagios_cfg=$6

echo "NAGIOS is $NAGIOS"
echo "NSCA_PORT is $NSCA_PORT"
echo "HOST is $HOST"
echo "nagios_config_file is $nagios_config_file"
echo "nagios_config_fixer is $nagios_config_fixer"
echo "update_nagios_cfg is $update_nagios_cfg"

if [ -f "$nagios_config_file" ]; then 
	echo "nagios_config_file exists in $nagios_config_file"
else
    echo "Cannot find nagios_config_file. Aborting."
	exit 1
fi

if [ -f "$nagios_config_fixer" ]; then 
	echo "nagios_config_fixer exists in $nagios_config_fixer"
else
    echo "Cannot find nagios_config_fixer. Aborting."
	exit 1
fi

if [ -f "$update_nagios_cfg" ]; then 
	echo "update_nagios_cfg exists in $update_nagios_cfg"
else
    echo "Cannot find update_nagios_cfg. Aborting."
	exit 1
fi

nagios=$(find /usr -iname nagios)
echo "nagios is $nagios"
function find_nagios_plugins()
{
    local  top=$1

    for file in $top;
    do
        f="$file/plugins"
		#echo "f is $f"
        if [ -d "$f" ]; then 
            top=$f
            echo $top
            break
		#else
			#echo "(-) $f"
        fi
    done
}

function find_nagios_objects()
{
    local  top=$1

    for file in $top;
    do
        f="$file"
		#echo "f is $f"
		d=${f%/*}
		#echo "d --> $d"
        if [ -d "$d/objects" ]; then 
            top="$d/objects"
            echo $top
            break
		#else
			#echo "(-) $f"
        fi
    done
}

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

nagios_plugins=$(find /usr -iname plugins | grep nagios | awk '{print $1}' | tail -n 1)
echo "nagios_plugins is $nagios_plugins"
if [ -d "$nagios_plugins" ]; then 
    PLUGINS="$nagios_plugins"
    echo "nagios=$nagios"
    echo "nagios_plugins=$nagios_plugins"
else
    echo "Cannot locate Nagios Plugins directory. Aborting."
    exit 1
fi

if [ -f "$nagios_config_file" ]; then 
    echo "nagios_config_file exists in $nagios_config_file"
else
    echo "Cannot locate nagios_config_file in $nagios_config_file.  Aborting."
	exit 1
fi

#echo "================================================================"
configs=$(find /usr -iname *nagios*.cfg)
nagios_objects=$(find_nagios_objects "$configs")
echo "nagios_objects is $nagios_objects"
#echo "================================================================"
if [ -d "$nagios_objects" ]; then 
    echo "nagios_objects is $nagios_objects"
else
    echo "Cannot locate nagios_objects in $nagios_objects. Aborting."
    exit 1
fi

source_config_file=$(echo "$nagios_config_file" )
echo "source_config_file is $source_config_file"

bnewname=$(basename $source_config_file)
echo "bnewname is $bnewname"

echo "HOST is $HOST"

bnewname2=${bnewname/remote1_/}
echo "bnewname2 is $bnewname2"

bnewname2a=${HOST}
echo "(1) bnewname2a is $bnewname2a"
bnewname2a=${bnewname2a}_$bnewname2
echo "(2) bnewname2a is $bnewname2a"

dest_config_file=${nagios_objects}/${bnewname2a}
echo "(1) dest_config_file is $dest_config_file"

if [ -f "$nagios_config_fixer" ]; then 
    echo "nagios_config_fixer is $nagios_config_fixer"
else
    echo "Cannot locate nagios_config_fixer in $nagios_config_fixer. Aborting."
    exit 1
fi

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

if [ -f "./vyperlogix_2_7.zip" ]; then 
	echo "vyperlogix_2_7.zip exists"
else
	echo "Fetching vyperlogix_2_7.zip"
    wget http://downloads.vyperlogix.com/vyperlogix/vyperlogix_2_7.zip
fi

if [ -f "$python" ]; then 
	echo "Running $nagios_config_fixer..."
	$python $nagios_config_fixer --source "$source_config_file" --dest "$dest_config_file" --host "$HOST" --alias "$HOST" --address "$NAGIOS" --library ./vyperlogix_2_7.zip
else
    echo "Cannot find python so could not execute $nagios_config_fixer. Aborting."
	exit 1
fi

#####################################################################################################
# 
source_dirname=$(dirname $source_config_file)
echo "(+++) source_dirname is $source_dirname"
host_address="host_address"
echo "(+++) host_address is $host_address"
host_address_fname=${source_dirname}$host_address
echo "(+++) host_address_fname is $host_address_fname"

if [ -f "$host_address_fname" ]; then 
	echo "host_address_fname exists in $host_address_fname"
else
    echo "Cannot find host_address_fname in $host_address_fname. Aborting."
	exit 1
fi
NAGIOS=$(cat $host_address_fname)
echo "(-->) NAGIOS is $NAGIOS"
#
#####################################################################################################

if [ -f "$python" ]; then 
	echo "Running $update_nagios_cfg..."
	$python $update_nagios_cfg "$dest_config_file"
else
    echo "Cannot find python so could not execute $update_nagios_cfg. Aborting."
	exit 1
fi

echo "service nagios stop"
service nsca stop
service nagios stop
sleep 15

pids=$(ps -ef | grep nagios | awk '{print $2}')
COUNTER=0
for p in $pids
	do
	COUNTER=$[$COUNTER +1]
	echo "($COUNTER) --> p --> $p"
done
echo "COUNTER=($COUNTER)"

echo "service nagios start"
service nagios start
service nsca start
sleep 15

pids=$(ps -ef | grep nagios | awk '{print $2}')
COUNTER=0
for p in $pids
	do
	COUNTER=$[$COUNTER +1]
	echo "($COUNTER) --> p --> $p"
done
echo "COUNTER=($COUNTER)"

plugin="$PLUGINS/check_load"
if [ -f "$plugin" ]; then 
    SERVICE='CPU Load'
    TEXT=$( ${plugin} -w 15,10,5 -c 30,25,20 )  ;
    RET=$?

    DATA=$( printf "%s\t%s\t%s\t%s\n" "$HOST" "$SERVICE" "$RET" "$TEXT" )
    echo "$DATA"
    echo "$DATA" | /usr/sbin/send_nsca -H "$NAGIOS" -p "$NSCA_PORT" -c /etc/send_nsca.cfg
fi

#echo "Stopping..."
#exit 1

plugin="$PLUGINS/check_users"
if [ -f "$plugin" ]; then 
    SERVICE='Current Users'
    TEXT=$( ${plugin} -w 20 -c 50 )  ;
    RET=$?

    DATA=$( printf "%s\t%s\t%s\t%s\n" "$HOST" "$SERVICE" "$RET" "$TEXT" )
    echo "$DATA"
	#echo "/usr/sbin/send_nsca -H \"$NAGIOS\" -p \"$NSCA_PORT\" -c /etc/send_nsca.cfg"
    echo "$DATA" | /usr/sbin/send_nsca -H "$NAGIOS" -p "$NSCA_PORT" -c /etc/send_nsca.cfg
fi

plugin="$PLUGINS/check_disk"

TARGET_PARTITIONS=$(awk '{print $4}' /proc/partitions | sed -e '/name/d' -e '/^$/d' -e '/[1-9]/!d')

for i in $TARGET_PARTITIONS
    do
    if [ -f "$plugin" ]; then 
        SERVICE="DISK_$i"
        TEXT=$( ${plugin} -w 10% -c 20% -W 20% -K 10% -p /dev/${i} )  ;
        RET=$?

        DATA=$( printf "%s\t%s\t%s\t%s\n" "$HOST" "$SERVICE" "$RET" "$TEXT" )
        echo "$DATA"
        echo "$DATA" | /usr/sbin/send_nsca -H "$NAGIOS" -p "$NSCA_PORT" -c /etc/send_nsca.cfg
    fi
done

plugin="$PLUGINS/check_ping"
if [ -f "$plugin" ]; then 
    SERVICE='PING'
    TEXT=$( ${plugin} -H 127.0.0.1 -w 100.0,60% -c 200.0,90% )  ;
    RET=$?

    DATA=$( printf "%s\t%s\t%s\t%s\n" "$HOST" "$SERVICE" "$RET" "$TEXT" )
    echo "$DATA"
    echo "$DATA" | /usr/sbin/send_nsca -H "$NAGIOS" -p "$NSCA_PORT" -c /etc/send_nsca.cfg
fi

plugin="$PLUGINS/check_ssh"
if [ -f "$plugin" ]; then 
    SERVICE='SSH'
    TEXT=$( ${plugin} -p 22 127.0.0.1 )  ;
    RET=$?

    DATA=$( printf "%s\t%s\t%s\t%s\n" "$HOST" "$SERVICE" "$RET" "$TEXT" )
    echo "$DATA"
    echo "$DATA" | /usr/sbin/send_nsca -H "$NAGIOS" -p "$NSCA_PORT" -c /etc/send_nsca.cfg
fi

plugin="$PLUGINS/check_procs"
if [ -f "$plugin" ]; then 
    SERVICE='Total Processes'
    TEXT=$( ${plugin}  )  ;
    RET=$?

    DATA=$( printf "%s\t%s\t%s\t%s\n" "$HOST" "$SERVICE" "$RET" "$TEXT" )
    echo "$DATA"
    echo "$DATA" | /usr/sbin/send_nsca -H "$NAGIOS" -p "$NSCA_PORT" -c /etc/send_nsca.cfg
fi

plugin="$PLUGINS/check_procs"
if [ -f "$plugin" ]; then 
    SERVICE='Zombie Processes'
    TEXT=$( ${plugin} -w 5 -c 10 -s Z )  ;
    RET=$?

    DATA=$( printf "%s\t%s\t%s\t%s\n" "$HOST" "$SERVICE" "$RET" "$TEXT" )
    echo "$DATA"
    echo "$DATA" | /usr/sbin/send_nsca -H "$NAGIOS" -p "$NSCA_PORT" -c /etc/send_nsca.cfg
fi

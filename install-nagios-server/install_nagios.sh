#!/bin/bash

#add the user and group for nagios process to run
echo "Adding 'nagios' user and password and creating the nagcmd group"

chmod 1777 /tmp

BUILD_DIR=~/downloads/nagios

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
	yum install -y apache2 php gcc glibc glibc-common gd gd-devel make net-snmp
	yum install -y wget build-essential php5-gd libgd2-xpm libgd2-xpm-dev libapache2-mod-php5 apache2-utils daemon chkconfig python-pip dos2unix
elif [ "${LINUX_VERSION}" = "ubuntu" ]; then
	echo "Installing for Ubuntu"
	apt-get install --yes apache2 php gcc glibc glibc-common gd gd-devel make net-snmp
	apt-get install --yes wget build-essential php5-gd libgd2-xpm libgd2-xpm-dev libapache2-mod-php5 apache2-utils daemon chkconfig python-pip dos2unix
fi

pip install dnspython
pip install web.py

useradd nagios -p nagios
groupadd nagcmd
usermod -a -G nagcmd nagios

echo "Getting the nagios and nagios-plugin code from tar balls"

workspace=$1
echo "workspace is $workspace."
fix_nagios_initd=$2
echo "fix_nagios_initd is $fix_nagios_initd."
fix_nagios_initd2=$3
echo "fix_nagios_initd2 is $fix_nagios_initd2."
fix_apache2_default_site=$4
echo "fix_apache2_default_site is $fix_apache2_default_site."
fix_nagios_cfg=$5
echo "fix_nagios_cfg is $fix_nagios_cfg."
nsca_helper_daemon=$6
echo "nsca_helper_daemon is $nsca_helper_daemon."

ServerName=$7
echo "ServerName is $ServerName."
NAGIOS_VERSION=$8
echo "NAGIOS_VERSION is $NAGIOS_VERSION."
NAGIOS_PLUGIN_VERSION=$9
echo "NAGIOS_PLUGIN_VERSION is $NAGIOS_PLUGIN_VERSION."

rm -f -R $BUILD_DIR
mkdir $BUILD_DIR
cd $BUILD_DIR

if [ -f "./nagios-$NAGIOS_VERSION.tar.gz" ]; then 
    echo "nagios-$NAGIOS_VERSION.tar.gz exists in $pwd."
else
    wget http://downloads.sourceforge.net/project/nagios/nagios-4.x/nagios-$NAGIOS_VERSION/nagios-$NAGIOS_VERSION.tar.gz
fi

USERGROUP="nagios:nagios"
NAGIOSDDIR="/usr/local/nagios"

echo "LINUX_VERSION --> ${LINUX_VERSION}"
if [ "${LINUX_VERSION}" = "centos" ]; then
	echo "Installing for CentOS."
	if [ -f "./nagios-plugins-$NAGIOS_PLUGIN_VERSION.tar.gz" ]; then 
		echo "nagios-plugins-$NAGIOS_PLUGIN_VERSION.tar.gz exists in $pwd."
	else
		wget https://www.nagios-plugins.org/download/nagios-plugins-$NAGIOS_PLUGIN_VERSION.tar.gz
	fi

	tar zxvf nagios-$NAGIOS_VERSION.tar.gz
	tar zxvf nagios-plugins-$NAGIOS_PLUGIN_VERSION.tar.gz

	cd $BUILD_DIR/nagios-$NAGIOS_VERSION

	# make and install nagios
	echo "Configuring the nagios source"

	./configure --with-command-group=nagcmd

	echo "Executing make on nagios code"

	make all

	if [ $? -eq 1 ]; then
	  echo "Nagios make all failed"
	  exit 1;
	fi

	make install

	if [ $? -eq 1 ]; then
	  echo "Nagios make install failed"
	  exit 1;
	fi

	sleep 10

	make install-init
	make install-config
	make install-commandmode
	make install-webconf

	sleep 10

	echo "Copying the eventhandlers to libexec and changing permissions on them"
	cp -R contrib/eventhandlers/ $NAGIOSDDIR/libexec/
	chown -R $USERGROUP $NAGIOSDDIR/libexec/eventhandlers

	$NAGIOSDDIR/bin/nagios -v $NAGIOSDDIR/etc/nagios.cfg

	if [ $? -eq 1 ]; then
	  echo "Nagios config file check failed."
	  exit 1;
	fi

	#make and install the plugins
	echo "Confguring the Nagios plugins"

	cd $BUILD_DIR/nagios-plugins-$NAGIOS_PLUGIN_VERSION

	./configure --with-nagios-user=nagios --with-nagios-group=nagios
	sleep 10

	echo "Executing a Make on the Nagios Plugins"
	make
	if [ $? -eq 1 ]; then
	  echo "Nagios plugin make failed"
	  exit 1;
	fi

	sleep 10

	make install

	if [ $? -eq 1 ]; then
	  echo "Nagios plugin install failed"
	  exit 1;
	fi

	sleep 10
elif [ "${LINUX_VERSION}" = "ubuntu" ]; then
	echo "Installing for Ubuntu"
	apt-get install wget build-essential php5-gd wget libgd2-xpm libgd2-xpm-dev libapache2-mod-php5 apache2-utils daemon

	tar zxvf nagios-$NAGIOS_VERSION.tar.gz

	cd $BUILD_DIR/nagios-$NAGIOS_VERSION

	./configure --with-nagios-group=nagios --with-command-group=nagcmd # -–with-mail=/usr/bin/sendmail

	make all

	make install

	make install-init

	make install-config

	make install-commandmode
	
	if [ -d "/etc/apache2" ]; then 
		echo "/etc/apache2 exists."
	else
		mkdir /etc/apache2
	fi

	if [ -d "/etc/apache2/conf.d" ]; then 
		echo "/etc/apache2/conf.d exists."
	else
		mkdir /etc/apache2/conf.d
	fi

	echo "??? /etc/apache2/conf.d/nagios.conf ???"
	if [ -f "/etc/apache2/conf.d/nagios.conf" ]; then 
		echo "Removing /etc/apache2/conf.d/nagios.conf"
		rm /etc/apache2/conf.d/nagios.conf
	fi

	make install-webconf
	
	cp -R contrib/eventhandlers/ $NAGIOSDDIR/libexec/

	chown -R $USERGROUP $NAGIOSDDIR/libexec/eventhandlers

	$NAGIOSDDIR/bin/nagios -v $NAGIOSDDIR/etc/nagios.cfg	
	
    apt-get install --yes nagios-plugins
	
	files=$(find $NAGIOSDDIR/etc | grep "~")
	for item in $files
		do
		echo "RETIRE: (item --> $item"
		rm $item
	done
fi

echo "??? /etc/apache2/conf.d/nagios.conf ???"
if [ -f "/etc/apache2/conf.d/nagios.conf" ]; then 
	echo "/etc/apache2/conf.d/nagios.conf exists."
else
	echo "??? $workspace/nagios.conf ???"
	if [ -f "$workspace/nagios.conf" ]; then 
		echo "cp $workspace/nagios.conf /etc/apache2/conf.d/nagios.conf"
		cp $workspace/nagios.conf /etc/apache2/conf.d/nagios.conf
	else
		echo "Cannot find $workspace/nagios.conf. Aborting."
		exit 1
	fi
fi

if [ -d "/etc/apache2/conf-enabled" ]; then 
	if [ -f "/etc/apache2/conf-enabled/nagios.conf" ]; then 
		unlink /etc/apache2/conf-enabled/nagios.conf
	fi
	if [ -f "/etc/apache2/conf.d/nagios.conf" ]; then 
		ln -s /etc/apache2/conf.d/nagios.conf /etc/apache2/conf-enabled/nagios.conf
	fi
	if [ -f "/etc/apache2/conf-enabled/ServerName" ]; then 
		unlink /etc/apache2/conf-enabled/ServerName
	fi
	if [ -f "/etc/apache2/conf.d/ServerName" ]; then 
		ln -s /etc/apache2/conf.d/ServerName /etc/apache2/conf-enabled/ServerName
	fi
fi

# add an admin user
#TODO - make this non-interactive and pass the pwd
echo "Adding a nagios admin user for the UI"
htpasswd -bc $NAGIOSDDIR/etc/htpasswd.users nagiosadmin nagios

ls -latr $workspace
if [ -f "$workspace/nagios.copy" ]; then 
	cp $workspace/nagios.copy /etc/init.d/nagios
else
    echo "Cannot find $workspace/nagios.copy. Aborting."
	exit 1
fi
if [ -f "/etc/init.d/nagios" ]; then 
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	sed -i 's/^\.\ \/etc\/rc.d\/init.d\/functions$/\.\ \/lib\/lsb\/init-functions/g' /etc/init.d/nagios
	sed -i 's/status\ /status_of_proc\ /g' /etc/init.d/nagios
	sed -i 's/runuser/su/g' /etc/init.d/nagios
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
else
    echo "Cannot find /etc/init.d/nagios. Aborting."
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
	
	echo "Running fix_nagios_initd.py..."
	$python $fix_nagios_initd

	echo "Running fix_nagios_initd2.py..."
	$python $fix_nagios_initd2

	echo "Running fix_apache2_default_site.py..."
	$python $fix_apache2_default_site $ServerName
	
	echo "Running fix_nagios_cfg.py..."
	$python $fix_nagios_cfg

	chown -R $USERGROUP $NAGIOSDDIR
else
    echo "Cannot find python. Aborting."
	exit 1
fi

chmod +x /etc/init.d/nagios

if [ -f "$workspace/killtree.sh" ]; then 
	cp $workspace/killtree.sh /usr/bin/killtree.sh
	chmod +x /usr/bin/killtree.sh
	ln -s /usr/bin/killtree.sh /usr/bin/killtree
else
    echo "Cannot find $workspace/killtree.sh. Aborting."
	exit 1
fi

echo "-------------------------------------------"
sed -i 's/\:80$/:8080/g' /etc/apache2/ports.conf
sed -i 's/Listen\ 80$/Listen 8080/g' /etc/apache2/ports.conf
sed -i 's/\:80>$/:8080>/g' /etc/apache2/sites-available/default
echo "=========================================="

# start apache2 and nagios
echo "Starting nagios and apache2"
chmod +x /etc/init.d/nagios
/etc/init.d/nagios start

if [ $? -eq 1 ]; then
  echo "Nagios startup failed"
  exit 1;
fi

sleep 5

/etc/init.d/apache2 start

if [ $? -eq 1 ]; then
  echo "apache2 startup failed"
  exit 1;
fi

sleep 5

if [ -f "/sbin/insserv" ]; then 
    echo "/sbin/insserv exists."
else
    ln -s /usr/lib/insserv/insserv /sbin/insserv
fi

#register nagios as a service
#echo "Registering nagios as a service"
#chkconfig --add nagios

#if [ $? -eq 1 ]; then
#  echo "nagios service registration failed"
#  exit 1;
#fi

#chkconfig --level 35 nagios on
#if [ $? -eq 1 ]; then
#  echo "nagios service registration failed"
#  exit 1;
#fi

echo "Finished installing nagios"

echo "Setting up confoguration files"

touch /etc/apache2/conf.d/ServerName
echo "ServerName $ServerName" > /etc/apache2/conf.d/ServerName

service nagios stop
service apache2 stop

sleep 5

cd $BUILD_DIR
pwd

ls -la

#echo "Finished copying the configuration files and bouncing the services."

service nagios start
service apache2 start

#exit 0

helpdir="/var/local/nsca_helper_daemon"

echo "Setting up nsca_helper_daemon"
echo "========================================================="
echo "nsca_helper_daemon --> $nsca_helper_daemon"
ls -latr $nsca_helper_daemon
echo "========================================================="
if [ -d "$nsca_helper_daemon" ]; then 
    echo "$nsca_helper_daemon exists."
    if [ -d "$helpdir" ]; then 
        echo "helpdir exists in $helpdir."
    else
        mkdir $helpdir
    fi
	#tar -zxvf "$nsca_helper_daemon" -C $helpdir
else
    echo "WARNING: Missing nsca_helper_daemon in $nsca_helper_daemon. Aborting."
	exit 1
fi

echo "========================================================="
echo "helpdir --> $helpdir"
ls -la $helpdir
echo "========================================================="
if [ -d "$helpdir" ]; then 
    echo "helpdir exists in $helpdir."
else
    echo "WARNING: Missing helpdir in $helpdir. Aborting."
	exit 1
fi

if [ -d "$helpdir/nsca-helper-daemon" ]; then 
    echo "nsca-helper-daemon exists in $helpdir/nsca-helper-daemon."
	rm -R -f $helpdir/nsca-helper-daemon
fi

cp -R $nsca_helper_daemon/* $helpdir

echo "========================================================="
echo "helpdir --> $helpdir"
ls -la $helpdir
echo "========================================================="

daemon="start-nsca-helper-daemon.sh"
stopper="stop-nsca-helper-daemon.sh"
helper="$helpdir/$daemon"
crontabber="$helpdir/establish-crontab-job.sh"
echo "helper is $helper"
if [ -f "$helper" ]; then 
    echo "$helper exists."
	chmod +x $helpdir/*.sh
	dos2unix $helpdir/*.sh
    if [ -f "/usr/bin/$daemon" ]; then 
	    echo "Unlinking /usr/bin/$daemon"
        unlink /usr/bin/$daemon
    fi
    echo "Linking /usr/bin/$daemon"
	ln -s $helper /usr/bin/$daemon
    echo "helpdir is $helpdir"
	#echo "Running $helper"
	#$helper
else
    echo "WARNING: Missing nsca_helper_daemon in $helper. Aborting."
	exit 1
fi

echo "stopper is $helpdir/$stopper"
if [ -f "$helpdir/$stopper" ]; then 
    echo "$helpdir/$stopper exists."
	chmod +x $helpdir/*.sh
	dos2unix $helpdir/*.sh
    if [ -f "/usr/bin/$stopper" ]; then 
	    echo "Unlinking /usr/bin/$stopper"
        unlink /usr/bin/$stopper
    fi
    echo "Linking /usr/bin/$stopper"
	ln -s $helpdir/$stopper /usr/bin/$stopper
else
    echo "WARNING: Missing stopper in $helpdir/$stopper. Aborting."
	exit 1
fi

echo "crontabber is $crontabber"
if [ -f "$crontabber" ]; then 
    echo "$crontabber exists."
	chmod +x $helpdir/*.sh
	dos2unix $helpdir/*.sh
	echo "Running $crontabber"
	$crontabber
else
    echo "WARNING: Missing crontabber in $crontabber. Aborting."
	exit 1
fi

exit 0

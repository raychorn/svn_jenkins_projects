#! /bin/bash

ServerName=$1
echo "ServerName is $ServerName"
s3_bucket=$2
echo "s3_bucket is $s3_bucket"
s3cfg=$3
echo "s3cfg is $s3cfg"
s3_bucket_max=$4
echo "s3_bucket is $s3_bucket"

DATE=$(date +"%Y%m%d%H%M")
echo "DATE is $DATE"

OS_VERSION_FILE=/proc/version
OS=`uname`
echo "DEBUG: OS=${OS}"
echo "DEBUG: OS_VERSION_FILE=${OS_VERSION_FILE}"
resp=$(cat "${OS_VERSION_FILE}")
echo "DEBUG: ${OS_VERSION_FILE}=${resp}"
redhat="Red Hat"
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
				grep -i "$redhat" ${OS_VERSION_FILE} 1>/dev/null 2>&1
				if [ $? -eq 0 ]; then
					LINUX_VERSION=centos
				else
					echo "${SCRIPT} only supports CentOS/Red Hat and Ubuntu at this time so cannot continue."
					exit 1
				fi
			fi
		fi
	else
		echo "Unable to find ${OS_VERSION_FILE}."
		exit 1
	fi
else
	echo "${SCRIPT} only supports Linux at this time."
	exit 1
fi

if [ "${LINUX_VERSION}" = "centos" ]; then
	echo "Installing for CentOS."
	TARGET_DIR="/etc/yum.repos.d"
	if [ -d "$TARGET_DIR" ]; then 
		echo "$TARGET_DIR exists."
	else
		echo "Cannot locate the $TARGET_DIR directory. Aborting."
		exit 1
	fi
	TARGET_REPO="$TARGET_DIR/s3tools.repo"
	if [ -f "$TARGET_REPO" ]; then 
		echo "$TARGET_REPO exists."
	else
		CWD=$(pwd)
		cd "$TARGET_DIR"
		wget http://s3tools.org/repo/RHEL_6/s3tools.repo
		cd "$CWD"
	fi
	yum -y install s3cmd
elif [ "${LINUX_VERSION}" = "ubuntu" ]; then
	echo "Installing for Ubuntu"
	apt-get install --yes s3cmd
fi

jobs_dir="/home/tomcat/.jenkins/jobs"

jobs_dir="/home/tomcat/.jenkins/jobs"

dirs=$(find / | grep jenkins | grep ".jenkins/jobs")
for item in $dirs
	do
	echo "item --> $item"
	if [ -d "$item" ]; then 
	    echo "item is $item"
		jobs_dir="$item"
		break
	fi
done

ls -latr $jobs_dir

if [ -d "$jobs_dir" ]; then 
    echo "jobs_dir exists in $jobs_dir."
else
	echo "Cannot locate the jobs_dir in $jobs_dir. Aborting."
	exit 1
fi

p=$(pwd)
echo "current working directory is $p"

files=$(ls /tmp/jenkins_jobs_*.tar.gz | awk '{print $1}')
for item in $files
	do
	#echo "item --> $item"
	if [ -f "$item" ]; then 
	    echo "item is $item"
		rm $item
	fi
done

cd $jobs_dir
tar_name="jenkins_jobs_$DATE.tar.gz"
tar_fname="/tmp/$tar_name"
tar cvzf $tar_fname .

if [ -f "$s3cfg" ]; then 
    echo "s3cfg exists in $s3cfg."
else
	echo "Cannot locate the s3cfg in $s3cfg. Aborting."
	exit 1
fi

if [ -f "/root/.s3cfg" ]; then 
    echo "/root/.s3cfg exists."
else
	echo "Cannot locate the /root/.s3cfg."
	cp $s3cfg /root/.s3cfg
	chmod 0600 /root/.s3cfg
fi

s3cmd -v put $tar_fname s3://$s3_bucket/$tar_name

S3FILES=""
files=$(s3cmd -v ls s3://$s3_bucket/ | grep jenkins_jobs_ | grep .tar.gz)
COUNTER=0
for item in $files
	do
	if [[ "$item" =~ ".tar.gz" ]]
	then
		S3FILES="$item,$S3FILES"
		COUNTER=$[$COUNTER +1]
		echo "($COUNTER) --> item --> $item"
	fi
done

echo "============================================================================"

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

IFS=$','
for item in $S3FILES
	do
	echo "item --> $item"
done

echo "S3FILES --> $S3FILES"

export S3FILES
export p
export COUNTER
export s3_bucket_max

cat << 'PYTHONEOF' > $p/handle_array.py
import os, sys

__s3_bucket_max__ = int(os.getenv('s3_bucket_max'))
print '__s3_bucket_max__=%s' % (__s3_bucket_max__)
__COUNTER__ = int(os.getenv('COUNTER'))
print '__COUNTER__=%s' % (__COUNTER__)
__p__ = os.getenv('p')
print '__p__=%s' % (__p__)
__S3FILES__ = [t for t in os.getenv('S3FILES').replace('"','').split(',') if (len(t) > 0)]
__S3FILES__.sort(lambda a,b:-1 if (a < b) else 1 if (a > b) else 0)
print '__S3FILES__=%s' % (__S3FILES__)
print 'length is %s' % (len(__S3FILES__))
fOut = open(os.sep.join([__p__,'python.out']),'w')
if (0):
    print >> fOut, 'BEGIN: (__S3FILES__)'
    for f in __S3FILES__:
        print >> fOut, f
    print >> fOut,  'END (__S3FILES__) !!!'
__retirees__ = __S3FILES__[0:-__s3_bucket_max__]
#print >> fOut,  'BEGIN: (__retirees__)'
print >> fOut, ','.join(__retirees__)
#for f in __retirees__:
#    print >> fOut, f
#print >> fOut,  'END (__retirees__) !!!'
fOut.flush()
fOut.close()
PYTHONEOF

if [ -f "$p/handle_array.py" ]; then 
    echo "$p/handle_array.py exists."
	pout=$($python $p/handle_array.py)
	echo "pout-->$pout"
else
	echo "Cannot locate the $p/handle_array.py."
fi

if [ -f "$p/python.out" ]; then 
    echo "$p/python.out exists."
	pout=$(cat $p/python.out)
	echo "pout-->$pout"
	for item in $pout
		do
		echo "RETIRE: (item --> $item"
		s3cmd del $item
	done
else
	echo "Cannot locate the $p/python.out."
fi

echo "============================================================================"

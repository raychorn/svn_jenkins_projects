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

if [ -f "$s3cfg" ]; then 
    echo "s3cfg exists in $s3cfg."
else
	echo "Cannot locate the s3cfg in $s3cfg. Aborting."
	exit 1
fi

root_s3cfg="/root/.s3cfg"
if [ -f "$root_s3cfg" ]; then 
    echo "$root_s3cfg exists."
else
	echo "Cannot locate the $root_s3cfg so creating it."
	cp $s3cfg $root_s3cfg
	chmod 0600 $root_s3cfg
fi

if [ -f "$root_s3cfg" ]; then 
    echo "$root_s3cfg exists."
else
	echo "Cannot locate the $root_s3cfg so aborting."
	exit 1
fi

file_spec=""
files=$(s3cmd -v ls s3://$s3_bucket/ | grep jenkins_jobs_ | grep .tar.gz)
for item in $files
	do
	file_spec="$item"
done

echo "file_spec=$file_spec"

tar_gz=""

IFS=$'/'
for item in $file_spec
	do
	#echo "item --> $item"
	tar_gz="$item"
done

echo "tar_gz=$tar_gz"

echo "s3cmd get $file_spec $tar_gz"
s3cmd get "$file_spec" "$tar_gz"

if [ -f "$tar_gz" ]; then 
    echo "$tar_gz exists."
	tar zxf "$tar_gz"
	rm "$tar_gz"
else
	echo "Cannot locate the $tar_gz so aborting."
	exit 1
fi

ls -latr $jobs_dir

echo "============================================================================"


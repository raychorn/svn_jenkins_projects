#!/bin/bash

jenkins_version=$1

jenkins_war=$(find / -iname jenkins.war | awk '{print $1}' | tail -n 1)

if [ -f "$jenkins_war" ]; then 
    echo "$jenkins_war exists."
else
    echo "WARNING: Missing jenkins_war in $jenkins_war. Aborting."
    exit 1
fi


if [ -d "~/downloads" ]; then 
    echo "~/downloads exists."
else
    mkdir ~/downloads
fi


cd ~/downloads
#wget http://updates.jenkins-ci.org/download/war/$jenkins_version/jenkins.war
wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war

if [ -f "jenkins.war" ]; then 
    echo "jenkins.war exists."
else
    echo "WARNING: Missing jenkins_war in $pwd. Aborting."
    exit 1
fi

service bitnami stop

echo "Deploying fresh jenkins.war to $jenkins_war"
rm -f -R /opt/bitnami/apache-tomcat/webapps/jenkins

mv jenkins.war $jenkins_war

service bitnami start

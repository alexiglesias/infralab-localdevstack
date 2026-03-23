#!/bin/bash
set -e

echo ">>> Adding hosts entries..."
echo "192.168.56.15 db01" >> /etc/hosts
echo "192.168.56.14 mc01" >> /etc/hosts
echo "192.168.56.16 rmq01" >> /etc/hosts

echo ">>> Installing Java and Maven..."
dnf update -y
dnf install -y java-17-openjdk-devel maven git

echo ">>> Installing Tomcat..."
dnf install -y tomcat tomcat-admin-webapps

echo ">>> Stopping Tomcat..."
systemctl stop tomcat

echo ">>> Cloning application source code..."
git clone -b local https://github.com/alexiglesias/vprofile-project.git /tmp/vprofile-project

echo ">>> Building application with Maven..."
cd /tmp/vprofile-project
mvn clean package -DskipTests

echo ">>> Deploying .war to Tomcat..."
rm -rf /var/lib/tomcat/webapps/ROOT
cp target/vprofile-v2.war /var/lib/tomcat/webapps/ROOT.war

echo ">>> Starting Tomcat..."
systemctl start tomcat
systemctl enable tomcat

echo ">>> Done. Tomcat is up and running."

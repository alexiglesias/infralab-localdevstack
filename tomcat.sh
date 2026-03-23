#!/bin/bash
set -e


echo ">>> Installing Java and Maven..."
apt update -y
apt install -y openjdk-17-jdk maven git


echo ">>> Installing Tomcat..."
apt install -y tomcat10 tomcat10-admin


echo ">>> Stopping Tomcat..."
systemctl stop tomcat10


echo ">>> Cloning application source code..."
git clone -b local https://github.com/alexiglesias/vprofile-project.git /tmp/vprofile-project


echo ">>> Building application with Maven..."
cd /tmp/vprofile-project
mvn clean package -DskipTests


echo ">>> Dep

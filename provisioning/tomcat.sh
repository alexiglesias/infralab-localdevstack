#!/usr/bin/env bash
#
# tomcat.sh — provision the application VM (app01) on CentOS Stream 9 (ARM).
#
# Installs Java 17, downloads Tomcat 10, builds the VProfile WAR with Maven,
# deploys it, and disables firewalld (backend VMs handle their own firewalls).

set -euo pipefail

readonly TOMURL="https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.26/bin/apache-tomcat-10.1.26.tar.gz"
readonly MAVEN_URL="https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip"

log() { printf '%s [tomcat.sh] %s\n' "$(date --iso-8601=seconds)" "$*"; }

log "installing Java 17, git, wget, rsync"
dnf -y install java-17-openjdk java-17-openjdk-devel git wget rsync unzip zip

log "downloading and installing Tomcat 10"
cd /tmp/
wget -q "$TOMURL" -O tomcatbin.tar.gz
tar xzvf tomcatbin.tar.gz
TOMDIR="apache-tomcat-10.1.26"
useradd --shell /sbin/nologin tomcat 2>/dev/null || true
rsync -avzh /tmp/"$TOMDIR"/ /usr/local/tomcat/
chown -R tomcat:tomcat /usr/local/tomcat

log "installing Tomcat systemd unit"
rm -rf /etc/systemd/system/tomcat.service
cat > /etc/systemd/system/tomcat.service << EOT
[Unit]
Description=Apache Tomcat 10
After=network.target

[Service]
User=tomcat
Group=tomcat
WorkingDirectory=/usr/local/tomcat
Environment=JAVA_HOME=/usr/lib/jvm/jre
Environment=CATALINA_HOME=/usr/local/tomcat
Environment=CATALINA_BASE=/usr/local/tomcat
ExecStart=/usr/local/tomcat/bin/catalina.sh run
ExecStop=/usr/local/tomcat/bin/shutdown.sh
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat

log "installing Maven 3.9.9"
cd /tmp/
wget -q "$MAVEN_URL"
unzip -q apache-maven-3.9.9-bin.zip
cp -r apache-maven-3.9.9 /usr/local/maven3.9
export MAVEN_OPTS="-Xmx512m"

log "cloning and building VProfile application"
git clone -b local https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project
/usr/local/maven3.9/bin/mvn install -q

log "deploying WAR to Tomcat"
systemctl stop tomcat
sleep 20
rm -rf /usr/local/tomcat/webapps/ROOT*
cp target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
systemctl start tomcat
sleep 20

log "disabling firewalld (backend VMs manage their own ports)"
systemctl stop firewalld
systemctl disable firewalld

systemctl restart tomcat
log "Tomcat provisioning complete"

#!/usr/bin/env bash
#
# mysql.sh — provision the database VM (db01) on CentOS Stream 9 (ARM).
#
# Installs MariaDB, creates the application database and user,
# imports the seed schema from the vprofile repo, and opens firewalld
# for port 3306.

set -euo pipefail

readonly DATABASE_PASS='admin123'

log() { printf '%s [mysql.sh] %s\n' "$(date --iso-8601=seconds)" "$*"; }

log "updating system packages"
yum update -y
yum install -y epel-release git zip unzip

log "installing MariaDB"
yum install -y mariadb-server

log "starting and enabling MariaDB"
systemctl start mariadb
systemctl enable mariadb

log "cloning vprofile repo to get db_backup.sql"
cd /tmp/
git clone -b main https://github.com/hkhcoder/vprofile-project.git

log "securing MariaDB and creating application database"
mysqladmin -u root password "$DATABASE_PASS"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE accounts"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'localhost' IDENTIFIED BY 'admin123'"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123'"
mysql -u root -p"$DATABASE_PASS" accounts < /tmp/vprofile-project/src/main/resources/db_backup.sql
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

log "restarting MariaDB"
systemctl restart mariadb

log "configuring firewalld to allow port 3306"
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --zone=public --add-port=3306/tcp --permanent
firewall-cmd --reload

systemctl restart mariadb
log "MariaDB provisioning complete"

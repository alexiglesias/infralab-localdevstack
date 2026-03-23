#!/bin/bash
set -e

DATABASE_PASS='infralab2024'

echo ">>> Installing MariaDB..."
dnf update -y
dnf install -y mariadb-server git

echo ">>> Starting MariaDB..."
systemctl start mariadb
systemctl enable mariadb

echo ">>> Securing MariaDB..."
mysqladmin -u root password "$DATABASE_PASS"
mysql -u root -p"$DATABASE_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DATABASE_PASS'"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

echo ">>> Creating database and user..."
mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE accounts"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'localhost' IDENTIFIED BY 'infralab2024'"
mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'infralab2024'"
mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

echo ">>> Importing database dump..."
mysql -u root -p"$DATABASE_PASS" accounts < /vagrant/db_backup.sql

echo ">>> Restarting MariaDB..."
systemctl restart mariadb

echo ">>> Done. MariaDB is up and running."

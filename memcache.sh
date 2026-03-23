#!/bin/bash
set -e

echo ">>> Installing Memcache..."
dnf update -y
dnf install -y memcached libmemcached

echo ">>> Starting Memcache..."
systemctl start memcached
systemctl enable memcached

echo ">>> Configuring Memcache to listen on all interfaces..."
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached

echo ">>> Restarting Memcache..."
systemctl restart memcached

echo ">>> Done. Memcache is up and running."

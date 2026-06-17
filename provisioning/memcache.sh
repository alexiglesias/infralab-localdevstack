#!/usr/bin/env bash
#
# memcache.sh — provision the Memcached VM (mc01) on CentOS Stream 9 (ARM).
#
# Installs Memcached, opens it on port 11211, and configures firewalld.

set -euo pipefail

log() { printf '%s [memcache.sh] %s\n' "$(date --iso-8601=seconds)" "$*"; }

log "installing epel and memcached"
dnf install -y epel-release
dnf install -y memcached

log "starting and enabling memcached"
systemctl start memcached
systemctl enable memcached

log "configuring memcached to listen on all interfaces"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached

systemctl restart memcached

log "configuring firewalld to allow port 11211"
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --add-port=11211/tcp --permanent
firewall-cmd --add-port=11111/udp --permanent
firewall-cmd --reload

sudo memcached -p 11211 -U 11111 -u memcached -d
log "Memcached provisioning complete"

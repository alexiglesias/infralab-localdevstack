#!/usr/bin/env bash
#
# rabbitmq.sh — provision the RabbitMQ VM (rmq01) on CentOS Stream 9 (ARM).
#
# Installs RabbitMQ from the CentOS RabbitMQ repo, creates the application
# user, and opens firewalld for port 5672.

set -euo pipefail

log() { printf '%s [rabbitmq.sh] %s\n' "$(date --iso-8601=seconds)" "$*"; }

log "installing dependencies"
yum install -y epel-release wget

log "installing RabbitMQ from centos-rabbitmq repo"
dnf -y install centos-release-rabbitmq-38
dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server

log "starting and enabling RabbitMQ"
systemctl enable --now rabbitmq-server

log "configuring firewalld to allow port 5672"
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --add-port=5672/tcp --permanent
firewall-cmd --reload

log "allowing remote connections and creating application user"
sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'
rabbitmqctl add_user test test
rabbitmqctl set_user_tags test administrator
rabbitmqctl set_permissions -p / test ".*" ".*" ".*"

systemctl restart rabbitmq-server
log "RabbitMQ provisioning complete"

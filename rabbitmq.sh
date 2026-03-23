#!/bin/bash
set -e

echo ">>> Installing RabbitMQ..."
dnf update -y
dnf install -y epel-release
dnf install -y rabbitmq-server

echo ">>> Starting RabbitMQ..."
systemctl start rabbitmq-server
systemctl enable rabbitmq-server

echo ">>> Configuring RabbitMQ..."
sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'

echo ">>> Creating RabbitMQ user..."
rabbitmqctl add_user infralab infralab2024
rabbitmqctl set_user_tags infralab administrator
rabbitmqctl set_permissions -p / infralab ".*" ".*" ".*"

echo ">>> Restarting RabbitMQ..."
systemctl restart rabbitmq-server

echo ">>> Done. RabbitMQ is up and running."

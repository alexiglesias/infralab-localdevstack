#!/usr/bin/env bash
#
# nginx.sh — provision the web VM (web01) on Ubuntu ARM (spox/ubuntu-arm).
#
# Installs Nginx and configures it as a reverse proxy to app01:8080.

set -euo pipefail

log() { printf '%s [nginx.sh] %s\n' "$(date --iso-8601=seconds)" "$*"; }

export DEBIAN_FRONTEND=noninteractive

log "installing Nginx"
apt update -y -q
apt install -y -q nginx

log "writing Nginx reverse-proxy configuration"
cat > /etc/nginx/sites-available/vproapp << 'EOT'
upstream vproapp {
  server app01:8080;
}

server {
  listen 80;

  location / {
    proxy_pass http://vproapp;
  }
}
EOT

rm -rf /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/vproapp

log "starting and enabling Nginx"
systemctl start nginx
systemctl enable nginx
systemctl restart nginx
log "Nginx provisioning complete"

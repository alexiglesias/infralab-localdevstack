#!/bin/bash
set -e

echo ">>> Adding hosts entries..."
echo "192.168.56.12 app01" >> /etc/hosts
echo "192.168.56.15 db01" >> /etc/hosts
echo "192.168.56.14 mc01" >> /etc/hosts
echo "192.168.56.16 rmq01" >> /etc/hosts

echo ">>> Installing Nginx..."
apt update -y
apt install -y nginx


echo ">>> Configuring reverse proxy..."
cat > /etc/nginx/sites-available/infralab <<EOF
upstream app {
    server app01:8080;
}


server {
    listen 80;


    location / {
        proxy_pass http://app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF


echo ">>> Enabling site..."
rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/infralab /etc/nginx/sites-enabled/infralab


echo ">>> Starting Nginx..."
systemctl start nginx
systemctl enable nginx
systemctl restart nginx


echo ">>> Done. Nginx is up and running."

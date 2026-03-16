#!/bin/bash

clear

echo "#################################################"
echo "#            VOLYX CONVOY INSTALLER              #"
echo "#         High Performance Game Hosting          #"
echo "#               https://volyx.host               #"
echo "#################################################"
echo ""

# Root check
if [[ $EUID -ne 0 ]]; then
   echo "❌ Please run this script as root"
   exit 1
fi

echo ""
read -p "Enter your Convoy Panel Domain (example: panel.domain.com): " DOMAIN
echo ""

echo "Installing required packages..."
apt update -y
apt install -y curl wget git nginx certbot python3-certbot-nginx docker.io docker-compose

systemctl enable docker
systemctl start docker

echo ""
echo "Downloading Convoy Panel..."
mkdir -p /var/www/convoy
cd /var/www/convoy

curl -L https://github.com/convoypanel/panel/releases/latest/download/panel.tar.gz | tar -xzv

cp .env.example .env

sed -i "s|APP_URL=.*|APP_URL=https://$DOMAIN|g" .env

echo ""
echo "Generating application key..."
docker compose run --rm app php artisan key:generate

echo ""
echo "Starting Convoy containers..."
docker compose up -d

echo ""
echo "Installing SSL..."
certbot --nginx -d $DOMAIN

echo ""
echo "#################################################"
echo "✅ Volyx Convoy Panel Installed Successfully!"
echo "🌐 Panel URL: https://$DOMAIN"
echo "#################################################"

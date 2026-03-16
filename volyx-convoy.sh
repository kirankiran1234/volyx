#!/bin/bash

clear
echo "======================================"
echo "        VOLYX CONVOY INSTALLER"
echo "         https://volyx.host"
echo "======================================"

if [[ $EUID -ne 0 ]]; then
 echo "Run as root"
 exit
fi

read -p "Enter your domain (example: panel.domain.com): " DOMAIN

echo ""
echo "Installing dependencies..."
apt update -y
apt install -y curl wget git unzip

echo ""
echo "Installing Docker..."
curl -fsSL https://get.docker.com | sh

echo ""
echo "Creating Convoy directory..."
mkdir -p /var/www/convoy
cd /var/www/convoy

echo ""
echo "Downloading Convoy panel..."
wget https://github.com/convoypanel/panel/archive/refs/heads/main.zip -O convoy.zip

unzip convoy.zip
mv panel-main/* .
rm -rf panel-main convoy.zip

echo ""
echo "Setting permissions..."
chmod -R 777 storage bootstrap/cache

echo ""
echo "Creating env file..."
cp .env.example .env

sed -i "s|APP_URL=.*|APP_URL=http://$DOMAIN|g" .env

echo ""
echo "Starting containers..."
docker compose up -d

echo ""
echo "Installing dependencies..."
docker compose exec workspace bash -c "composer install --no-dev --optimize-autoloader"

echo ""
echo "Generating key..."
docker compose exec workspace bash -c "php artisan key:generate --force"

echo ""
echo "Migrating database..."
docker compose exec workspace php artisan migrate --force

echo ""
echo "Optimizing panel..."
docker compose exec workspace php artisan optimize

echo ""
echo "Creating admin user..."
docker compose exec workspace php artisan c:user:make

echo ""
echo "======================================"
echo "Convoy installed successfully!"
echo "Open: http://$DOMAIN"
echo "======================================"

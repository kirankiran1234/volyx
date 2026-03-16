#!/bin/bash

clear
echo "======================================"
echo "        VOLYX CONVOY INSTALLER"
echo "         https://volyx.host"
echo "======================================"

if [ "$EUID" -ne 0 ]; then
 echo "Please run this script as root"
 exit
fi

read -p "Enter your panel domain (example: panel.domain.com): " DOMAIN

echo "Updating system..."
apt update -y
apt upgrade -y

echo "Installing dependencies..."
apt install -y curl wget git unzip ca-certificates

echo "Installing Docker..."
curl -fsSL https://get.docker.com | sh

echo "Installing Docker Compose..."
apt install -y docker-compose-plugin

echo "Creating panel directory..."
mkdir -p /var/www/convoy
cd /var/www/convoy

echo "Cleaning old installation..."
rm -rf *

echo "Downloading Convoy panel..."
curl -L https://github.com/convoypanel/panel/releases/latest/download/panel.tar.gz -o panel.tar.gz

echo "Extracting files..."
tar -xzvf panel.tar.gz
rm panel.tar.gz

echo "Setting permissions..."
chmod -R 775 storage bootstrap/cache

echo "Creating environment file..."
cp .env.example .env

echo "Configuring environment..."
sed -i "s|APP_URL=.*|APP_URL=http://$DOMAIN|g" .env
sed -i "s|APP_ENV=.*|APP_ENV=production|g" .env
sed -i "s|APP_DEBUG=.*|APP_DEBUG=false|g" .env

echo "Starting Docker containers..."
docker compose up -d

echo "Waiting for containers to start..."
sleep 30

echo "Installing dependencies..."
docker compose exec workspace composer install --no-dev --optimize-autoloader

echo "Generating app key..."
docker compose exec workspace php artisan key:generate --force

echo "Running database migration..."
docker compose exec workspace php artisan migrate --force

echo "Optimizing application..."
docker compose exec workspace php artisan optimize

echo ""
echo "======================================"
echo " Convoy Panel Installed Successfully!"
echo " Panel URL: http://$DOMAIN"
echo ""
echo "Create admin user with:"
echo "docker compose exec workspace php artisan c:user:make"
echo "======================================"

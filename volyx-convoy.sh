#!/bin/bash

clear

echo "======================================"
echo "        VOLYX CONVOY INSTALLER"
echo "         https://volyx.host"
echo "======================================"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

read -p "Enter your panel domain (example: panel.domain.com): " DOMAIN

echo "Updating system..."
apt update -y
apt upgrade -y

apt install -y curl wget git unzip

echo "Installing Docker..."
curl -fsSL https://get.docker.com | sh

echo "Installing Docker Compose..."
apt install -y docker-compose-plugin

echo "Creating panel directory..."
mkdir -p /var/www/convoy
cd /var/www/convoy

echo "Cleaning old files..."
rm -rf *

echo "Downloading Convoy panel..."
curl -Lo panel.tar.gz https://github.com/convoypanel/panel/releases/latest/download/panel.tar.gz

echo "Extracting panel..."
tar -xzvf panel.tar.gz

echo "Setting permissions..."
chmod -R 777 storage bootstrap/cache

echo "Creating environment file..."
cp .env.example .env

sed -i "s|APP_URL=.*|APP_URL=http://$DOMAIN|g" .env

echo "Starting docker containers..."
docker compose up -d

echo "Waiting for containers..."
sleep 25

echo "Installing dependencies..."
docker compose exec workspace bash -c "composer install --no-dev --optimize-autoloader"

echo "Generating application key..."
docker compose exec workspace bash -c "php artisan key:generate --force"

echo "Running database migration..."
docker compose exec workspace php artisan migrate --force

echo "Optimizing..."
docker compose exec workspace bash -c "php artisan optimize"

echo ""
echo "======================================"
echo "Convoy Panel Installed Successfully!"
echo "Open: http://$DOMAIN"
echo ""
echo "Create admin user with:"
echo "docker compose exec workspace php artisan c:user:make"
echo "======================================"

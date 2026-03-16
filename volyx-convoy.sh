#!/bin/bash

clear

echo "====================================="
echo "       VOLYX CONVOY INSTALLER"
echo "        https://volyx.host"
echo "====================================="
echo ""

if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root"
  exit
fi

read -p "Enter your panel domain (example: panel.domain.com): " DOMAIN

echo ""
echo "Installing Docker..."
curl -fsSL https://get.docker.com/ | sh

echo ""
echo "Creating Convoy directory..."
mkdir -p /var/www/convoy
cd /var/www/convoy

echo ""
echo "Downloading Convoy Panel..."
curl -Lo panel.tar.gz https://github.com/convoypanel/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz

chmod -R o+w storage/* bootstrap/cache/

echo ""
echo "Creating environment file..."
cp .env.example .env

sed -i "s|APP_URL=.*|APP_URL=http://$DOMAIN|g" .env

echo ""
echo "Starting Docker containers..."
docker compose up -d

echo ""
echo "Installing dependencies..."
docker compose exec workspace bash -c "composer install --no-dev --optimize-autoloader"

echo ""
echo "Generating application key..."
docker compose exec workspace bash -c "php artisan key:generate --force && php artisan optimize"

echo ""
echo "Running database migration..."
docker compose exec workspace php artisan migrate --force

echo ""
echo "Rebuilding containers..."
docker compose down
docker compose up -d --build
docker compose exec workspace bash -c "php artisan optimize"

echo ""
echo "Creating admin user..."
docker compose exec workspace php artisan c:user:make

echo ""
echo "====================================="
echo "Convoy Panel Installed Successfully!"
echo "Open: http://$DOMAIN"
echo "====================================="

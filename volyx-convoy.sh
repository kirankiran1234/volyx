#!/usr/bin/env bash
set -e

clear
echo "======================================"
echo "        VOLYX CONVOY INSTALLER"
echo "         https://volyx.host"
echo "======================================"

if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run as root"
  exit 1
fi

read -rp "Enter your panel domain (example: panel.domain.com): " DOMAIN

echo "➡️ Installing dependencies..."
apt update -y
apt install -y curl wget git unzip ca-certificates

echo "➡️ Installing Docker..."
curl -fsSL https://get.docker.com | sh

echo "➡️ Ensuring docker compose plugin..."
apt install -y docker-compose-plugin || true

echo "➡️ Preparing directory..."
mkdir -p /var/www/convoy
cd /var/www/convoy

echo "➡️ Cleaning old files (if any)..."
rm -rf /var/www/convoy/*

echo "➡️ Cloning Convoy panel..."
git clone https://github.com/convoypanel/panel.git .

echo "➡️ Setting permissions..."
chmod -R o+w storage bootstrap/cache || true

echo "➡️ Creating environment file..."
cp .env.example .env

sed -i "s|APP_URL=.*|APP_URL=http://$DOMAIN|g" .env

echo "➡️ Starting Docker containers..."
docker compose up -d

echo "⏳ Waiting for containers to boot..."
sleep 15

echo "➡️ Installing PHP dependencies..."
docker compose exec workspace composer install --no-dev --optimize-autoloader

echo "➡️ Generating app key..."
docker compose exec workspace php artisan key:generate --force

echo "➡️ Running database migrations..."
docker compose exec workspace php artisan migrate --force

echo "➡️ Optimizing panel..."
docker compose exec workspace php artisan optimize

echo "======================================"
echo "✅ Convoy installed successfully!"
echo "🌐 Open: http://$DOMAIN"
echo ""
echo "➡️ Create admin user now:"
echo "docker compose exec workspace php artisan c:user:make"
echo "======================================"

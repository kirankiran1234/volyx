#!/bin/bash

clear
echo "======================================"
echo "        VOLYX CONVOY INSTALLER"
echo "         https://volyx.host"
echo "======================================"

read -p "Enter your panel domain (example: panel.domain.com): " DOMAIN

echo "Updating system..."
apt clean
rm -rf /var/lib/apt/lists/*
apt update -y

echo "Installing required packages..."
apt install -y curl wget sudo unzip gnupg ca-certificates software-properties-common

echo "Installing Docker..."
curl -fsSL https://get.docker.com | sh

systemctl enable docker
systemctl start docker

echo "Cleaning old docker containers..."
docker stop $(docker ps -aq) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null
docker system prune -a -f

echo "Creating Convoy directory..."
mkdir -p /opt/convoy
cd /opt/convoy

echo "Downloading Convoy..."
curl -L https://github.com/convoypanel/panel/archive/refs/heads/main.tar.gz -o convoy.tar.gz
tar -xzf convoy.tar.gz --strip-components=1
rm convoy.tar.gz

echo "Creating environment file..."
cp .env.example .env

sed -i "s|APP_URL=.*|APP_URL=http://$DOMAIN|g" .env

echo "Starting Docker containers..."
docker compose up -d --build

echo "Waiting for containers..."
sleep 20

echo "Running setup commands..."
docker compose exec workspace php artisan key:generate
docker compose exec workspace php artisan migrate --force

echo "======================================"
echo " Convoy Panel Installed Successfully!"
echo " Open: http://$DOMAIN"
echo "======================================"

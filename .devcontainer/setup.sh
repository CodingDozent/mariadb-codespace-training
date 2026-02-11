#!/usr/bin/env bash
set -e

echo "Installing MariaDB..."
sudo apt-get update
sudo apt-get install -y mariadb-server mariadb-client

echo "Configuring MariaDB..."
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

echo "Starting MariaDB..."
sudo mysqld_safe --skip-networking=0 --skip-bind-address &

sleep 5

echo "Creating training database..."
mysql -u root -e "CREATE DATABASE IF NOT EXISTS training;"

echo "Installing phpMyAdmin..."
sudo apt-get install -y phpmyadmin php-mbstring php-zip php-gd php-json php-curl

echo "Starting phpMyAdmin on port 8080..."
php -S 0.0.0.0:8080 -t /usr/share/phpmyadmin &

echo "Setup complete."

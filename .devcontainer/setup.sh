#!/usr/bin/env bash
set -e

echo "=== Updating package lists ==="
sudo apt-get update -y

echo "=== Installing MariaDB server and client ==="
sudo apt-get install -y mariadb-server mariadb-client

echo "=== Adjusting MariaDB bind-address for Codespaces ==="
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf || true

echo "=== Starting MariaDB in safe mode ==="
sudo mysqld_safe --skip-networking=0 --skip-bind-address &
sleep 5

echo "=== Setting MariaDB root password ==="
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
FLUSH PRIVILEGES;
EOF

echo "=== Creating training database ==="
mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS training;"

echo "=== Installing PHP extensions ==="
sudo apt-get install -y wget unzip php-mbstring php-zip php-gd php-json php-curl

echo "=== Downloading phpMyAdmin ==="
wget -q https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip -O /tmp/pma.zip

echo "=== Extracting phpMyAdmin ==="
unzip -q /tmp/pma.zip -d /tmp
sudo rm -rf /usr/share/phpmyadmin
sudo mv /tmp/phpMyAdmin-*-all-languages /usr/share/phpmyadmin

echo "=== Preparing phpMyAdmin temp directory ==="
sudo mkdir -p /usr/share/phpmyadmin/tmp
sudo chmod 777 /usr/share/phpmyadmin/tmp

echo "=== Creating phpMyAdmin config.inc.php ==="
sudo tee /usr/share/phpmyadmin/config.inc.php >/dev/null <<'EOF'
<?php
$cfg['blowfish_secret'] = 'supersecretblowfishkey1234567890'; 
$cfg['Servers'][1]['auth_type'] = 'cookie';
$cfg['Servers'][1]['host'] = '127.0.0.1';
$cfg['Servers'][1]['AllowNoPassword'] = false;
EOF

echo "=== Starting phpMyAdmin on port 8080 ==="
php -S 0.0.0.0:8080 -t /usr/share/phpmyadmin &
sleep 2

echo "=== Setup complete ==="
echo "MariaDB is running with root/root"
echo "phpMyAdmin is available on port 8080"

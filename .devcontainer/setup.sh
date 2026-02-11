#!/usr/bin/env bash
set -e

LOGFILE=/tmp/codespace-setup.log
echo "=== Setup started ===" | tee $LOGFILE

log() {
  echo "$1"
  echo "$1" >> $LOGFILE
}

log "Updating package lists..."
sudo apt-get update -y >> $LOGFILE 2>&1

log "Installing MariaDB..."
sudo apt-get install -y mariadb-server mariadb-client >> $LOGFILE 2>&1

log "Configuring MariaDB..."
sudo sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf || true

log "Starting MariaDB..."
sudo mysqld_safe --skip-networking=0 --skip-bind-address >> $LOGFILE 2>&1 &
sleep 5

log "Setting root password..."
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
FLUSH PRIVILEGES;
EOF

log "Creating training database..."
mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS training;" >> $LOGFILE 2>&1

log "Enabling full Debian Trixie repositories for PHP..."
echo "deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/trixie-full.list
echo "deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list.d/trixie-full.list
echo "deb http://deb.debian.org/debian-security trixie-security main contrib non-free non-free-firmware" | sudo tee -a /etc/apt/sources.list.d/trixie-full.list

sudo apt-get update >> $LOGFILE 2>&1

log "Installing PHP extensions (Debian Trixie)..."
sudo apt-get install -y \
  php8.4-mbstring \
  php8.4-zip \
  php8.4-gd \
  php8.4-curl \
  php8.4-mysql \
  php8.4-xml \
  php8.4-intl \
  php8.4-common \
  php8.4-cli >> $LOGFILE 2>&1


log "Downloading phpMyAdmin..."
wget -q https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip -O /tmp/pma.zip

log "Extracting phpMyAdmin..."
unzip -q /tmp/pma.zip -d /tmp
sudo rm -rf /usr/share/phpmyadmin
sudo mv /tmp/phpMyAdmin-*-all-languages /usr/share/phpmyadmin

log "Preparing phpMyAdmin temp directory..."
sudo mkdir -p /usr/share/phpmyadmin/tmp
sudo chmod 777 /usr/share/phpmyadmin/tmp

log "Creating phpMyAdmin config..."
sudo tee /usr/share/phpmyadmin/config.inc.php >/dev/null <<'EOF'
<?php
$cfg['blowfish_secret'] = 'supersecretblowfishkey1234567890';
$cfg['Servers'][1]['auth_type'] = 'cookie';
$cfg['Servers'][1]['host'] = '127.0.0.1';
$cfg['Servers'][1]['AllowNoPassword'] = false;
EOF

log "Starting phpMyAdmin on port 8080..."
php -S 0.0.0.0:8080 -t /usr/share/phpmyadmin >> $LOGFILE 2>&1 &
sleep 2

log "=== Setup complete ==="
log "MariaDB root password: root"
log "phpMyAdmin running on port 8080"

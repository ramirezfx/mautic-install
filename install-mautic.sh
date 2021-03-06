# VARIABLES
MAUTICDLURL="https://github.com/mautic/mautic/releases/download/4.1.1/4.1.1-update.zip"
MAUTICFILENAME="4.1.1-update.zip"
MAUTICDB="mautic"
MAUTICUSER="mauticuser"
MAUTICPWD="mauticpassword"
YOURSERVERNAME="mautic.speedypreneur.com"
YOUREMAIL="yourmail@example.om"

# Install LEMP

sudo apt update
sudo apt upgrade

# Install NGINX
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
sudo ufw allow http
sudo chown www-data:www-data /usr/share/nginx/html -R

#Install MariaDB
sudo apt install -y mariadb-server mariadb-client
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql_secure_installation

#Install PHP7.4
sudo apt install -y php7.4 php7.4-fpm php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline php7.4-mbstring php7.4-xml php7.4-gd php7.4-curl
sudo systemctl start php7.4-fpm
sudo systemctl enable php7.4-fpm

#Create NGINX Server Block
sudo rm /etc/nginx/sites-enabled/default
cp default.conf /etc/nginx/conf.d/
sudo systemctl reload nginx

#NGINX Automatic Restart
sudo mkdir -p /etc/systemd/system/nginx.service.d/
cp restart.conf /etc/systemd/system/nginx.service.d/

# Download Mautic

wget $MAUTICDLURL
sudo apt install unzip
sudo mkdir -p /var/www/mautic/
sudo unzip $MAUTICFILENAME -d /var/www/mautic/
sudo chown -R www-data:www-data /var/www/mautic/

# CREATE DATABASE AND USER
cp mautic.sql.template mautic.sql
sed -i 's/MAUTICDB/'$MAUTICDB'/g' mautic.sql
sed -i 's/DBUSER/'$MAUTICUSER'/g' mautic.sql
sed -i 's/DBPASSWORD/'$MAUTICPWD'/g' mautic.sql
mysql -u root < mautic.sql

# Install required and recommended PHP Modules
sudo apt install -y php-imagick php7.4-fpm php7.4-mysql php7.4-common php7.4-gd php7.4-imap php7.4-imap php7.4-json php7.4-curl php7.4-zip php7.4-xml php7.4-mbstring php7.4-bz2 php7.4-intl php7.4-gmp
cp mautic.conf.template mautic.conf
sed -i 's/YOURSERVERNAME/'$YOURSERVERNAME'/g' mautic.conf
cp mautic.conf /etc/nginx/conf.d/

# Fix PHP memory-limit
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/7.4/fpm/php.ini
sudo systemctl reload nginx
sudo systemctl reload php7.4-fpm

# Enable HTTPS
sudo apt install -y certbot
sudo mkdir -p /var/www/mautic/.well-known/acme-challenge
sudo chown www-data:www-data /var/www/mautic/.well-known/acme-challenge
sudo apt install -y python3-certbot-nginx
sudo certbot --nginx --agree-tos --redirect --hsts --staple-ocsp --email $YOUREMAIL -d $YOURSERVERNAME
sudo sed -i 's/443 ssl/443 ssl http2/g' /etc/nginx/conf.d/mautic.conf
sudo systemctl reload nginx

# Create Cron-Jobs for mautic
cat mautic-cron >> /etc/crontab

echo "Installation finished! You can start the web-installer by pointing your browser to"
echo "https://"$YOURSERVERNAME"/mautic"

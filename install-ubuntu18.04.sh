#!/usr/bin/env bash
## Install MediaWiki 1.31 on Ubuntu 18.04

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get -y install sudo

sudo apt-get -y install mysql-server 
# sudo apt-get -y install apache2 mariadb-server -y # has issues on containers (need privledge)
#sudo apt-get install apache2 mysql-server php php-mysql libapache2-mod-php php-xml php-mbstring
sudo apt-get -y install apache2 php php-mysql libapache2-mod-php php-xml php-mbstring php-gd php-zip php-xml php-soap php-xmlrpc libapache2-mod-php php-curl php-apcu git 

sudo cp /etc/php/7.2/apache2/php.ini /etc/php/7.2/apache2/php.ini.o
sudo cat >/etc/php/7.2/apache2/php.ini <<EOL
memory_limit = 256M
upload_max_filesize = 100M
max_execution_time = 360
date.timezone = UTC 
EOL

mysql -h localhost -u root <<EOL
CREATE DATABASE wiki;
CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'wiki';
GRANT ALL ON wiki.* TO 'wiki'@'localhost' WITH GRANT OPTION;
EOL

wget https://releases.wikimedia.org/mediawiki/1.31/mediawiki-1.31.0.tar.gz
tar -xvzf mediawiki-1.31.0.tar.gz
sudo cp -r mediawiki-1.31.0 /var/www/html/wiki
sudo chown -R www-data:www-data /var/www/html/wiki
sudo chmod -R 777 /var/www/html/wiki

sudo cat >/etc/apache2/sites-available/wiki.conf <<EOL
<VirtualHost *:80>
  ServerAdmin admin@example.com
  DocumentRoot /var/www/html/wiki/
  ServerName example.com
  <Directory /var/www/html/wiki/>
  Options +FollowSymLinks
  AllowOverride All
  </Directory>
  ErrorLog /var/log/apache2/media-error_log
  CustomLog /var/log/apache2/media-access_log common
</VirtualHost>

<Directory "/var/www/html/wiki/Library/MediaWiki/web/images">
  # Ignore .htaccess files
  AllowOverride None
  
  # Serve HTML as plaintext, don't execute SHTML
  AddType text/plain .html .htm .shtml .phtml .php .php3 .php4 .php5 .php7
  
  # Don't run arbitrary PHP code.
  php_admin_flag engine off
  
  # If you've other scripting languages, disable them too.
</Directory>
EOL

sudo a2ensite wiki.conf
sudo a2enmod rewrite
sudo systemctl restart apache2


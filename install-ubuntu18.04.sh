sudo apt-get update
sudo -y apt-get upgrade
#sudo apt-get install apache2 mysql-server php php-mysql libapache2-mod-php php-xml php-mbstring

sudo apt-get -y install mysql-server
# sudo apt-get -y install apache2 mariadb-server -y # has issues on containers (need privledge)

# mkdir /var/lib/mysql-files
# chown -R mysql:mysql /var/lib/mysql-files/
# chmod 700 /var/lib/mysql-files/


sudo apt-get update
sudo apt-get -y install php7.2 libapache2-mod-php7.2 php7.2-common php7.2-mbstring php7.2-xmlrpc php7.2-soap php7.2-gd php7.2-xml php7.2-intl php7.2-mysql php7.2-cli php7.2-mcrypt php7.2-zip php7.2-curl -y

sudo cp /etc/php/7.2/apache2/php.ini /etc/php/7.2/apache2/php.ini.o
sudo cat >/etc/php/7.2/apache2/php.ini <<EOL
memory_limit = 256M
upload_max_filesize = 100M
max_execution_time = 360
date.timezone = UTC 
EOL

# Do not need as it is done by auto
# sudo systemctl start apache2
# sudo systemctl enable apache2
# sudo systemctl start mysql
# sudo systemctl enable mysql

#sudo mysql_secure_installation
#mysql -u root -p

mysql -h localhost -u root wiki <<EOL
CREATE DATABASE wiki
CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'wiki';
GRANT ALL ON mediadb.* TO 'media'@'localhost' IDENTIFIED BY 'wikime' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
EOL


wget https://releases.wikimedia.org/mediawiki/1.31/mediawiki-1.31.0.tar.gz
tar -xvzf mediawiki-1.31.0.tar.gz
#tar -C /var/www/html/ -xvzf mediawiki-1.31.0.tar.gz

sudo cp -r mediawiki-1.31.0 /var/www/html/wiki
sudo chown -R www-data:www-data /var/www/html/wiki
sudo chmod -R 777 /var/www/html/wiki

#sudo nano /etc/apache2/sites-available/mediawiki.conf
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
EOL

sudo a2ensite wiki.conf
sudo a2enmod rewrite

sudo systemctl restart apache2

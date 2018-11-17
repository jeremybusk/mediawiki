#!/bin/bash
# https://github.com/rDuckDev/MediaWiki-on-Ubuntu/blob/master/install.sh

NoC="\033[0m"
RED="\033[0;31m"
GRN="\033[0;32m"
ORG="\033[0;33m"
BLU="\033[0;34m"

echo -e "${BLU}Installing MediaWiki${NoC}"
read -p "Enter the name of your wiki: " WIKI_NAME
echo
cd /var/www/html/
wget https://releases.wikimedia.org/mediawiki/1.31/mediawiki-1.31.0.tar.gz
tar -xvzf mediawiki-1.31.0.tar.gz
rm mediawiki-1.31.0.tar.gz
mv mediawiki-1.31.0 $WIKI_NAME

echo -e "${BLU}Installing MediaWiki extensions${NoC}"
read -p "Press any key to continue..." -n 1 -r
echo
# VisualEditor https://www.mediawiki.org/wiki/Extension:VisualEditor
echo -e "${BLU}VisualEditor${NoC}"
cd /var/www/html/$WIKI_NAME/extensions
git clone https://github.com/wikimedia/mediawiki-extensions-VisualEditor.git --branch REL1_31 --depth 1 VisualEditor
cd VisualEditor
git submodule update --init
# RevisionSlider https://www.mediawiki.org/wiki/Extension:RevisionSlider
echo -e "${BLU}RevisionSlider${NoC}"
cd /var/www/html/$WIKI_NAME/extensions
git clone https://github.com/wikimedia/mediawiki-extensions-RevisionSlider.git --branch REL1_31 --depth 1 RevisionSlider
cd RevisionSlider
composer install --no-dev
npm install

echo -e "${BLU}Fixing file permissions${NoC}"
read -p "Press any key to continue..." -n 1 -r
echo
echo -e "${ORG}Please wait...${NoC}"
chown -R root:www-data /var/www/html/$WIKI_NAME
chown -R www-data:www-data /var/www/html/$WIKI_NAME/cache
chown -R www-data:www-data /var/www/html/$WIKI_NAME/images
find /var/www/html/$WIKI_NAME -type d -exec chmod 750 {} \;
find /var/www/html/$WIKI_NAME -type f -exec chmod 640 {} \;

echo -e "${BLU}Creating MySQL database for MediaWiki${NoC}"
SYSOPPASS=`pwgen -syncB1 12`
USERPASS=`pwgen -syncB1 8`
while true
do
  read -s -p "MySQL password for user root: " MySQL_ROOT
  echo
  read -s -p "Confirm password for user root: " CONFIRM
  echo

  if [ "$CONFIRM" = "$MySQL_ROOT" ]
  then
      mysql -u root -p$MySQL_ROOT -e "CREATE DATABASE $WIKI_NAME;"
      mysql -u root -p$MySQL_ROOT -e "GRANT ALL PRIVILEGES ON $WIKI_NAME.* TO 'wiki-sysop'@localhost IDENTIFIED BY '$SYSOPPASS';"
      mysql -u root -p$MySQL_ROOT -e "GRANT SELECT, INSERT, UPDATE, DELETE ON $WIKI_NAME.* TO 'wiki'@localhost IDENTIFIED BY '$USERPASS';"

      break
  else
      echo -e "${RED}Passwords did not match${NoC}"
  fi
done

echo -e "${BLU}Installing Parsoid${NoC}"
read -p "Press any key to continue..." -n 1 -r
echo
cd /usr/lib/
git clone https://github.com/wikimedia/parsoid.git --branch v0.9.0 --depth 1 parsoid
cd parsoid
npm install
cp config.example.yaml config.yaml
echo -e "${BLU}Opening Parsoid configuration for editing${NoC}"
vi config.yaml

echo -e "${BLU}Registering the Parsoid service${NoC}"
cd /etc/systemd/system
wget https://github.com/rDuckDev/MediaWiki-on-Ubuntu/raw/master/parsoid.service
chmod 644 parsoid.service
chown root:root parsoid.service
systemctl daemon-reload
systemctl enable parsoid
systemctl start parsoid

# print config options
LOGFILE="/var/www/html/README"
IP_ADDR=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`

echo `date` > $LOGFILE
echo " " >> $LOGFILE
echo "Parsoid configuration: /usr/lib/parsoid/config.yaml" >> $LOGFILE
echo "MediaWiki API: http://$IP_ADDR/$WIKI_NAME/api.php" >> $LOGFILE
echo " " >> $LOGFILE
echo "Open your browser to http://$IP_ADDR/$WIKI_NAME to configure MediaWiki" >> $LOGFILE
echo " " >> $LOGFILE
echo "Database host: localhost" >> $LOGFILE
echo "Database name: $WIKI_NAME" >> $LOGFILE
echo "Database user: wiki-sysop" >> $LOGFILE
echo "Database pass: $SYSOPPASS" >> $LOGFILE
echo "Wiki name: $WIKI_NAME" >> $LOGFILE
echo " " >> $LOGFILE
echo "Add the following settings to LocalSettings.php" >> $LOGFILE
echo '$wgDBuser = "wiki";' >> $LOGFILE
echo '$wgDBpassword = "'$USERPASS'";' >> $LOGFILE
echo '$wgDBadminuser = "wiki-sysop";' >> $LOGFILE
echo '$wgDBadminpassword = "'$SYSOPPASS'";' >> $LOGFILE

echo -e "${ORG}The following was saved to $LOGFILE.${NoC}"
echo
cat /var/www/html/README
echo

echo -e "${GRN}Finished!${NoC}"
read -p "Press any key to continue..." -n 1 -r
echo

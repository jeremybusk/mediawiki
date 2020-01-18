#!/bin/bash
set -e
# Simple example backup/update scripts

bkp_dir="/bkp"
html_folder="/var/www/html"
timestamp=$(date "+%Y%m%dT%H%M%S")
sql_bkp_file="/bkp/wiki.sql.${timestamp}"
html_bkp_file="/bkp/wiki-html.${timestamp}.tgz"


mkdir -p ${bkp_dir}
cd ${bkp_dir}


mysqldump --user=wiki --password=wiki wiki > ${sql_bkp_file}
tar -zcvf ${html_bkp_file} ${html_folder}
tar -ztvf ${html_bkp_file}


cd ${html_folder}
composer update --no-dev
wget https://releases.wikimedia.org/mediawiki/1.34/mediawiki-1.34.0.tar.gz
tar  --strip-components=1 -xvzf mediawiki-1.34.0.tar.gz  mediawiki-1.34.0
rm mediawiki-1.34.0.tar.gz
cd maintenance
php update.php
cd ../


find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
echo "Mediawiki update complete."

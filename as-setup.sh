#!/bin/bash

## Run common installation
. ~/base-setup.sh
cd /cloudstone

dbIPAddress=ec2-XX-XX-XX-XX.ap-southeast-2.compute.amazonaws.com
worker_processes=`grep -c ^processor /proc/cpuinfo `
worker_connections=1500;

## Setup Tomcat and FABAN
. ~/base-server-setup.sh
cd /cloudstone

## Create and setup the /tmp/http_sessions, where sessions will be hosted.
## If it does not exists or if permissions are insufficient you won't be able to login
printf "$logPrefix  create  /tmp/http_sessions $logSuffix"
mkdir -p /tmp/http_sessions
sudo chmod -R 777 /tmp/http_sessions


## Setting up the web application
printf "$logPrefix Setting the web app $logSuffix"
sudo bash -c "echo \"APP_DIR=/var/www\" >> /etc/environment"
export APP_DIR=/var/www
sudo mkdir -p $APP_DIR

## Apply a patch to Olio
printf "$logPrefix Patch Olio $logSuffix"
sudo cp -r $OLIO_HOME/webapp/php/trunk/* $APP_DIR
sudo cp /cloudstone/web-release/cloudstone.patch $APP_DIR
cd $APP_DIR
sudo patch -p1 < cloudstone.patch

## Set the DB configuration & Edit the config.php
printf "$logPrefix Setup the DB connection $logSuffix"
 
cd $APP_DIR/etc

sudo sed -i -e "s/^\s*\$olioconfig\['dbTarget'\]\s*=.*/\$olioconfig\['dbTarget'\] = \'mysql:host=${dbIPAddress};dbname=olio\';/" ./config.php

sudo sed -i -e "s/^.*\$olioconfig\['cacheSystem'\]\s*=\s*'MemCached'.*/\$olioconfig\['cacheSystem'\] = 'NoCache';/" ./config.php

sudo sed -i -e "s/^\s*\$olioconfig\['geocoderURL'\]\s*=.*/\$olioconfig\['geocoderURL'\] = 'http:\/\/${dbIPAddress}:8080\\/geocoder\/geocode';/" ./config.php

## Installing Nginx ...
printf "$logPrefix Install NGINX $logSuffix"
cd /cloudstone
cp web-release/nginx-1.0.11.tar.gz .
tar zxvf nginx-1.0.11.tar.gz 1> /dev/null
cd nginx-1.0.11
./configure 

make
sudo make install

## Start server
sudo /usr/local/nginx/sbin/nginx
## Stop server
sudo /usr/local/nginx/sbin/nginx -s stop

cd /usr/local/nginx/conf/
sudo mv ./nginx.conf ./nginx-backup.conf
sudo cp ~/nginx.conf ./nginx.conf

sudo sed -i "s/\(worker_processes *\).*/worker_processes $worker_processes;/" ./nginx.conf
sudo sed -i "s/\(worker_connections *\).*/worker_connections $worker_connections;/" ./nginx.conf
sudo /usr/local/nginx/sbin/nginx

## Installing PHP
printf "$logPrefix Install PHP $logSuffix"
sudo apt-get install -y libxml2-dev curl libcurl3 libcurl3-dev libjpeg-dev libpng-dev

cd /cloudstone/

cp ./web-release/mysql-5.5.20-linux2.6-x86_64.tar.gz .
tar xzvf mysql-5.5.20-linux2.6-x86_64.tar.gz 1> /dev/null

cp ./web-release/php-5.3.9.tar.gz .
tar xzvf php-5.3.9.tar.gz 1> /dev/null

cd php-5.3.9

## Patch PhP as it won't complie otherwise, as it depends on an old version of libxml2-dev
cp ~/php-5.4.5-libxm2-2.9.0.patch .
sudo patch -p0 < php-5.4.5-libxm2-2.9.0.patch

./configure --enable-fpm --with-curl --with-pdo-mysql=/cloudstone/mysql-5.5.20-linux2.6-x86_64 --with-gd --with-jpeg-dir --with-png-dir --with-config-file-path=$APP_DIR/etc/
make
sudo make install

sudo bash -c "echo \"PHPRC=$APP_DIR/etc/\" >> /etc/environment"
export PHPRC=$APP_DIR/etc/

sudo mv $APP_DIR/etc/php.ini $APP_DIR/etc/php-backup.ini
sudo cp ~/php.ini $APP_DIR/etc

## To run Nginx with PHP support, the PHP-FPM module must be started separately:
sudo cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf
sudo addgroup nobody # (or you can modify the php-fpm.com file to set the user and group to the ones you are already using)
sudo /usr/local/sbin/php-fpm

## Setting up the Filestore 
printf "$logPrefix Set up the file store $logSuffix"
cd $APP_DIR
sudo cp /cloudstone/web-release/cloudsuite.patch .
sudo patch -p1 < cloudsuite.patch

## Find the best place to put the storage
maxSpaceDir=`getMaxDiskSpaceDir`
if [[ $maxSpaceDir == */ ]]
then 
    export FILESTORE=`getMaxDiskSpaceDir`filestorage
else 
    export FILESTORE=`getMaxDiskSpaceDir`/filestorage
fi

sudo bash -c "echo \"FILESTORE=$FILESTORE\" >> /etc/environment"
sudo mkdir -p $FILESTORE
sudo chmod a+rwx $FILESTORE

sudo chmod +x $FABAN_HOME/benchmarks/OlioDriver/bin/fileloader.sh
$FABAN_HOME/benchmarks/OlioDriver/bin/fileloader.sh 102 $FILESTORE

cd $APP_DIR/etc
escapedPath=${FILESTORE//\//\\\/}
sudo sed -i -e "s/^\s*\$olioconfig\['localfsRoot'\]\s*=.*/\$olioconfig\['localfsRoot'\] = '${escapedPath}';/" ./config.php

# TODO Find a better way to restart php-fpm ... 
sudo killall -9 php-fpm
sudo /usr/local/sbin/php-fpm

printf "$logPrefix Done $logSuffix"

## Print installation details...
printf "$installSummaryLine"

printf "%-15s %s\n" "\$JAVA_HOME:" $JAVA_HOME 
printf "%-15s %s\n" "\$JDK_HOME:" $JDK_HOME
printf "%-15s %s\n" "\$OLIO_HOME:" $OLIO_HOME
printf "%-15s %s\n" "\$FABAN_HOME:" $FABAN_HOME
printf "%-15s %s\n" "\$APP_DIR:" $APP_DIR
printf "%-15s %s\n" "\$FILESTORE:" $FILESTORE


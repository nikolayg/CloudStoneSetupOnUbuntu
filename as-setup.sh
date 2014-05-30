#!/bin/bash

# Record the start directory 
export startDir=`pwd`

# Import commonly reused functions
echo "Load Commonly used functions from $startDir/functions.sh"
. $startDir/functions.sh

## Run common installation
. $startDir/base-setup.sh
cd /cloudstone

## Setup Tomcat and FABAN
. $startDir/base-server-setup.sh
cd /cloudstone

dbIPAddress=ec2-ec2-XX-XX-XX-XX.ap-southeast-2.compute.amazonaws.com
worker_processes=`grep -c ^processor /proc/cpuinfo `
worker_connections=1500;

## Create and setup the /tmp/http_sessions, where sessions will be hosted.
## If it does not exists or if permissions are insufficient you won't be able to login
logHeader "create  /tmp/http_sessions "
mkdir -p /tmp/http_sessions
sudo chmod -R 777 /tmp/http_sessions

## Setting up the web application
logHeader "Setting the web app"
exportVar APP_DIR "/var/www"
sudo mkdir -p $APP_DIR

## Apply a patch to Olio
logHeader "Patch Olio"
sudo cp -r $OLIO_HOME/webapp/php/trunk/* $APP_DIR
sudo cp /cloudstone/web-release/cloudstone.patch $APP_DIR
cd $APP_DIR
sudo patch -p1 < cloudstone.patch

## Set the DB configuration & Edit the config.php
logHeader "Setup the DB connection"
cd $APP_DIR/etc

setProperty "\$olioconfig['dbTarget']" "'mysql:host=${dbIPAddress};dbname=olio';" ./config.php
setProperty "\$olioconfig['cacheSystem']" "'NoCache';" ./config.php
setProperty "\$olioconfig['geocoderURL']" "'http://${dbIPAddress}:8080/geocoder/geocode';" ./config.php

## Installing Nginx ...
logHeader "Install NGINX"
cd /cloudstone
cp web-release/nginx-1.0.11.tar.gz .
tar zxvf nginx-1.0.11.tar.gz 1> /dev/null
cd nginx-1.0.11
./configure 1> /dev/null

make 1> /dev/null
sudo make install 1> /dev/null

## Start server
sudo /usr/local/nginx/sbin/nginx
## Stop server
sudo /usr/local/nginx/sbin/nginx -s stop

cd /usr/local/nginx/conf/
sudo mv ./nginx.conf ./nginx-backup.conf
sudo cp ~/nginx.conf ./nginx.conf

setProperty "worker_processes" "$worker_processes;" ./nginx.conf " "
setProperty "worker_connections" "$worker_connections;" ./nginx.conf " "
sudo /usr/local/nginx/sbin/nginx

## Installing PHP
logHeader "Install PHP"
sudo apt-get install -y libxml2-dev curl libcurl3 libcurl3-dev libjpeg-dev libpng-dev 1> /dev/null

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
make 1> /dev/null
sudo make install 1> /dev/null

exportVar PHPRC "$APP_DIR/etc/"

sudo mv $APP_DIR/etc/php.ini $APP_DIR/etc/php-backup.ini
sudo cp ~/php.ini $APP_DIR/etc

## To run Nginx with PHP support, the PHP-FPM module must be started separately:
sudo cp /usr/local/etc/php-fpm.conf.default /usr/local/etc/php-fpm.conf
sudo addgroup nobody # (or you can modify the php-fpm.com file to set the user and group to the ones you are already using)
sudo /usr/local/sbin/php-fpm

## Setting up the Filestore 
logHeader "Set up the file store and its patch"
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
exportVar FILESTORE "$FILESTORE"

sudo mkdir -p $FILESTORE
sudo chmod a+rwx $FILESTORE

sudo chmod +x $FABAN_HOME/benchmarks/OlioDriver/bin/fileloader.sh
$FABAN_HOME/benchmarks/OlioDriver/bin/fileloader.sh 102 $FILESTORE

cd $APP_DIR/etc
setProperty "\$olioconfig['localfsRoot']" "'$FILESTORE';" ./config.php

# TODO Find a better way to restart php-fpm ... 
sudo killall -9 php-fpm
sudo /usr/local/sbin/php-fpm

## Print installation details...
logInstallDetails


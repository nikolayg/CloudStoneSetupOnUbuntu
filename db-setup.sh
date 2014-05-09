#!/bin/bash

## Run common installation
. ~/base-setup.sh
cd /cloudstone

asIPAddress=ec2-54-206-131-182.ap-southeast-2.compute.amazonaws.com
conc_users=50

# Setup Tomcat and FABAN
. ~/base-server-setup.sh
cd /cloudstone


printf "$logPrefix  Setup MySql $logSuffix"
## Removed preconfigured MySql
sudo apt-get remove --purge -y mysql-server mysql-client mysql-common
sudo apt-get autoremove
sudo apt-get autoclean

## Set up mysql and its user
sudo groupadd mysql 
sudo useradd -r -g mysql mysql

cp ./web-release/mysql-5.5.20-linux2.6-x86_64.tar.gz .
tar xzvf mysql-5.5.20-linux2.6-x86_64.tar.gz # 1> /dev/1> /dev/null

sudo chown -R mysql mysql-5.5.20-linux2.6-x86_64
sudo chgrp -R mysql mysql-5.5.20-linux2.6-x86_64

sudo chmod -R 777 mysql-5.5.20-linux2.6-x86_64
cd mysql-5.5.20-linux2.6-x86_64
sudo cp support-files/my-medium.cnf /etc/my.cnf

# Sets up some MySql vars like hostname
# bin/my_print_defaults
sudo scripts/mysql_install_db --user=mysql 

## Start mysql
printf "$logPrefix  Start MySql $logSuffix"
sudo -b bin/mysqld_safe --defaults-file=/etc/my.cnf --user=mysql # 1> /dev/1> /dev/null

## Wait for MySql to start ...
sleep 1m

## Popluate DB
printf "$logPrefix Create database schema $logSuffix"

## MySql doesn't know of FABAN, so replace the var in the script
esapedFabanHome=${FABAN_HOME//\//\\\/}
sed -i "s/\$FABAN_HOME/$esapedFabanHome/g" ~/setupDB.sql 

## Grant permission from anywhere, as it does not work with EC2 DNS! 
#sed -i "s/ip.address.of.frontend/$asIPAddress/g" ~/setupDB.sql
sed -i "s/ip.address.of.frontend/%/g" ~/setupDB.sql
sudo bin/mysql -uroot < ~/setupDB.sql

printf "$logPrefix Populate database $logSuffix"
cd $FABAN_HOME/benchmarks/OlioDriver/bin
sudo chmod +x dbloader.sh
./dbloader.sh localhost $conc_users


## Setting up the Geocoder Emulator
printf "$logPrefix  Setting up the Geocoder Emulator $logSuffix"
mkdir /cloudstone/geocoderhome
sudo chmod -R 777 /cloudstone/geocoderhome 
cd /cloudstone/geocoderhome
sudo bash -c "echo \"GEOCODER_HOME=/cloudstone/geocoderhome\" >> /etc/environment"
export GEOCODER_HOME=/cloudstone/geocoderhome

sudo cp ~/geocoder.tar.gz .
sudo tar xzvf geocoder.tar.gz # 1> /dev/1> /dev/null

cd $GEOCODER_HOME/geocoder
sudo cp build.properties.template build.properties
escapedPath=$CATALINA_HOME/lib
escapedPath=${escapedPath//\//\\\/}
sudo sed -i "s/\(servlet.lib.path *= *\).*/servlet.lib.path=$escapedPath/" ./build.properties

ant all
cp dist/geocoder.war $CATALINA_HOME/webapps

## Start Tomcat:
printf "$logPrefix  Start Tomcat $logSuffix"
$CATALINA_HOME/bin/startup.sh

printf "$logPrefix Done $logSuffix"

## Print installation details...
printf "$installSummaryLine"

printf "%-15s %s\n" "\$JAVA_HOME:" $JAVA_HOME 
printf "%-15s %s\n" "\$JDK_HOME:" $JDK_HOME
printf "%-15s %s\n" "\$OLIO_HOME:" $OLIO_HOME
printf "%-15s %s\n" "\$FABAN_HOME:" $FABAN_HOME
printf "%-15s %s\n" "\$CATALINA_HOME:" $CATALINA_HOME
printf "%-15s %s\n" "\$GEOCODER_HOME:" $GEOCODER_HOME

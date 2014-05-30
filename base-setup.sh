#!/bin/bash

# Import commonly reused functions
. $startDir/functions.sh

# Log Installation environment metadata
logHeader "Installation Metadata"
echo USER: `whoami`, $USER
echo SYSTEM: `uname -a`
echo CURRENT TIME: `date`
echo START DIR: $startDir


## Make the CloudStone directory and give appropriate access for everyone
logHeader " Setting up the installation directory /cloudstone"
sudo mkdir /cloudstone
sudo chown -R $USER /cloudstone/
sudo chmod -R 777 /cloudstone 
cd /cloudstone

logHeader " Setting up common packages"

## Update repositories
sudo apt-get update 1> /dev/null

## Uninstall all javas if present
sudo apt-get purge -y openjdk-\* icedtea-\* icedtea6-\* 1> /dev/null

## Install unzip utilities
sudo apt-get install -y unzip 1> /dev/null

## Install C/C++ compilers
sudo apt-get install -y build-essential 1> /dev/null

## Install dependencies
sudo apt-get install -y libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlib1g-dev 1> /dev/null

## Install Java and ANT. Set up Java environment variables
sudo apt-get install -y openjdk-6-jdk 1> /dev/null

## Install libaio1
sudo apt-get install -y libaio1 1> /dev/null

## Install git
sudo apt-get install -y git 1> /dev/null

## Install monitoring tools
sudo apt-get install -y sysstat 1> /dev/null


logHeader "Change permissions and owner of /tmp, create /var/log/messages"
sudo chown -R $USER /tmp/
sudo chmod -R 777 /tmp/

sudo touch /var/log/messages
sudo chmod 777 /var/log/messages

## Change permission of pem file and set access without prompts
logHeader " Setting SSH access without password"
pemFile=CloudStone.pem
sudo chmod 400 ~/$pemFile 
sudo cp -rf ~/config ~/.ssh/config


## Set up Java
logHeader " Setting up Java environment variables"

jdklocation=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
jrelocation=$jdklocation/jre
exportVar JAVA_HOME $jdklocation
exportVar JDK_HOME $jdklocation
exportVar PATH "$PATH:$jrelocation/bin"

## Install ANT
logHeader " Setting up ANT"
sudo apt-get install -y ant

## Download cloudstone, extract Olio and set its mysql connector
logHeader " Download and setup Olio"
wget --no-verbose http://parsa.epfl.ch/cloudsuite/software/web.tar.gz 1> /dev/null
tar xzvf web.tar.gz 1> /dev/null

cp web-release/apache-olio-php-src-0.2.tar.gz .
tar xzvf apache-olio-php-src-0.2.tar.gz 1> /dev/null

exportVar OLIO_HOME "/cloudstone/apache-olio-php-src-0.2"

cp web-release/mysql-connector-java-5.0.8.tar.gz .
tar xzvf mysql-connector-java-5.0.8.tar.gz 1> /dev/null
cp ./mysql-connector-java-5.0.8/mysql-connector-java-5.0.8-bin.jar $OLIO_HOME/workload/php/trunk/lib

sudo chown -R $USER $OLIO_HOME
sudo chmod -R 777 $OLIO_HOME

#!/bin/bash

export logPrefix="\n\n\n\n == == == == == == == == == == == == == == == == == == == == == == == == \n -- -- -- "
export logSuffix=" -- -- -- \n\n "
export installSummaryLine="\n\n\n\n\n ==== ==== ==== ==== ==== ==== INSTALLATION SUMMARY ==== ==== ==== ==== ==== ==== \n\n"

printf "$logPrefix  Metadata $logSuffix"
echo USER: `whoami`, $USER
echo SYSTEM: `uname -a`
echo CURRENT SERVER TIME: `date`


printf "$logPrefix  Setting up the installation directory /cloudstone $logSuffix"
## Make the CloudStone directory and give appropriate access for everyone
sudo mkdir /cloudstone
sudo chown -R $USER /cloudstone/
sudo chmod -R 777 /cloudstone 
cd /cloudstone

printf "$logPrefix  Setting up common packages $logSuffix"

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


printf "$logPrefix  Change permissions and owner of /tmp, create /var/log/messages $logSuffix"
sudo chown -R $USER /tmp/
sudo chmod -R 777 /tmp/

sudo touch /var/log/messages
sudo chmod 777 /var/log/messages

printf "$logPrefix  Setting SSH access without password $logSuffix"
sudo cp -rf ~/config ~/.ssh/config


printf "$logPrefix  Setting up Java environment variables $logSuffix"

jdklocation=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
jrelocation=$jdklocation/jre

sudo bash -c "echo \"JAVA_HOME=$jdklocation\" >> /etc/environment"
sudo bash -c "echo \"JDK_HOME=$jdklocation\" >> /etc/environment"
sudo bash -c "echo \"PATH=$PATH:$jrelocation/bin\" >> /etc/environment"

export JAVA_HOME=$jdklocation
export JDK_HOME=$jdklocation
export PATH=$PATH:$jrelocation/bin

## Install ANT
printf "$logPrefix  Setting up ANT $logSuffix"
sudo apt-get install -y ant

## Download cloudstone, extract Olio and set its mysql connector
printf "$logPrefix  Download and setup Olio $logSuffix"
wget http://parsa.epfl.ch/cloudsuite/software/web.tar.gz 1> /dev/null
tar xzvf web.tar.gz 1> /dev/null

cp web-release/apache-olio-php-src-0.2.tar.gz .
tar xzvf apache-olio-php-src-0.2.tar.gz 1> /dev/null

sudo bash -c "echo \"OLIO_HOME=/cloudstone/apache-olio-php-src-0.2\" >> /etc/environment"  
export OLIO_HOME=/cloudstone/apache-olio-php-src-0.2

cp web-release/mysql-connector-java-5.0.8.tar.gz .
tar xzvf mysql-connector-java-5.0.8.tar.gz 1> /dev/null
cp ./mysql-connector-java-5.0.8/mysql-connector-java-5.0.8-bin.jar $OLIO_HOME/workload/php/trunk/lib

sudo chown -R $USER $OLIO_HOME
sudo chmod -R 777 $OLIO_HOME

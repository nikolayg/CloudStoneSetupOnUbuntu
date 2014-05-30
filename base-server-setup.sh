#!/bin/bash

cd /cloudstone

## Untar and setup FABAN archive taken from the client
logHeader " Setup FABAN archive taken from the client "
sudo cp ~/faban.tar.gz .
tar xzvf faban.tar.gz 1> /dev/null
exportVar FABAN_HOME "/cloudstone/faban"

## Make FABAN accessible by everyone
sudo chown -R $USER $FABAN_HOME
sudo chmod -R 777 $FABAN_HOME

##Setting up Tomcat
logHeader "$logPrefix Setting up Tomcat"
cp web-release/apache-tomcat-6.0.35.tar.gz .
tar xzvf apache-tomcat-6.0.35.tar.gz 1> /dev/null
sudo bash -c "echo \"CATALINA_HOME=/cloudstone/apache-tomcat-6.0.35\" >> /etc/environment"
export CATALINA_HOME=/cloudstone/apache-tomcat-6.0.35

cd $CATALINA_HOME/bin
tar zxvf commons-daemon-native.tar.gz 1> /dev/null
cd commons-daemon-1.0.7-native-src/unix/
./configure
make
cp jsvc ../..




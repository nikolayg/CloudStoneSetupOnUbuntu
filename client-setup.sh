#!/bin/bash

# Record the start directory 
export startDir=`pwd`

# Import commonly reused functions
echo "Load Commonly used functions from $startDir/functions.sh"
. $startDir/functions.sh

## Run common installation
. $startDir/base-setup.sh
cd /cloudstone

clientIPAddress=ec2-XX-XX-XX-XX.ap-southeast-2.compute.amazonaws.com

logHeader " Set-up Faban"

## Clone and build faban's forked repo
cd ~
git clone https://github.com/nikolayg/faban.git 1> /dev/null
cd ~/faban
ant 1> /dev/null

cp -ar ~/faban/stage/ /cloudstone
mv /cloudstone/stage/ /cloudstone/faban

exportVar FABAN_HOME "/cloudstone/faban"

cd $FABAN_HOME/
cp samples/services/ApacheHttpdService/build/ApacheHttpdService.jar services
cp samples/services/MysqlService/build/MySQLService.jar services
cp samples/services/MemcachedService/build/MemcachedService.jar services

cd $OLIO_HOME/workload/php/trunk
cp build.properties.template build.properties 

## Set Faban's master IP and build
setProperty "faban.url" "http://$clientIPAddress:9980" ./build.properties
setProperty "faban.home" $FABAN_HOME ./build.properties

ant deploy.jar 1> /dev/null
cp $OLIO_HOME/workload/php/trunk/build/OlioDriver.jar $FABAN_HOME/benchmarks

## Make FABAN appropriately accessible
logHeader " Change permission for FABAN"
echo sudo chown -R $USER $FABAN_HOME
sudo chown -R $USER $FABAN_HOME

echo sudo chmod -R 777 $FABAN_HOME
sudo chmod -R 777 $FABAN_HOME

## Change the AWK shebang for this OS
logHeader " Change the AWK shebang of the post scripts in $FABAN_HOME/bin/Linux for this OS"
awkLocation=`which awk`
escapedAwkLocation=`escapeString $awkLocation`
for postStat in `ls $FABAN_HOME/bin/Linux/ | grep "\-post"`
do
    sudo sed -i "1s/^.*$/"\#\!$escapedAwkLocation" -f/" $FABAN_HOME/bin/Linux/$postStat
done

logHeader " Start and Test FABAN"
## Start FABAN with the same shell environment
$FABAN_HOME/master/bin/startup.sh

## Wait for Faban to start and make a request to it, so it extracts $FABAN_HOME/benchmarks/OlioDriver.jar
sleep 1m
cd /cloudstone

wget http://$clientIPAddress:9980

## Wait for the request to complete and Backup Faban's dir
sleep 1m

logHeader " Archiving FABAN and Geocoder"
tar -zcvf faban.tar.gz ./faban 1> /dev/null

cd $OLIO_HOME
tar -zcvf geocoder.tar.gz ./geocoder 1> /dev/null
cd /cloudstone
mv $OLIO_HOME/geocoder.tar.gz .

## Print installation details...
logInstallDetails


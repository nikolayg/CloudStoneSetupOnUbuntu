#!/bin/bash

## Run common installation
. ~/base-setup.sh
cd /cloudstone

clientIPAddress=ec2-XX-XX-XX-XX.ap-southeast-2.compute.amazonaws.com

printf "$logPrefix  Set-up Faban $logSuffix"

## Download Faban
# wget java.net/projects/faban/downloads/download/faban-kit/faban-kit-022311.tar.gz 1> /dev/null
# tar xzvf faban-kit-022311.tar.gz 1> /dev/null

## Clone and build faban's forked repo
cd ~
git clone https://github.com/nikolayg/faban.git 1> /dev/null
cd ~/faban
ant 1> /dev/null

cp -ar ~/faban/stage/ /cloudstone
mv /cloudstone/stage/ /cloudstone/faban

sudo bash -c "echo \"FABAN_HOME=/cloudstone/faban\" >> /etc/environment"
export FABAN_HOME=/cloudstone/faban

cd $FABAN_HOME/
cp samples/services/ApacheHttpdService/build/ApacheHttpdService.jar services
cp samples/services/MysqlService/build/MySQLService.jar services
cp samples/services/MemcachedService/build/MemcachedService.jar services

cd $OLIO_HOME/workload/php/trunk
cp build.properties.template build.properties 

## Set Faban's master IP and build
sed -i "s/\(faban.url *= *\).*/faban.url=http:\/\/$clientIPAddress:9980/" ./build.properties
esapedFabanHome=${FABAN_HOME//\//\\\/}
sed -i "s/\(faban.home *= *\).*/faban.home=$esapedFabanHome/" ./build.properties

## Replace the $FABAN_HOME/bin/Linux/interface as it has a bug.
#mv $FABAN_HOME/bin/Linux/interface $FABAN_HOME/bin/Linux/interface-old-backup
#cp ~/interface $FABAN_HOME/bin/Linux/interface

ant deploy.jar 
cp $OLIO_HOME/workload/php/trunk/build/OlioDriver.jar $FABAN_HOME/benchmarks

## Make FABAN appropriately accessible
printf "$logPrefix  Change permission for FABAN $logSuffix"
echo sudo chown -R $USER $FABAN_HOME
sudo chown -R $USER $FABAN_HOME

echo sudo chmod -R 777 $FABAN_HOME
sudo chmod -R 777 $FABAN_HOME

## Change the AWK shebang for this OS
printf "$logPrefix  Change the AWK shebang of the post scripts in $FABAN_HOME/bin/Linux for this OS $logSuffix"
awkLocation=`which awk`
escapedAwkLocation=${awkLocation//\//\\\/}
for postStat in `ls $FABAN_HOME/bin/Linux/ | grep "\-post"`
do
    sudo sed -i "1s/^.*$/"\#\!$escapedAwkLocation" -f/" $FABAN_HOME/bin/Linux/$postStat
done

printf "$logPrefix  Start and Test FABAN $logSuffix"
## Start FABAN with the same shell environment
$FABAN_HOME/master/bin/startup.sh

## Wait for Faban to start and make a request to it, so it extracts $FABAN_HOME/benchmarks/OlioDriver.jar
sleep 1m
cd /cloudstone

printf "\nGetting: http://$clientIPAddress:9980\n"
wget http://$clientIPAddress:9980

## Wait for the request to complete and Backup Faban's dir
sleep 1m

printf "$logPrefix  Archiving FABAN and Geocoder $logSuffix"
tar -zcvf faban.tar.gz ./faban 1> /dev/null

cd $OLIO_HOME
tar -zcvf geocoder.tar.gz ./geocoder 1> /dev/null
cd /cloudstone
mv $OLIO_HOME/geocoder.tar.gz .

printf "$logPrefix Done $logSuffix"

## Print installation details...
printf "$installSummaryLine"

printf "%-15s %s\n" "\$JAVA_HOME:" $JAVA_HOME 
printf "%-15s %s\n" "\$JDK_HOME:" $JDK_HOME
printf "%-15s %s\n" "\$OLIO_HOME:" $OLIO_HOME
printf "%-15s %s\n" "\$FABAN_HOME:" $FABAN_HOME


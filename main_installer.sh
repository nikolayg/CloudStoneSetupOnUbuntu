#!/bin/bash

# Import commonly reused functions
. ./functions.sh

## Input Variables...
clientIPAddress=ec2-XX-XX-XX-XX.ap-southeast-2.compute.amazonaws.com
asIPAddress=ec2-ec2-XX-XX-XX-XX.ap-southeast-2.compute.amazonaws.com
dbIPAddress=ec2-ec2-XX-XX-XX-XX.ap-southeast-2.compute.amazonaws.com 

pemFile=CloudStone.pem
userName=ubuntu

## List of all files we'll need for the installation
allFiles=($pemFile functions.sh base-setup.sh base-server-setup.sh as-setup.sh client-setup.sh db-setup.sh nginx.conf php-5.4.5-libxm2-2.9.0.patch php.ini setupDB.sql config)

## Print meta info
logHeader "Starting installation with the following parameters:"
echo Client Address \(Faban Driver\) : $clientIPAddress
echo Web/AS Server Address: $asIPAddress 
echo DB Server Address: $dbIPAddress

echo PEM FILE: $pemFile 
echo Node Login Username: $userName
echo Current User on the installer: `whoami` 

## Change permissions of the pem file
logHeader "Change permissions of local pem file"
sudo chmod 400 $pemFile

## Change the IP addresses in the scripts and the config files ... 
logHeader " Prepare installation scripts and configuration files"
for f in as-setup.sh base-setup.sh base-server-setup.sh client-setup.sh db-setup.sh
do
    setProperty "clientIPAddress" $clientIPAddress ./$f
    setProperty "asIPAddress" $asIPAddress ./$f
    setProperty "dbIPAddress" $dbIPAddress ./$f
    setProperty "pemFile" $pemFile ./$f
done

## Set up the SSH config file
logHeader "Set up the SSH config file"
setProperty User $userName ./config " "
setProperty IdentityFile "~/$pemFile" ./config " "

## Copy the scripts and properties to the servers ... 
logHeader "Transfer scripts and config to servers..."
for address in $clientIPAddress $dbIPAddress $asIPAddress
do
    scp -i $pemFile ${allFiles[*]} $userName@$address:~/
done

## Set up the client
logHeader "Set up the client..."
ssh -i $pemFile $userName@$clientIPAddress "bash client-setup.sh" &> ~/client-setup.log

## Copy FABAN  and GEOCODER from the client to the local machine
logHeader "Copy FABAN and Geocoder from client locally"
scp -i $pemFile $userName@$clientIPAddress:/cloudstone/faban.tar.gz ~ 
scp -i $pemFile $userName@$clientIPAddress:/cloudstone/geocoder.tar.gz ~ 

## Copy FABAN and GEOCODER to the AS and DB servers
logHeader "Copy FABAN and geocoder to the servers...  "
for address in $dbIPAddress $asIPAddress
do
    scp -i $pemFile ~/faban.tar.gz $userName@$address:~/
    scp -i $pemFile ~/geocoder.tar.gz $userName@$address:~/
done

## Set up the AS/Web server
logHeader "Setup AS/Web server... "
ssh -i $pemFile $userName@$asIPAddress "bash as-setup.sh" &> ~/as-setup.log

## Set up the DB server
logHeader "$\n\n == Setup database server... \n "
ssh -i $pemFile $userName@$dbIPAddress "bash db-setup.sh" &> ~/db-setup.log


printf "$\n\n\n == == == == DONE! == == == == \n "

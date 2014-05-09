#!/bin/bash

clientIPAddress=ec2-XX-XX-XX-XX.ap-southeast-2.compute.amazonaws.com 
asIPAddress=ec2-XX-XX-XX-XX.ap-southeast-2.compute.amazonaws.com
dbIPAddress=ec2-XX-XX-XX-XX.ap-southeast-2.compute.amazonaws.com 

pemFile=CloudStone.pem
userName=ubuntu

## Print meta info
printf "$\n\n == Starting isntallation with the following parameters... \n "
echo Client Address \(Faban Driver\) : $clientIPAddress
echo Web/AS Server Address: $asIPAddress 
echo DB Server Address: $dbIPAddress

echo PEM FILE: $pemFile 
echo Node Login Username: $userName
echo Current User on the installer: `whoami` 


## Change the IP addresses in the scripts ... 
printf "$\n\n == Prepare installation scripts... \n "
for f in as-setup.sh base-setup.sh base-server-setup.sh client-setup.sh db-setup.sh
do
    sed -i "s/\(clientIPAddress *= *\).*/clientIPAddress=$clientIPAddress/" ./$f
    sed -i "s/\(dbIPAddress *= *\).*/dbIPAddress=$dbIPAddress/" ./$f
    sed -i "s/\(asIPAddress *= *\).*/asIPAddress=$asIPAddress/" ./$f
done

sed -i "s/\(User *\).*/User $userName/" ./config
sed -i "s/\(IdentityFile *\).*/IdentityFile ~\/$pemFile/" ./config  


## Copy the scripts and properties to the servers ... 
printf "$\n\n == Transfer scripts and config to servers... \n "
for address in $clientIPAddress $dbIPAddress $asIPAddress
do
    scp -i $pemFile $pemFile base-setup.sh base-server-setup.sh as-setup.sh client-setup.sh db-setup.sh nginx.conf php-5.4.5-libxm2-2.9.0.patch php.ini setupDB.sql config $userName@$address:~/
done

## Set up the client
printf "$\n\n == Set up the client... \n\n "
ssh -i $pemFile $userName@$clientIPAddress "bash client-setup.sh" &> ~/client-setup.log

## Copy FABAN  and GEOCODER from the client
printf "$\n\n == Copy FABAN and Geocoder from client locally... \n "

scp -i $pemFile $userName@$clientIPAddress:/cloudstone/faban.tar.gz ~ 
scp -i $pemFile $userName@$clientIPAddress:/cloudstone/geocoder.tar.gz ~ 


## Copy FABAN and GEOCODER to the AS and DB servers
printf "$\n\n == Copy FABAN and geocoder to the servers... \n "
for address in $dbIPAddress $asIPAddress
do
    scp -i $pemFile ~/faban.tar.gz $userName@$address:~/
    scp -i $pemFile ~/geocoder.tar.gz $userName@$address:~/
done

## Set up the DB server
printf "$\n\n == Setup AS/Web server... \n "
ssh -i $pemFile $userName@$asIPAddress "bash as-setup.sh" &> ~/as-setup.log

## Set up the AS server
printf "$\n\n == Setup database server... \n "
ssh -i $pemFile $userName@$dbIPAddress "bash db-setup.sh" &> ~/db-setup.log

## Prepare an archive of logs
#printf "$\n\n == Prepare archive of logs... \n "
#cd ~
#zip ./logs.zip client-setup.log as-setup.log db-setup.log
#cd -
#mv ~/logs.zip .

printf "$\n\n\n == == == == DONE! == == == == \n "

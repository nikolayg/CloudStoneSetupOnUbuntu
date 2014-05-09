#!/bin/bash

cd /cloudstone

## Untar and setup FABAN archive taken from the client
printf "$logPrefix  Setup FABAN archive taken from the client $logSuffix"
sudo cp ~/faban.tar.gz .
tar xzvf faban.tar.gz 1> /dev/null
sudo bash -c "echo \"FABAN_HOME=/cloudstone/faban\" >> /etc/environment"
export FABAN_HOME=/cloudstone/faban

## Make FABAN accessible by everyone
sudo chown -R $USER $FABAN_HOME
sudo chmod -R 777 $FABAN_HOME

## Start the agent
#sudo $FABAN_HOME/master/bin/startup.sh
#sudo $FABAN_HOME/bin/agent

##Setting up Tomcat
printf "$logPrefix Setting up Tomcat $logSuffix"
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

# Define a utility function returning the directory with the
# most available disk space.
function getMaxDiskSpaceDir()
{
    # Get the metadata of all disks. For each disk returns
    #  (i)  the number of available blocks and 
    #  (ii) the disk's mount point
    diskDefs=(`df -P | awk '{ print $4 " " $6 }'`)
    
    # Number of elements in the def list
    diskDefsLen=${#diskDefs[*]}
    
    # Loop to find the index of the disk with the most Free space.
    bestIdx=1
    bestNumBlocks=0
    for i in $(seq 2 2 $((diskDefsLen - 1)) )
    do 
        availableBlocks=${diskDefs[$i]}
        if [ $availableBlocks -gt $bestNumBlocks ]
        then
            bestNumBlocks=$availableBlocks
            bestIdx=$i
        fi
    done
    
    echo ${diskDefs[$((bestIdx+1))]}
}


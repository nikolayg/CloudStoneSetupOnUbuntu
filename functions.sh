#!/bin/bash

### ====== ====== ======  Utility funcitons  ====== ====== ======  


# A utility function returning the root/mount directory 
# of the mounted disk with the biggest free space.
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
            #echo "Change ..."
        fi
        #echo "Available:" $availableBlocks " Best so far" $bestNumBlocks "Directory:" ${diskDefs[$((i+1))]}
    done
    
    echo ${diskDefs[$((bestIdx+1))]}
}

# Escapes special characters (brackets, slashes, dollars etc.) from a string 
function escapeString()
{
    arg=$1
    regex="\\\?\\\$|\[|\]|\(|\)|\/|\{|\}"
    echo "$arg" | sed -r 's/('$regex')/\\\1/g'
}

# Replaces the value of a property in a file
# Arguements - prop name, prop value, file, assignment symbol ("=" if not specified)
function setProperty()
{
    property=`escapeString $1`
    val=`escapeString $2`
    file=$3
    # If the assignment symbol is not specified use "="
    assignSymbol=${4-=}
    #echo $property
    #echo $val
    #echo sed -i -e "s/^\s*$property\s*$assignSymbol.*/$property$assignSymbol$val/" $file
    sudo sed -i -e "s/^\(\s*\)$property\s*$assignSymbol.*/\1$property$assignSymbol$val/" $file
    #sudo sed -i "s/^\s*\($property *$assignSymbol *\).*/$property$assignSymbol$val/" $file
}


# Logs an installation header message, that delimits the installation stages
function logHeader()
{
    arg=$1
    logPrefix="\n\n == == == == == == == == == == == == == == == == == == == == == == == == \n -- -- -- "
    logSuffix=" -- -- -- \n\n "
    printf "$logPrefix$arg$logSuffix"
}

## Print installation details - direcotories, variables etc.
function logInstallDetails
{
    logHeader "\n\n\n ======== ======== ======== ======== INSTALLATION SUMMARY ======== ======== ======== ======== \n\n"

    printf "%-15s %s\n" "\$JAVA_HOME:" $JAVA_HOME 
    printf "%-15s %s\n" "\$JDK_HOME:" $JDK_HOME
    printf "%-15s %s\n" "\$OLIO_HOME:" $OLIO_HOME
    printf "%-15s %s\n" "\$FABAN_HOME:" $FABAN_HOME
    printf "%-15s %s\n" "\$APP_DIR:" $APP_DIR
    printf "%-15s %s\n" "\$FILESTORE:" $FILESTORE
    printf "%-15s %s\n" "\$NFS_MOUNT_PATH:" $NFS_MOUNT_PATH
    printf "%-15s %s\n" "\$CATALINA_HOME:" $CATALINA_HOME
    printf "%-15s %s\n" "\$GEOCODER_HOME:" $GEOCODER_HOME
}

## Exports an environment variable and its value
function exportVar()
{
    var=$1
    val=$2
    sudo bash -c "echo \"$var=$val\" >> /etc/environment"
    export $var=$val
}

## Dynamically updates the load balancer's config file with the servers and their weigths.
## Arguements - pairs of DNS/IP addresses and weigths, file
function setServerFarmConfig()
{
    tmpFile="$HOME/temp-setServerFarm-file.txt"
    numParams=$#
    params=( "$@" )
    
    echo "" > "$tmpFile"
    echo "upstream backend  {" >> "$tmpFile"
    for i in $(seq 0 2 $((numParams - 2)) )
    do 
        addess=${params[$i]}
        weigth=${params[$((i+1))]}
        echo "   server $addess weight=$weigth;"  >> $tmpFile
    done
    echo "}" >> $tmpFile
    
    file=${params[$((numParams-1))]}
    sudo bash -c "cat $tmpFile >> $file"
    rm  $tmpFile
}

## Resets the load balancer to work with the specified servers and their weigths.
## Arguements - pairs of DNS/IP addresses and weigths
function resetLoadBalancer()
{
    params=( "$@" )
    cd /etc/nginx/sites-available/
    sudo cp -f ./default-backup ./default
    setServerFarmConfig ${params[*]} "./default"
    cd - 1> /dev/null
}

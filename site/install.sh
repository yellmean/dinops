#!/bin/bash
SiteUser=dingjian
ProgDir=$(cd `dirname $0`; pwd)
PkgsName=web-0.0.1-DEVELOPE.war
SiteHome=/mnt/www/webapps
DownloadLink=http://192.168.0.188:8081/nexus/service/local/repositories/releases/content/com/dingjian/web/0.0.1-DEVELOPE/$PkgsName

function checksource {
    cd "$ProgDir"
    if [[ -n $(ls | grep -w $PkgsName) ]]; then
         echo "$PkgsName already exists!"
    else
         wget $DownloadLink
    fi
}

function deployment {
    if [[ $1 != [a-zA-Z]* ]]; then
         echo "Warning::Invaild argument, please input a string name for Site home directory!"
         return 1
    fi
    if [ ! -d "$SiteHome/$1" ]; then 
         mkdir -p $SiteHome/$1
         echo "Create Site home directory $SiteHome/$1 success!"
    else 
         echo "Directory $SiteHome/$1 exists, please change your Site home directory!"
         return 1
    fi
    rm -rf $SiteHome/$1/* && echo "Clean $SiteHome/$1 success!" || exit 1
    \cp -rf  $PkgsName $SiteHome/$1 && cd $SiteHome/$1
    jar xf $PkgsName
    if [ $? -eq 0 ]; then
         echo "Extracted $PkgsName to $SiteHome success!" 
    else
         echo "Extracted $PkgsName to $SiteHome Failure!"
         return 1
    fi
    rm -rf $PkgsName
    \cp -rf $ProgDir/conf/* $SiteHome/$1/WEB-INF/config 
    if [ $? -eq 0 ]; then
        echo "Configure the Site for $1 success!"
    else
        echo "Configure the Site for $1 success!"
        return 1
    fi
    chown -R $SiteUser:$SiteUser $SiteHome
    echo "Site for $1 is deployed successfully and owner is $SiteUser!" || exit 1
}

checksource
deployment $1

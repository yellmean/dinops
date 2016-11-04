#!/bin/bash
Prog=rsync
ClientUser=dingjian
ProgCfgDir=/etc/rsync
ProgDir=$(cd `dirname $0`; pwd)
PkgsName=rsync-3.0.6-12.el6.x86_64.rpm
DownloadLink=ftp://rpmfind.net/linux/centos/6.8/os/x86_64/Packages/rsync-3.0.6-12.el6.x86_64.rpm

cd "$ProgDir"
function initialize {
    if [[ "$USER" != "root" ]]; then
        echo "Current user is not root"
        return 1
    fi
    for i in $(rpm -qa | grep $Prog | grep -v grep); do 
        echo "Deleting rpm -> "$i; sudo rpm -e --nodeps $i
    done
    if [[ ! -z $(rpm -qa | grep $Prog | grep -v grep) ]]; then
        echo "-->Failed to remove $Prog the defult version!"
        return 1
    fi
}

function checksource {
    if [[ -n $(ls | grep -w $PkgsName) ]]; then
         echo "$PkgsName already exists!"
    else
         wget $DownloadLink
    fi
}

function install {
    rpm -vih $PkgsName; reval=$?
    if [ $reval == 0 ]; then
         echo "Install $prog success!"
    else 
         echo "Install $prog failure!"
         return 1
    fi 
}

function configure {
    if [ ! -d /etc/rsync ]; then
         mkdir -p /etc/rsync; 
    else
         echo "Directory /etc/rsync already exists!"
    fi
    \cp -rf $ProgDir/conf/* /etc/rsync/ || return 1
    echo "Configure rsync success!"
    chown root:root /etc/rsync/rsyncd.secrets || return 1
    chown $ClientUser:$ClientUser /etc/rsync/rsyncd.passwds || return 1
    chmod 600 /etc/rsync/rsyncd.secrets /etc/rsync/rsyncd.passwds || return 1
    echo "Install rsync success!"
}

function addservice {
    \cp -rf rsync /etc/init.d/rsync || return 1
    chmod +x /etc/init.d/rsync || return 1
    chkconfig --add rsync || return 1
    echo "Add rsync as a service success!"
    chkconfig rsync on || return 1
    service rsync start || return 1
}

initialize
checksource
install
configure
addservice

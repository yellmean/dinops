#!/bin/bash
# eastmoney public tools
# version: v1.0.1
# create by Dinops, 2016-9-28
#
Prog=redis
RedisUser=redis
RedisPort=$1
RedisHome=/mnt/www
ProgDir=$(cd `dirname $0`; pwd)
RedisVersion=stable
PkgsType=tar.gz
DownloadLink=http://download.redis.io/redis-stable.tar.gz

function environment() {
    if [[ "$USER" != "root" ]]; then
        echo "Current user is not root"
    fi
    grep "$RedisUser" /etc/passwd > /dev/null
    if [[ $? -ne 0 ]]; then
        #groupadd $RedisUser
        #useradd -M -g $RedisUser -s /sbin/nologin $RedisUser
        useradd -s /bin/false -M $RedisUser
    fi
}

function checksource {
    cd $ProgDir || return $?
    if [[ -n $(ls | grep -w $Prog-$RedisVersion.$PkgsType) ]]; then
        echo "$Prog-$RedisVersion.$PkgsType is local exists!"
    else 
        wget DownloadLink || return $?
        echo "Download $Prog-$RedisVersion.$PkgsType success!"
    fi
}

function install() {
    cd $ProgDir || return $?
    tar zxvf $Prog-$RedisVersion.$PkgsType || return $?
    cd $Prog-$RedisVersion || return $?
    make test
    if [ -d $RedisHome/redis$1 ]; then
        echo "The directory $RedisHome/redis$1 is exist! Please change redis port!"
        return 3
    else
        mkdir -p $RedisHome/redis$1 || return $?
    fi
    make test || return $?
    make prefix=$RedisHome/redis$1 install || return $?
}

function configure() {
    cd $RedisHome/redis$1 || return $?
}

environment; [ $? -ne 0 ] && exit 1
checksource; [ $? -ne 0 ] && exit 2
install; [ $? -ne 0 ] && exit 3

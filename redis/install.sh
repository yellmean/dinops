#!/bin/bash
# eastmoney public tools
# version: v1.0.1
# create by Dinops, 2016-9-28
#
Prog=redis
RedisHome=/usr/local/redis
ProgDir=$(cd `dirname $0`; pwd)
RedisVersion=stable
PkgsType=tar.gz
DownloadLink=http://download.redis.io/redis-stable.tar.gz

function environment() {
    if [[ "$USER" != "root" ]]; then
        echo "Current user is not root"
    fi
    #grep "$REDIS_USER" /etc/passwd > /dev/null
    #if [[ $? -ne 0 ]]; then  # check user and group
    #    groupadd $REDIS_USER
    #    useradd -M -g $REDIS_USER -s /sbin/nologin $REDIS_USER
    #fi
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
    make || return $?
}

environment; [ $? -ne 0 ] && exit 1
checksource; [ $? -ne 0 ] && exit 2
install; [ $? -ne 0 ] && exit 3

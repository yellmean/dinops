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
        return 1
    fi
    if [[ -z `rpm -qa tcl` ]]; then
        yum install -y tcl || return $?
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
    echo "Start install redis..."
    cd $ProgDir || return $?
    tar zxvf $Prog-$RedisVersion.$PkgsType || return $?
    cd $Prog-$RedisVersion || return $?
    if [ -d $RedisHome/redis$1 ]; then
        echo "The directory $RedisHome/redis$1 exist! Please change redis port!"
        return 3
    else
        mkdir -p $RedisHome/redis$1 || return $?
    fi
    make test > /dev/null || return $?
    make PREFIX=$RedisHome/redis$1 install > /dev/null || return $?
    cp redis.conf $RedisHome/redis$1 || return $?
    cp sentinel.conf $RedisHome/redis$1 || return $?
    mv $RedisHome/redis$1/bin/* $RedisHome/redis$1
    rm -rf $RedisHome/redis$1/bin
    echo "redis installed successs! redis Home directory is $RedisHome/redis$1!"
}

function configure() {
    echo "Start configure redis..."
    cd $RedisHome/redis$1 || return $?
    echo 1 > /proc/sys/vm/overcommit_memory 
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    echo 65535 > /proc/sys/net/core/somaxconn
    sed -i "s/6379/$1/g" redis.conf
    sed -i "s/daemonize no/daemonize yes/g" redis.conf
    sed -i "s/pidfile \/var\/run\/redis_6379.pid/pidfile $RedisHome\/redis$1\/redis.pid/g" redis.conf
    sed -i "s/logfile \"\"/logfile $RedisHome\/redis$1\/redis.log/g" redis.conf
    sed -i "s/dir ./dir $RedisHome\/redis$1/g" redis.conf
    echo "Configure reids success!"
    echo "You should use \"sudo -u $RedisUser /path/to/redis-server /path/to/redis.conf\" to run redis!"
}

environment; [ $? -ne 0 ] && exit 1
checksource; [ $? -ne 0 ] && exit 2
install; [ $? -ne 0 ] && exit 3
configure; [ $? -ne 0 ] && exit 4

ProgDir=$(cd `dirname $0`; pwd)
RedisHome=/usr/local/redis
RedisProg=$RedisHome/bin/redis-server
SentinelProg=$RedisHome/bin/redis-sentinel

function checkredis {
    cd $ProgDir || return $?
    if [[ $Port != 637[0-9] || -z $Port ]]; then
        echo "Warning::Invaild argument, please input a number like 637*!"
        return 1
    fi
    if [ ! -f $RedisProg ]; then 
        echo "Redis server uninstalled, please check it!"
        return 1
    fi
    if [ ! -f "$RedisConf" ]; then 
         cp redis.conf $RedisConf || return $?
    else 
         echo "the port $Port already exists, please change your redis port!"
         return 1
    fi
}

function checksentinel {
    cd $ProgDir || return $?
    if [[ $Port != 2637[0-9] || -z $Port ]]; then
        echo "Warning::Invaild argument, please input a number like 2637*!"
        return 1
    fi
    if [ ! -f $SentinelProg ]; then 
        echo "Sentinel server uninstalled, please check it!"
        return 1
    fi
    if [ ! -f "$RedisConf" ]; then 
         echo "Please install the redis bind $(($Port-2000)) before!"
         return 1
    fi 
    if [ ! -f "$SentinelConf" ]; then 
         cp sentinel.conf $SentinelConf || return $?
    else 
         echo "The port $Port already exists, please change your sentinel port!"
         return 1
    fi
}

function redisconfig {
    sed -i "s/6379/$Port/g" $RedisConf
    if [[ $? -ne 0 ]]; then
       echo "Configure redis server bind $Port failure!"
       rm -rf $RedisConf || return 1
       return 1
    fi
    echo "Configure redis server bind $Port success!"
    echo "You can command: \"$RedisProg $RedisConf\" to run redis server !"
}

function redisoptimize {
    cd $ProgDir || return $?
    cp redis /etc/init.d/redis$Port || return $?
    chkconfig --add redis$Port || return $?
    chkconfig redis$Port on || return $?
    service redis$Port start || return $?
}

function sentinelconfig {
    sed -i "s/26379/$Port/g" $SentinelConf
    if [[ $? -ne 0 ]]; then
       echo "Configure sentinel server bind $Port failure!"
       rm -rf $SentinelConf || return 1
       return 1
    fi
    echo "Configure sentinel server bind $Port success!"
    echo "You can command: \"$SentinelProg $SentinelConf\" to run Sentinel server! "
}

echo "Please choice the server you want install: (redis | sentinel) "
read ServerType
case $ServerType in
    redis)
        echo "Please input the redis server bind port like 637*"
        read Port
        RedisConf=$RedisHome/etc/redis${Port}.conf
        checkredis
        redisconfig
        redisoptimize
        ;;
    sentinel)
        echo "Please input the sentinel server bind port like 637*"
        read Port
        SentinelConf=$RedisHome/etc/sentinel${Port}.conf
        checksentinel
        sentinelconfig
        ;;
    *)
        echo -e "\033[33mUsage: {redis | sentinel}\033[0m"
        exit 1
esac

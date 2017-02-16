#!/bin/bash

progdir=$(cd `dirname "$0"`; pwd)
s='no'

function start() {
    tomcat_array=`ps -ef | grep tomcat | grep -v grep | awk -F " " '{print $9}' | cut -d "/" -f 4`
    for tomcat in $tomcat_array; do
    {
        count=0 
        while true; do
        {
            pid=`ps -ef | grep "$tomcat" | grep -v grep | awk '{print $2}'`
            while [ -z "$pid" ]; do 
            {
                pid=`ps -ef | grep "$tomcat" | grep -v grep | awk '{print $2}'`
                sleep 5
            }
            done
            old_memory=`/usr/java/default/bin/jstat -gcutil "$pid" | awk -F " " '{print $4}' | grep -v O | awk -F "." '{print $1}'`
	    if [ $old_memory -gt 90 ]; then
		let num+=1
	    else
		num=0
	    fi
	    if [ $num -gt 5 ]; then
                su dingjian -c \
		"kill -9 $pid && /mnt/www/$tomcat/bin/startup.sh || return $?;\
		echo `date` >> /mnt/www/logs/jvmstack/$tomcat.log"
		num=0
            fi
            if [ $old_memory -gt 70 ]; then
                let count+=1
            else
                count=0
            fi
            if [ $count -gt 30 ]; then
                a=$(date +%Y%m%d)
                su dingjian -c \
                "echo `date` >> /mnt/www/logs/jvmstack/$tomcat.$a.stack;\
                /usr/java/default/bin/jstack -F $pid >> /mnt/www/logs/jvmstack/$tomcat.$a.stack;\
                echo `date` >> /mnt/www/logs/jvmstack/$tomcat.$a.histo;\
                /usr/java/default/bin/jmap -histo $pid >> /mnt/www/logs/jvmstack/$tomcat.$a.histo;\
                echo `date` >> /mnt/www/logs/jvmstack/$tomcat.$a.pstack;\
                pstack $pid >> /mnt/www/logs/jvmstack/$tomcat.$a.pstack;\
                echo `date` >> /mnt/www/logs/jvmstack/$tomcat.$a.pidcpu;\
                ps -eLo pid,lwp,pcpu | grep $pid >> /mnt/www/logs/jvmstack/$tomcat.$a.pidcpu"
                count=0
                sleep 300
            fi
            sleep 2 
        }
        done || return $?
    }&
    done || return $?
    echo "jvmstack Started"
} 

function stop() {
    ps -ef | grep jvmstack | grep -v grep | awk '($3==1){print $2}'| xargs kill -9 
    echo "jvmstack Stoped"
}

function status() {
    pid_array=`ps -ef | grep jvmstack | grep -v grep | awk '($3==1){print $2}'`
    for pid in $pid_array; do 
        s=yes
    done
}

case $1 in
    start)
        status && reval=$s
        if [ $reval == yes ]; then
            echo "jvmstack is running!"
            echo $pid_array
        elif [ $reval == no ];then
            start
        fi
        ;;
    stop)
        status && reval=$s
        if [ $reval == yes ]; then
            stop
        elif [ $reval == no ]; then
            echo "jvmstack is not running!"
        fi
        ;;
    restart)
        status && reval=$s
        if [ $reval == yes ]; then
            stop
            start
        elif [ $reval == no ]; then
            start
        fi
        ;;
    status)
        status && reval=$s
        if [ $reval == yes ]; then
            echo "jvmstack is running!"
            echo $pid_array
        elif [ $reval == no ]; then
            echo "jvmstack is not running!"
        fi
        ;;
    *)
        echo -e "Usage: $0 {start|stop|restart|status}"
        ;;
esac

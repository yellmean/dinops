#!/bin/sh
ProgName=jdk
ProgVersion=7u25-linux-x64
ProgDir=$(cd `dirname $0`; pwd)
DownloadLink=http://download.oracle.com/otn-pub/java/jdk/7u25-b15/"$ProgName"-"$ProgVersion".rpm

function initialize {
    if [[ "$USER" != "root" ]]; then
        echo "Current user is not root!"
        return 1
    fi
    for i in $(rpm -qa | grep $ProgName | grep -v grep); do 
        sudo rpm -e --nodeps $i || return $?
        echo "Delete rpm -> $i success!"
    done
    if [[ ! -z $(rpm -qa | grep $ProgName | grep -v grep) ]]; then
        echo "-->Failed to remove the defult $ProgName!"
        return 1
    fi
}

function checksource {
    cd "$ProgDir" || return $?
    if [[ -n $(ls | grep -w $ProgName-$ProgVersion.rpm) ]]; then
         echo "$ProgName-$ProgVersion.rpm already exists!"
    else
         wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" $DownloadLink || return $?
    fi
}

function rpm_install {
    rpm -vih $ProgName-$ProgVersion.rpm && java -version || return $?
    if [ $? == 0 ]; then 
         echo "Install $ProgName success!"
    else
         echo "Install $ProgName failure!"
         return 1
    fi 
}

initialize; [ $? -ne 0 ] && exit 1
checksource; [ $? -ne 0 ] && exit 2
rpm_install; [ $? -ne 0 ] && exit 3

:<<!
function tar_install {
    mkdir /usr/local/java
    cd /usr/local/java
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u67-b01/jdk-7u67-linux-x64.tar.gz
    tar -xvf jdk-7u67-linux-x64.tar.gz
    export JAVA_HOME="/usr/local/java/jdk1.7.0_67"
    if ! grep "JAVA_HOME=/usr/local/java/jdk1.7.0_67" /etc/environment 
    then
        echo "JAVA_HOME=/usr/local/java/jdk1.7.0_67" | sudo tee -a /etc/environment 
        echo "export JAVA_HOME" | sudo tee -a /etc/environment 
        echo "PATH=$PATH:$JAVA_HOME/bin" | sudo tee -a /etc/environment 
        echo "export PATH" | sudo tee -a /etc/environment 
        echo "CLASSPATH=.:$JAVA_HOME/lib" | sudo tee -a /etc/environment 
        echo "export CLASSPATH" | sudo tee -a /etc/environment 
    fi
    source /etc/environment  
    echo "======================================="
    echo "jdk is installed !"
}
!

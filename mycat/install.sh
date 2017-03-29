#!/bin/bash

RunUser=mycat
ProgDir=$(cd `dirname $0`; pwd)
MycatHome=/usr/local
MycatUser=root
MycatPassword=@3edcvfr4
MycatSchema="basedb"
MysqlReadUrl=192.168.0.1:3306
MysqlWriteUrl=192.168.0.2:3306
MysqlUser=dingjian
MysqlPassword=dingjian
DownloadLink='http://dl.mycat.io/1.6-RELEASE/Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz'

function checksource {
    cd $ProgDir || return $?
    if [[ -n $(ls | grep -w 'Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz') ]]; then
         echo "Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz already exists!"
    else
         wget $DownloadLink || return $?
    fi
    return 0
}

function environment {
    if [[ "$USER" != "root" ]]; then
        echo "Current user is not root!"
        return 1
    fi
    grep "$RunUser" /etc/passwd > /dev/null
    if [[ $? -ne 0 ]]; then  # check user and group
        useradd -s /sbin/nologin -M $RunUser || return $?
        echo "Add user $RunUser success!"
    fi
    return 0
}

function installing {
    cd $ProgDir || return $?
    echo "Start installing Mycat Server..."
    tar zxvf Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz -C $MycatHome || return $?
    echo "Install Mycat Server success! It home directory is $MycatHome/mycat."
    return 0;
}

function configure {
    cd $MycatHome/mycat || return $?
    sed -i "s/user name=\"test\"/user name=\"$MycatUser\"/g" conf/server.xml
    sed -i "s/test/$MycatPassword/g" conf/server.xml
    sed -i "s/TESTDB/$MycatSchema/g" conf/server.xml
    sed -i "s/TESTDB/$MycatSchema/g" conf/schema.xml
    #cat << EOF > conf/schema.xml
    echo -e '<?xml version="1.0"?>' > conf/schema.xml
    echo -e '<!DOCTYPE mycat:schema SYSTEM "schema.dtd">' >> conf/schema.xml
    echo -e '<mycat:schema xmlns:mycat="http://org.opencloudb/" >' >> conf/schema.xml
    echo -e "\t<schema name=\"$MycatSchema\" checkSQLschema=\"false\" sqlMaxLimit=\"100\" dataNode=\"dn1\"></schema>" >> conf/schema.xml
    echo -e "\t<dataNode name=\"dn1\" dataHost=\"localhost1\" database=\"$MycatSchema\" />" >> conf/schema.xml
    echo -e "\t<dataHost name=\"localhost1\" maxCon=\"1000\" minCon=\"10\" balance=\"0\" writeType=\"0\" dbType=\"mysql\" dbDriver=\"native\" switchType=\"1\"  slaveThreshold=\"100\">" >> conf/schema.xml
    echo -e "\t\t<heartbeat>select user()</heartbeat>" >> conf/schema.xml
    echo -e "\t\t<writeHost host=\"hostM1\" url=\"$MysqlWriteUrl\" user=\"$MysqlUser\" password=\"$MysqlPassword\">" >> conf/schema.xml
    echo -e "\t\t\t<readHost host=\"hostS1\" url=\"$MysqlReadUrl\" user=\"$MysqlUser\" password=\"$MysqlPassword\" />" >> conf/schema.xml
    echo -e "\t\t</writeHost>" >> conf/schema.xml
    echo -e "\t</dataHost>" >> conf/schema.xml
    echo -e '</mycat:schema>' >> conf/schema.xml
    echo -e "Configure Mycat success!"
    return 0
}

checksource; [ $? -ne 0 ] && exit 1
environment; [ $? -ne 0 ] && exit 2
installing; [ $? -ne 0 ] && exit 3
configure $1; [ $? -ne 0 ] && exit 4

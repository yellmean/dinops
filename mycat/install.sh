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
DownloadLink=https://github.com/MyCATApache/Mycat-download/raw/master/1.5-RELEASE/Mycat-server-1.5.1-RELEASE-20161110104159-linux.tar.gz

function checksource {
    cd $ProgDir || return $?
    if [[ -n $(ls | grep -w 'Mycat-server-1.5.1-RELEASE-20161110104159-linux.tar.gz') ]]; then
         echo "Mycat-server-1.5.1-RELEASE-20161110104159-linux.tar.gz already exists!"
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

function install {
    cd $ProgDir || return $?
    echo "Start installing Mycat Server..."
    tar zxvf Mycat-server-1.5.1-RELEASE-20161110104159-linux.tar.gz -C $MycatHome || return $?
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
    echo '<?xml version="1.0"?>' > conf/schema.xml
    echo '<!DOCTYPE mycat:schema SYSTEM "schema.dtd">' >> conf/schema.xml
    echo '<mycat:schema xmlns:mycat="http://org.opencloudb/" >' >> conf/schema.xml
	echo "   <schema name=\"$MycatSchema\" checkSQLschema=\"false\" sqlMaxLimit=\"100\" dataNode=\"dn1\"></schema>" >> conf/schema.xml
	echo "   <dataNode name=\"dn1\" dataHost=\"localhost1\" database=\"$MycatSchema\" />" >> conf/schema.xml
	echo "   <dataHost name=\"localhost1\" maxCon=\"1000\" minCon=\"10\" balance=\"0\" writeType=\"0\" dbType=\"mysql\" dbDriver=\"native\" switchType=\"1\"  slaveThreshold=\"100\">" >> conf/schema.xml
	echo '	   <heartbeat>select user()</heartbeat>' >> conf/schema.xml
	echo "	   <writeHost host=\"hostM1\" url=\"$MysqlWriteUrl\" user=\"$MysqlUser\" password=\"$MysqlPassword\">" >> conf/schema.xml
	echo "	     <readHost host=\"hostS1\" url=\"$MysqlReadUrl\" user=\"$MysqlUser\" password=\"$MysqlPassword\" />" >> conf/schema.xml
	echo '	   </writeHost>' >> conf/schema.xml
	echo '   </dataHost>' >> conf/schema.xml
    echo '</mycat:schema>' >> conf/schema.xml
    echo "Configure Mycat success!"
    return 0
}

checksource; [ $? -ne 0 ] && exit 1
environment; [ $? -ne 0 ] && exit 2
configure $1; [ $? -ne 0 ] && exit 3
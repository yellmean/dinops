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
    cat << EOF > conf/schema.xml
    <?xml version="1.0"?>
    <!DOCTYPE mycat:schema SYSTEM "schema.dtd">
    <mycat:schema xmlns:mycat="http://org.opencloudb/" >
	    <schema name="$MycatSchema" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1"></schema>
	      <dataNode name="dn1" dataHost="localhost1" database="$MycatSchema" />
	      <dataHost name="localhost1" maxCon="1000" minCon="10" balance="0" writeType="0" dbType="mysql" dbDriver="native" switchType="1"  slaveThreshold="100">
		      <heartbeat>select user()</heartbeat>
		      <writeHost host="hostM1" url="$MysqlWriteUrl" user="$MysqlUser" password="$MysqlPassword">
		       <readHost host="hostS1" url="$MysqlReadUrl" user="$MysqlUser" password="$MysqlPassword" />
		      </writeHost>
	      </dataHost>
    </mycat:schema>
    EOF
    reval=$?
    if [ $reval -ne 0 ]; then
        echo "Configure Mycat failure, Please manual configuration!"
        return 3
    fi
    echo "Configure Mycat success!"
    return 0
}

checksource; [ $? -ne 0 ] && exit 1
environment; [ $? -ne 0 ] && exit 2
configure $1; [ $? -ne 0 ] && exit 3

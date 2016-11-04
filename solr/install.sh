#!/bin/bash
RunUser=dingjian
ProgDir=$(cd `dirname $0`; pwd)
ProgName=apache-tomcat
ProgVersion=6.0.36
PkgsType=tar.gz
TomcatHome=/mnt/www
SiteHome=/mnt/www/webapps
DownloadLink=http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.36/bin/$ProgName-$ProgVersion.$PkgsType
SolrVersion=4.2.1
SolrPkgs=solr-4.2.1.war
SolrLnk=http://120.24.219.17/software/solr-4.2.1.war
SolrHome=/mnt/www/webapps



function checksource {
    cd $ProgDir || return $?
    if [[ -n $(ls | grep -w $ProgName-$ProgVersion.$PkgsType) ]]; then
         echo "$ProgName-$ProgVersion.$PkgsType already exists!"
    else
         wget $DownloadLink || return $?
    fi
    if [[ -n $(ls | grep -w $SolrPkgs) ]]; then
         echo "$SolrPkgs already exists!"
    else wget $SolrLnk || return $?
    fi 
    if [[ -n $(ls | grep -w catalina-jmx-remote.jar) ]]; then
         echo "catalina-jmx-remote.jar already exists!"
    else
         wget http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.36/bin/extras/catalina-jmx-remote.jar || return $?
    fi 
    if [[ -n $(ls | grep -w jmxcmd.jar) ]]; then
         echo "jmxcmd.jar already exists!"
    else
         wget http://ncu.dl.sourceforge.net/project/jmxcmd/jmxcmd.jar || return $?
    fi 
}

function environment {
    if [[ "$USER" != "root" ]]; then
        echo "Current user is not root!"
        return 1
    fi
    grep "$RunUser" /etc/passwd > /dev/null
    if [[ $? -ne 0 ]]; then  # check user and group
        groupadd $RunUser || return $?
        useradd -g $RunUser -s $RunUser || return $?
        echo "Add user $RunUser success!"
    fi
    return 0
}

function configure {
    if [[ $1 != 9[0-9]90 || -z $1 ]]; then {
        echo "Warning::Invaild argument, please input a integer number like 9*90!"
        exit 1
    } 
    fi
    echo "Start build the Tomcat home......"
    if [ ! -d "$TomcatHome/tomcat$1" ]; then
         mkdir -p $TomcatHome/tomcat$1 || return $?
    else
         echo "Warning::This directory $TomcatHome/tomcat$1 is exists, Please change your port!"
         return 1
    fi
    tar zxf $ProgName-$ProgVersion.$PkgsType || return $?
    mv $ProgName-$ProgVersion/* $TomcatHome/tomcat$1 && rm -rf $ProgName-$ProgVersion || return $?
    echo "Finish build the Tomcat home!"
    echo "Start modifying the Tomcat configuration file......"
    # configure tomcat port
    sed -i "s/8080/$1/g" $TomcatHome/tomcat$1/conf/server.xml || return $?
    sed -i "s/8005/$(($1+5))/g" $TomcatHome/tomcat$1/conf/server.xml || return $?
    sed -i "s/8443/$(($1+3))/g" $TomcatHome/tomcat$1/conf/server.xml || return $?
    sed -i "s/8009/$(($1+9))/g" $TomcatHome/tomcat$1/conf/server.xml || return $?
    sed -i '/connectionTimeout="20000"/i\\t\texecutor="tomcatThreadPool"' $TomcatHome/tomcat$1/conf/server.xml || return $?
    sed -i '/connectionTimeout="20000"/i\\t\tmaxThreads="1000"' $TomcatHome/tomcat$1/conf/server.xml || return $?
    sed -i '/connectionTimeout="20000"/i\\t\tuseBodyEncodingForURI="true"' $TomcatHome/tomcat$1/conf/server.xml || return $?
    sed -i '/connectionTimeout="20000"/i\\t\tURIEncoding="UTF-8"' $TomcatHome/tomcat$1/conf/server.xml || return $?
    # configure tomcat logformat
    sed -i '/<\/Host>/i\\t<Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"' $TomcatHome/tomcat$1/conf/server.xml || return $?
    sed -i '/<\/Host>/i\\t\tprefix="localhost_access_log." suffix=".txt" pattern="%a %t %H %S %r %B %D %s %T" resolveHosts="false"/>' $TomcatHome/tomcat$1/conf/server.xml || return $?
    # configure jmx monitor port
    sed -i "/<GlobalNamingResources>/i\\\t<Listener className=\"org.apache.catalina.mbeans.JmxRemoteLifecycleListener\" rmiRegistryPortPlatform=\"$(($1+6))\" rmiServerPortPlatform=\"$(($1+7))\" \/>" $TomcatHome/tomcat$1/conf/server.xml || return $?
    # configure jmx monitor arguments in catalina.sh
    PrivateIP=`ifconfig | grep "inet" | grep -v "127.0.0.1" | awk '{print $2}'|tr -d "addr:" | sed -n 1p` || return $?
    sed -i "/cygwin=false/i\CATALINA_OPTS=\"-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=$PrivateIP\"" $TomcatHome/tomcat$1/bin/catalina.sh || return $?
    # configue tomcat manager
    sed -i '/<\/tomcat-users>/i\\t<role rolename="manager"\/>' $TomcatHome/tomcat$1/conf/tomcat-users.xml || return $?
    sed -i '/<\/tomcat-users>/i\\t<user username="tomcat" password="dingjian" roles="manager"\/>' $TomcatHome/tomcat$1/conf/tomcat-users.xml || return $?
    # configure tomcat script setenv.sh
    \cp -rf setenv.sh $TomcatHome/tomcat$1/bin/setenv.sh || return $?
    echo "Copy setenv.sh to tomcat bin success!"
    # configure tomcat script restart.sh
    \cp -rf restart.sh $TomcatHome/tomcat$1/bin/restart.sh || return $?
    echo "Copy restart.sh to tomcat bin success!"
    \cp -rf catalina-jmx-remote.jar $TomcatHome/tomcat$1/lib || return $?
    echo "Copy catalina-jmx-remote.jar to tomcat lib success!"
    \cp -rf jmxcmd.jar $TomcatHome/tomcat$1/lib || return $?
    echo "Copy jmxcmd.jar to tomcat bin success!"
    if [[ ! -d $TomcatHome/tomcat$1/conf/Catalina/localhost ]]; then
        mkdir -p $TomcatHome/tomcat$1/conf/Catalina/localhost || return $?
    fi
    echo '<?xml version="1.0" encoding="UTF-8"?>' > $TomcatHome/tomcat$1/conf/Catalina/localhost/manager.xml || return $?
    echo '<Context antiResourceLocking="false" privileged="true" useHttpOnly="true" />' >> $TomcatHome/tomcat$1/conf/Catalina/localhost/manager.xml || return $?
    echo '<?xml version="1.0" encoding="UTF-8"?>' > $TomcatHome/tomcat$1/conf/Catalina/localhost/host-manager.xml || return $?
    echo '<Context antiResourceLocking="false" privileged="true" useHttpOnly="true" />' > $TomcatHome/tomcat$1/conf/Catalina/localhost/host-manager.xml || return $?
    echo "Finish modifying the Tomcat configuration file!"
    # configure tomcat solr path
    echo "<Context docBase=\"$SolrHome/$SolrPkgs\" debug=\"0\" crossContext=\"true\">" > $TomcatHome/tomcat$1/conf/Catalina/localhost/solr.xml || return $?
    echo "	<Environment name=\"solr/home\" type=\"java.lang.String\" value=\"$SolrHome/solr$1\" override=\"true\" />" >> $TomcatHome/tomcat$1/conf/Catalina/localhost/solr.xml || return $?
    echo "</Context>" >> $TomcatHome/tomcat$1/conf/Catalina/localhost/solr.xml || return $?
    echo "Configure $TomcatHome/tomcat$1/conf/Catalina/localhost/solr.xml success!"
    if [[ ! -d $SolrHome/solr$1 ]]; then
        mkdir -p $SolrHome/solr$1 || return $?
    fi
    \cp -rf $SolrPkgs $SolrHome || return $?
    echo "Copy $SolrPkgs to $SolrHome success!"
    \cp -rf conf/* $SolrHome/solr$1 || return $?
    chown -R $RunUser:$RunUser $TomcatHome/tomcat$1 || return $?
    chown -R $RunUser:$RunUser $SolrHome/solr$1 || return $?
    echo "Tomcat installation success, the installation directory for $TomcatHome/tomcat$1, listening port for $1!"
    echo "Solr installation success, the installation directory for $SolrHome/solr$1, You should go to the directory configuration!"
    echo "You must use the $RunUser user to run Tomcat!"
}

checksource; [ $? -ne 0 ] && exit 1
environment; [ $? -ne 0 ] && exit 2
configure $1; [ $? -ne 0 ] && exit 3

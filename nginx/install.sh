#!/bin/bash
# eastmoney public tools
# version: v1.0.1
# create by Dinops, 2016-9-28
#
NginxUser=nobody
NginxHome=/usr/local/nginx
ProgName=nginx
ProgVersion=1.10.1
PkgsType=tar.gz
ProgDir=$(cd `dirname $0`; pwd)
DownloadLink=http://nginx.org/download/$ProgName-$ProgVersion.$PkgsType

cd $ProgDir || return $?
function environment {
    if [[ "$USER" != "root" ]]; then
        echo "Current user is not root"
        return 1
    fi
    yum -y install wget curl pcre pcre-devel zlib zlib-devel gcc gcc-c++ &> /tmp/nginx_install.log
    grep "$NginxUser" /etc/passwd > /dev/null
    if [[ $? -ne 0 ]]; then  # check user and group
        groupadd $NginxUser || return $?
        useradd -M -g $NginxUser -s /sbin/nologin $NginxUser || return $?
    fi
    return 0
}

function checksource {
    if [[ -n $(ls | grep -w $ProgName-$ProgVersion.$PkgsType) ]]; then
         echo "$ProgName-$ProgVersion.$PkgsType already exists!"
    else
         wget $DownloadLink || return $?
    fi 
}

function install {
    # Compile before installation configuration
    if [ ! -d $NginxHome ]; then 
        mkdir -p $NginxHome || return $?
        echo "Create nginx home  $NginxHome success!"
    else
        echo "Nginx home $NginxHome already exists!"
    fi
    tar xzf $ProgName-$ProgVersion.$PkgsType && cd $ProgName-$ProgVersion || return $?
    ./configure --prefix=$NginxHome --user=$NginxUser --group=$NginxUser --with-http_stub_status_module &> /tmp/nginx_install.log
    if [[ $? -ne 0 ]]; then
        echo "Check nginx configuration failure!"
        return 1
    else
        echo "Start make nginx......"
        make &> /tmp/nginx_install.log || return $?
        echo "Make nginx success!"
        echo "Start make install nginx......"
        make install &> /tmp/nginx_install.log  || return $?
        echo "Make install nginx success!"
        cd $ProgDir && rm -rf $ProgName-$ProgVersion || return $?
    fi
}

function optimize {
    if [ -L /usr/local/sbin/nginx ]; then
        rm -rf /usr/local/sbin/nginx || return $?
    fi
    ln -s $NginxHome/sbin/nginx /usr/local/sbin/nginx > /dev/null || return $?
    echo "Add nginx command to bash success!"
    # cp -f $CONFDIR/nginx/nginx.conf $NGINX_HOME/conf/nginx.conf
    processor=`cat /proc/cpuinfo | grep "processor" | wc -l` || return $?
    sed -i "s/^w.*;$/worker_processes  ${processor};/g" $NginxHome/conf/nginx.conf || return $?
    echo "Amend the "worker_processes" field to the value of the processor success!"
    \cp -rf nginx /etc/init.d/nginx && chmod +x /etc/init.d/nginx || return $?
    chkconfig --add nginx && chkconfig nginx on || return $?
    echo "Optimize nginx to service success!";
    /etc/init.d/nginx configtest || return $? 
    service nginx restart || return $?
}

function validate {
    # Modified index.html page content
    content=$"deployment on $(date "+%Y-%m-%d %H:%M:%S")"
    echo $content > $NginxHome/html/index.html
    # View the index.html, and the output of the modified index.html page
    /etc/init.d/nginx status || return $?
    echo -n "Index.html: "
    curl http://localhost || return $?
};

environment; [ $? -eq 0 ] || exit 1
checksource; [ $? -eq 0 ] || exit 2
install; [ $? -eq 0 ] || exit 3
optimize; [ $? -eq 0 ] || exit 4
validate; [ $? -eq 0 ] || exit 5

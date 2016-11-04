#!/bin/bash
ProgDir=$(cd `dirname $0`; pwd)
DbHost=dingjian.mysql.rds.aliyuncs.com:3306
DbUser=dingjian
DbPasswd=DJsoft_201693821

function globalsetting {
    cd $ProgDir || return $?
    if [[ $1 != [a-zA-Z0-9]* ]]; then
        echo "Warning::Invaild argument, please input a string name for Solr directory!"
        return 1
    fi
    if [ ! -d "$1" ]; then 
         mkdir -p $1 || return $?
         echo "Create solr home directory $1 success!"
    else 
         echo "Directory $1 exists, please change your solr home directory!"
         return 1
    fi
    echo "please input the solrtype:"
    echo "1. ebbroker;"
    echo "2. ebgarden;"
    echo "3. ebroomlistingimage;"
    echo "4. listing;"
    echo "5. phoneCode;"
    echo "6. resourceCustomer."
    echo -n "Please input the solrtype:(1|2|3|4|5|6) "
    read solrtype
    case $solrtype in
        1)
            echo "Your Solr type is ebbroker!"
            \cp -rf module/ebbroker/* $1 || return $?
            ;;
        2)
            echo "Your Solr type is ebgarden!"
            \cp -rf module/ebgarden/* $1 || return $?
            ;;
        3)
            echo "Your Solr type is ebroomlistingimage!"
            \cp -rf module/ebroomlistingimage/* $1 || return $?
            ;;
        4)
            echo "Your Solr type is listing!"
            \cp -rf module/listing/* $1 || return $?
            ;;
        5)
            echo "Your Solr type is phoneCode!"
            \cp -rf module/phoneCode/* $1 || return $?
            ;;
        6)
            echo "Your Solr type is resourceCustomer!"
            \cp -rf module/resourceCustomer/* $1 || return $?
            ;;
        *)
            echo -e "\033[33mUsage: $0 {1|2|3|4|5|6}\033[0m"
            rm -rf $1 || return $? 
            return 1
            ;;
    esac
}

function solrconfig {
    cd $ProgDir || return $?
    # configure solr.xml
    sed -i "/<\/cores>/i\\\t<core schema=\"schema.xml\" loadOnStartup=\"true\" instanceDir=\"$1/\" transient=\"false\" name=\"$1\" config=\"solrconfig.xml\" dataDir=\"data\"/>" solr.xml || return $?
    echo "Add solr name and instanceDir to solr.xml success!"
    # configure data-config.xml 
    cd $1/conf || return $?
    sed -i "s/databaseHost/$DbHost/g"  data-config.xml || return $?
    echo "Setting database host $DbHost success!"
    read -p "Please input the DatabaseName: " DbName
    sed -i "s/databaseName/$DbName/g"  data-config.xml || return $?
    echo "Setting database name $DbName success!"
    sed -i "s/databaseUser/$DbUser/g"  data-config.xml || return $?
    echo "Setting database user $DbUser success!"
    sed -i "s/databasePassword/$DbPasswd/g"  data-config.xml || return $?
    echo "Setting database passowrd $DbPasswd success!"
    echo "Configure solr core $1 success! Restart Tomcat to take effect!"
}

globalsetting $1; [[ $? -ne 0 ]] && exit 1
solrconfig $1; [[ $? -ne 0 ]] && exit 2

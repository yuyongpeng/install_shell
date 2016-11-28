#!/bin/bash

#while getopts "v:bc" arg  
#do  
#    case $arg in  
#        a)  
#            #参数存在$OPTARG中  
#            echo "a's arg:$OPTARG" ;;  
#        v)  
#            echo "b" ;;  
#        c)  
#            echo "c" ;;   
#        ?)  
#            #当有不认识的选项的时候arg为?  
#            echo "unkonw argument" exit 1 ;;  
#    esac  
#done 
mongoRepoFile=/etc/yum.repos.d/mongodb-org-3.2.repo
touch $mongoRepoFile
cat > $mongoRepoFile <<END
[mongodb-org-3.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.2.asc
END

yum install -y mongodb-org

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
mongoDbPath=/data/mongodb
# root 角色的用户
rootAsUser=root
rootAsPass=modernmedia
# userAdminAnyDatabase 角色用户
userAdminAnyDatabase_user1=user1
userAdminAnyDatabase_pass1=pass1
# readWrite 角色用户
readWrite_user1=user1
readWrite_pass1=pass1


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
mkdir -p ${mongoDbPath}
chown -R mongod.mongod ${mongoDbPath}
cp mongod.conf /etc/
sed -i 's/dataMongoPath/${mongoDbPath/\//\\\/}/g' /etc/mongod.conf

# 初始化数据库的权限用户



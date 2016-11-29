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

replSetName=rs_push

# root 角色的用户
rootAsUser=root
rootAsPass=1q2w3e4r
# userAdminAnyDatabase 角色用户
userAdminAnyDatabase_user1=user1
userAdminAnyDatabase_pass1=pass1
# readWriteAnyDatabase 角色用户
readWriteAnyDatabase_user1=user1
readWriteAnyDatabase_pass1=pass1


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
repl_mongoDbPath=${mongoDbPath//\//\\/}
echo $repl_mongoDbPath
sed -i "s/dataMongoPath/${repl_mongoDbPath}/g" /etc/mongod.conf
sed -i "s/rs_name/${replSetName}/g" /etc/mongod.conf

# 配置副本集
keyFile=mongodb-keyfile
openssl rand -base64 90 > ${mongoDbPath}/${keyFile}
chown mongod.mongod ${mongoDbPath}/${keyFile}
/etc/init.d/mongod start
#service mongod restart

arbiter=10.11.27.95
master=10.11.82.245
master_pass=22
second=10.11.91.180
second_pass=11
PORT=27017 

# 在master 节点上执行即可
# 初始化副本集集群配置和数据库的权限用户
mongo <<END
config={_id:"${replSetName}",members:[{_id:0,host:"${arbiter}:${PORT}",arbiterOnly:true},{_id:1,host:"${master}:${PORT}",priority:1},{_id:2,host:"${second}:${PORT}",priority:2}]};
rs.initiate(config);
use admin;
db.createUser({user:"${rootAsUser}",pwd:"${rootAsPass}",roles:["root"]});
db.createUser({user:"${userAdminAnyDatabase_user1}",pwd:"${userAdminAnyDatabase_pass1}",roles:["userAdminAnyDatabase"]}); 
db.createUser({user:"${readWriteAnyDatabase_user1}",pwd:"${readWriteAnyDatabase_pass1}",roles:["readWriteAnyDatabase]});
END

sed -i "s/#  authorization/  authorization/g" /etc/mongod.conf
service mongod restart

mongo -u ${readWriteAnyDatabase_user1} -p ${readWriteAnyDatabase_pass1} --authenticationDatabase admin <<END
use test;
db.testkk.insert({"id":"111"});
db.testkk.find();
END


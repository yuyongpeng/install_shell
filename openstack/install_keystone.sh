#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#
cd $(dirname $0)
. ./openstack_config.sh
#----------------------------[ 安装keystone ]----------------------------------------
mysql -uroot -p${MYSQL_ROOT_PASS} -e "create database keystone default charset=utf8;"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
#mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'${CONTROLLER_HOSTNAME}' IDENTIFIED BY '${KEYSTONE_DBPAS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "flush privileges;"
yum install -y openstack-keystone httpd mod_wsgi
#配置keystone.conf
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:${KEYSTONE_DBPASS}@${CONTROLLER_HOSTNAME}/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet
# 初始化数据库
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password ${ADMIN_PASS} \
  --bootstrap-admin-url http://${CONTROLLER_HOSTNAME}:35357/v3/ \
  --bootstrap-internal-url http://${CONTROLLER_HOSTNAME}:35357/v3/ \
  --bootstrap-public-url http://${CONTROLLER_HOSTNAME}:5000/v3/ \
  --bootstrap-region-id RegionOne
# 修改apache 配置
sed -i "s/#ServerName www.*$/ ServerName ${CONTROLLER_HOSTNAME}:80/g" /etc/httpd/conf/httpd.conf
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service
systemctl restart httpd.service
# 配置admin账号环境变量
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_DOMAIN_NAME=default
export OS_AUTH_URL=http://${CONTROLLER_HOSTNAME}:35357/v3
export OS_IDENTITY_API_VERSION=3
# 本指南使用一个你添加到你的环境中每个服务包含独有用户的service 项目。创建``service``项目：
openstack project create --domain default --description "Service Project" service
# 创建``demo`` 项目：
openstack project create --domain default --description "Demo Project" demo
# 创建``demo`` 用户：
expect<<END
spawn openstack user create --domain default --password-prompt demo
expect {
"User Password:" {send "${DEMO_PASS}\n"; exp_continue}
"Repeat User Password:" {send "${DEMO_PASS}\n"}
}
END

# 创建 bbwc 项目
openstack project create --domain default --description "${OPENSTACK_COMMON_PROJECTNAME} Project" ${OPENSTACK_COMMON_PROJECTNAME}
# 创建bbwc项目下的普通用户
expect<<END
spawn openstack user create --domain default --password-prompt ${OPENSTACK_COMMON_USERNAME}
expect {
"User Password:" {send "${OPENSTACK_COMMON_USER_PASS}\n"; exp_continue}
"Repeat User Password:" {send "${OPENSTACK_COMMON_USER_PASS}\n"}
}
END
sleep 3
# 创建 user 角色：
openstack role create user
# 将demo项目，demo用户，添加到 user角色
openstack role add --project demo --user demo user
# 将bbwc项目，bbwc用户，添加到 user角色
openstack role add --project ${OPENSTACK_COMMON_PROJECTNAME} --user ${OPENSTACK_COMMON_USERNAME} user

# 创建 OpenStack 客户端环境脚本
touch ${OPENRC_PATH}/${OPENRC_ADMIN_USER}
cat > ${OPENRC_PATH}/${OPENRC_ADMIN_USER}<<END
#!/bin/bash
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_AUTH_URL=http://${CONTROLLER_HOSTNAME}:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
END
# 创建openstack客户端demo用户的环境脚本
touch ${OPENRC_PATH}/${OPENRC_DEMO_USER}
cat > ${OPENRC_PATH}/${OPENRC_DEMO_USER}<<END
#!/bin/bash
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=${DEMO_PASS}
export OS_AUTH_URL=http://${CONTROLLER_HOSTNAME}:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
END
# 创建openstack客户端bbwc用户的环境脚本
touch ${OPENRC_PATH}/${OPENSTACK_COMMON_USERNAME}-openrc
cat > ${OPENRC_PATH}/${OPENSTACK_COMMON_USERNAME}-openrc<<END
#!/bin/bash
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=${OPENSTACK_COMMON_PROJECTNAME}
export OS_USERNAME=${OPENSTACK_COMMON_USERNAME}
export OS_PASSWORD=${OPENSTACK_COMMON_USER_PASS}
export OS_AUTH_URL=http://${CONTROLLER_HOSTNAME}:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
END

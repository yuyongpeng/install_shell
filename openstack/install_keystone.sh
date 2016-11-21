#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#

#----------------------------[ 安装keystone ]----------------------------------------
mysql -uroot -p${MYSQL_ROOT_PASS} -e "create database keystone default charset=utf8;"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "flush privileges;"
yum install -y openstack-keystone httpd mod_wsgi
#配置keystone.conf
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:${KEYSTONE_DBPASS}@controller/keystone
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

openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
#openstack user create --domain default --password-prompt demo
expect<<END
spawn openstack user create --domain default --password-prompt demo
expect "User Password:"
send "${DEMO_PASS}\n"
expect "Repeat User Password:"
send "${DEMO_PASS}\n"
END
openstack role create user
openstack role add --project demo --user demo user


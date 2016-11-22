#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#
cd $(dirname $0)
. openstack_config.sh
#----------------------------[ 安装镜像服务 ]----------------------------------------o
# 初始化glance使用的数据库
mysql -uroot -p${MYSQL_ROOT_PASS} -e "create database glance default charset=utf8;"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'glance'@'%' IDENTIFIED BY '${GLACNE_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "flush privileges;"

# 获得访问权限
. ${OPENRC_PATH}/${OPENRC_ADMIN_USER}
#. /root/admin-openrc
#创建 glance 用户：
expect<<END
spawn openstack user create --domain default --password-prompt glance
expect {
"User Password:" {send "${GLANCE_PASS}\n"; exp_continue}
"Repeat User Password:" {send "${GLANCE_PASS}\n"}
}
END

#添加 admin 角色到 glance 用户和 service 项目上。
openstack role add --project service --user glance admin
#创建``glance``服务实体：
openstack service create --name glance --description "OpenStack Image" image
# 创建镜像服务的 API 端点：
openstack endpoint create --region ${REGION_NAME} image public http://${CONTROLLER_HOSTNAME}:9292
openstack endpoint create --region ${REGION_NAME} image internal http://${CONTROLLER_HOSTNAME}:9292
openstack endpoint create --region ${REGION_NAME} image admin http://${CONTROLLER_HOSTNAME}:9292

yum install -y openstack-glance

openstack-config --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:${GLANCE_DBPASS}@${CONTROLLER_HOSTNAME}/glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://${CONTROLLER_HOSTNAME}:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://${CONTROLLER_HOSTNAME}:35357 
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers ${CONTROLLER_HOSTNAME}:11211
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken password ${GLANCE_PASS}
openstack-config --set /etc/glance/glance-api.conf paste_deploy flavor keystone
openstack-config --set /etc/glance/glance-api.conf glance_store stores file,http
openstack-config --set /etc/glance/glance-api.conf glance_store default_store file 
openstack-config --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/
openstack-config --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:GLANCE_DBPASS@${CONTROLLER_HOSTNAME}/glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://${CONTROLLER_HOSTNAME}:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://${CONTROLLER_HOSTNAME}:35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers ${CONTROLLER_HOSTNAME}:11211
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_type password
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_name default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_name default
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken username glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken password ${GLANCE_PASS}
openstack-config --set /etc/glance/glance-registry.conf paste_deploy flavor keystone 
# 初始化glance数据库
su -s /bin/sh -c "glance-manage db_sync" glance
# 启动镜像服务并将其配置为随机启动：
systemctl enable openstack-glance-api.service  openstack-glance-registry.service
systemctl restart openstack-glance-api.service  openstack-glance-registry.service




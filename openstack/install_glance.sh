#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#

#----------------------------[ 安装镜像服务 ]----------------------------------------o
# 初始化glance使用的数据库
mysql -uroot -p${MYSQL_ROOT_PASS} -e "create database glance default charset=utf8;"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'glance'@'%' IDENTIFIED BY '${GLACNE_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "flush privileges;"

# 获得访问权限
. /root/admin-openrc
#创建 glance 用户：
expect<<END
spawn openstack user create --domain default --password-prompt glance
expect "User Password:"
send "${GLANCE_PASS}\n"
expect "Repeat User Password:"
send "${GLANCE_PASS}\n"
END
#添加 admin 角色到 glance 用户和 service 项目上。
openstack role add --project service --user glance admin
#创建``glance``服务实体：
openstack service create --name glance --description "OpenStack Image" image
# 创建镜像服务的 API 端点：
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

yum install -y openstack-glance

openstack-config --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:${GLANCE_DBPASS}@controller/glance
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://controller:35357 
openstack-config --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers controller:11211
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
openstack-config --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://controller:5000
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://controller:35357
openstack-config --set /etc/glance/glance-registry.conf keystone_authtoken memcached_servers controller:11211
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
systemctl start openstack-glance-api.service  openstack-glance-registry.service

#验证glance安装
. /root/admin-openrc
cd /tmp
wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
openstack image create "cirros" \ 
 --file cirros-0.3.4-x86_64-disk.img \
 --disk-format qcow2 --container-format bare \
 --public
openstack image list


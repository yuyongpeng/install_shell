#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
# 安装配置计算节点的neutron网络
#
cd $(dirname $0)
. ./openstack_config.sh
#----------------------------[ 安装neutron服务的controller节点 ]----------------------------------------
# 初始化glance使用的数据库
mysql -uroot -p${MYSQL_ROOT_PASS} -e "create database neutron default charset=utf8;"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '${NEUTRON_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '${NEUTRON_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "flush privileges;"

# 获得访问权限
. ${OPENRC_PATH}/${OPENRC_ADMIN_USER}
#. /root/admin-openrc

#创建 neutron 用户：
expect<<END
spawn openstack user create --domain default --password-prompt neutron
expect {
"User Password:" {send "${NEUTRON_PASS}\n"; exp_continue}
"Repeat User Password:" {send "${NEUTRON_PASS}\n"}
}
END

#添加 admin 角色到 neutron 用户和 service 项目上。
openstack role add --project service --user neutron admin
#创建``neutron``服务实体：
openstack service create --name neutron --description "OpenStack Networking" network
# 创建网络服务API端点：
openstack endpoint create --region ${REGION_NAME} network public http://${CONTROLLER_HOSTNAME}:9696
openstack endpoint create --region ${REGION_NAME} network internal http://${CONTROLLER_HOSTNAME}:9696
openstack endpoint create --region ${REGION_NAME} network admin http://${CONTROLLER_HOSTNAME}:9696

# 配置网络选项































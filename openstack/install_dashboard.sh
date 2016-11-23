#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#
cd $(dirname $0)
. ./openstack_config.sh
confFile=/etc/openstack-dashboard/local_settings

#----------------------------[ 安装dashboard服务 ]----------------------------------------
# 安装软件
yum install -y openstack-dashboard
# 修改配置文件
mv ${confFile} ${confFile}_bak
cp config/local_settings ${confFile}
sed -i ${confFile} 's/^OPENSTACK_HOST = "controller"/OPENSTACK_HOST = "${CONTROLLER_HOSTNAME}"/g'
sed -i ${confFile} 's/127.0.0.1:11211/${CONTROLLER_HOSTNAME}:11211/g'
# 重启web服务器以及会话存储服务：
systemctl restart httpd.service memcached.service

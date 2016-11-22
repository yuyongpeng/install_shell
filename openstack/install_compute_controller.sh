#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
# 安装配置控制节点
#
cd $(dirname $0)
. ./openstack_config.sh
#----------------------------[ 安装计算服务的controller节点 ]----------------------------------------o
# 初始化 nova 使用的数据库
mysql -uroot -p${MYSQL_ROOT_PASS} -e "create database nova default charset=utf8;"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "create database nova_api default charset=utf8;"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova_api'@'localhost' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova_api'@'%' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "flush privileges;"


# 获得 admin 凭证来获取只有管理员能执行的命令的访问权限：
. ${OPENRC_PATH}/${OPENRC_ADMIN_USER}
#. /root/admin-openrc
#创建 nova 用户：
expect<<END
spawn openstack user create --domain default --password-prompt nova
expect {
"User Password:" {send "${NOVA_PASS}\n"; exp_continue}
"Repeat User Password:" {send "${NOVA_PASS}\n"}
}
END

# 给 nova 用户添加 admin 角色：
openstack role add --project service --user nova admin
#创建``nova``服务实体：
openstack service create --name nova  --description "OpenStack Compute" compute
# 创建 Compute 服务 API 端点 ：
openstack endpoint create --region ${REGION_NAME} compute public http://${CONTROLLER_HOSTNAME}:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region ${REGION_NAME} compute internal http://${CONTROLLER_HOSTNAME}:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region ${REGION_NAME} compute admin http://${CONTROLLER_HOSTNAME}:8774/v2.1/%\(tenant_id\)s

# 安装软件包
yum install -y openstack-nova-api openstack-nova-conductor openstack-nova-console openstack-nova-novncproxy openstack-nova-scheduler


# 编辑``/etc/nova/nova.conf``文件
openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://glance:${GLANCE_DBPASS}@${CONTROLLER_HOSTNAME}/glance
# 在``[DEFAULT]``部分，只启用计算和元数据API：
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
# 在``[api_database]``和``[database]``部分，配置数据库的连接：
openstack-config --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:${NOVA_DBPASS}@${CONTROLLER_HOSTNAME}/nova_api
openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://nova:${NOVA_DBPASS}@${CONTROLLER_HOSTNAME}/nova
# 在``[DEFAULT]``部分，配置``RabbitMQ``消息队列访问权限：
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:${RABBIT_PASS}@${CONTROLLER_HOSTNAME}
# 在 “[DEFAULT]” 和 “[keystone_authtoken]” 部分，配置认证服务访问：
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone 
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://${CONTROLLER_HOSTNAME}:5000
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://${CONTROLLER_HOSTNAME}:35357
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers ${CONTROLLER_HOSTNAME}:11211 
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password 
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default 
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default 
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service 
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova
openstack-config --set /etc/nova/nova.conf keystone_authtoken password ${NOVA_PASS}
# 在 [DEFAULT 部分，配置``my_ip`` 来使用控制节点的管理接口的IP 地址。]
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip ${CONTROLLER_MANAGE_IP}
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True 
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf vnc  vncserver_listen \$my_ip 
openstack-config --set /etc/nova/nova.conf vncserver_proxyclient_address \$my_ip
openstack-config --set /etc/nova/nova.conf glance api_servers http://${CONTROLLER_HOSTNAME}:9292
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp 

# 数据库初始化
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage db sync" nova

# 启动服务
systemctl enable openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl restart openstack-nova-api.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service 

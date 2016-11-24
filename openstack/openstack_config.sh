#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#

# 网络信息
CONTROLLER_HOSTNAME=controller
COMPUTE_HOSTNAME=compute1
# 管理网段 ip
CONTROLLER_MANAGE_IP=10.0.2.53
CONTROLLER_MANAGE_IFNO=enp0s8
# 公网ip
CONTROLLER_PUBLIC_IP=10.0.47.119
CONTROLLER_PUBLIC_IFNO=enp0s9
# compute 服务器的管理网段ip
COMPUTE_MANAGE_IP=10.0.2.53

# 账号信息
MYSQL_ROOT_OLD_PASS=""
MYSQL_ROOT_PASS=modernmedia
#块设备存储服务的数据库密码
CINDER_DBPASS=modernmedia_cinder
#Database password for the dashboard
DASH_DBPASS=modernmedia_dash
#镜像服务的数据库密码
GLANCE_DBPASS=modernmedia_glance
#认证服务的数据库密码
KEYSTONE_DBPASS=modernmedia_keystone
#网络服务的数据库密码
NEUTRON_DBPASS=modernmedia_neutron
#计算服务的数据库密码
NOVA_DBPASS=modernmedia_nova
NOVA_API_DBPASS=modernmedia_nova_api

#admin 用户密码
ADMIN_PASS=modernmediaOsAdmin
#demo 用户的密码
DEMO_PASS=modernmediaOsDemo
#块设备存储服务的 cinder 密码
CINDER_PASS=modernmediaOsCinder
#镜像服务的 glance 用户密码
GLANCE_PASS=modernmediaOsGlance
#网络服务的 neutron 用户密码
NEUTRON_PASS=modernmediaOsNeutron
#计算服务中``nova``用户的密码
NOVA_PASS=modernmediaOsNova

METADATA_SECRET=modernmediaOsMetadata
#RabbitMQ的guest用户密码
RABBIT_PASS=modernmediaRabbit

# 客户端脚本存放路径
OPENRC_PATH=/root
OPENRC_ADMIN_USER=admin-openrc
OPENRC_DEMO_USER=demo-openrc

#openstack keystone 普通用户
OPENSTACK_COMMON_PROJECTNAME=bbwc_proj
OPENSTACK_COMMON_USERNAME=bbwc
OPENSTACK_COMMON_USER_PASS=bbwcModernmedia

#区域名称
REGION_NAME=RegionOne

#卷组名称
VOLUME_GROUP=cinder_volumes

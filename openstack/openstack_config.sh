#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#

# 网络信息
CONTROLLER_HOSTNAME=controller

# 管理网段 ip
CONTROLLER_MANAGE_IP=10.0.2.53
CONTROLLER_MANAGE_IFNO=em1
# 公网ip
CONTROLLER_PUBLIC_IP=
CONTROLLER_PUBLIC_IFNO=em2

# 账号信息
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
#块设备存储服务的 cinder 密码
CINDER_PASS=modernmediaOsCinder
#demo 用户的密码
DEMO_PASS=modernmediaOsDemo
#镜像服务的 glance 用户密码
GLANCE_PASS=modernmediaOsGlance
#网络服务的 neutron 用户密码
NEUTRON_PASS=modernmediaOsNeutron
#计算服务中``nova``用户的密码
NOVA_PASS=modernmediaOsNova

#RabbitMQ的guest用户密码
RABBIT_PASS=modernmediaRabbit


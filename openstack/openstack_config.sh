#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#

# 网络信息
# 管理网段 ip
CONTROLLER_MANAGE_IP=10.0.2.53
CONTROLLER_MANAGE_IFNO=em1
# 公网ip
CONTROLLER_PUBLIC_IP=
CONTROLLER_PUBLIC_IFNO=em2

# 账号信息
MYSQL_ROOT_PASS=1q2w3e4r
#块设备存储服务的数据库密码
CINDER_DBPASS=1q2w3e4r
#Database password for the dashboard
DASH_DBPASS=1q2w3e4r
#镜像服务的数据库密码
GLANCE_DBPASS=1q2w3e4r
#认证服务的数据库密码
KEYSTONE_DBPASS=1q2w3e4r
#网络服务的数据库密码
NEUTRON_DBPASS=1q2w3e4r
#计算服务的数据库密码
NOVA_DBPASS=1q2w3e4r

#admin 用户密码
ADMIN_PASS=1q2w3e4r
#块设备存储服务的 cinder 密码
CINDER_PASS=1q2w3e4r
#demo 用户的密码
DEMO_PASS=1q2w3e4r
#镜像服务的 glance 用户密码
GLANCE_PASS=1q2w3e4r
#网络服务的 neutron 用户密码
NEUTRON_PASS=1q2w3e4r
#计算服务中``nova``用户的密码
NOVA_PASS=1q2w3e4r

#RabbitMQ的guest用户密码
RABBIT_PASS=1q2w3e4r


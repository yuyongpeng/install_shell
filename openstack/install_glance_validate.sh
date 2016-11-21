#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#
cd $(dirname $0)
. ./openstack_config.sh
#----------------------------[ 验证镜像服务 ]----------------------------------------
# 获得 admin 凭证来获取只有管理员能执行的命令的访问权限：
. /root/admin-openrc
#下载源镜像：
cd /tmp
wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
# 将下载的镜像上传到openstack环境
openstack image create "cirros" \
  --file cirros-0.3.4-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --public
# 确认镜像的上传并验证属性：
openstack image list
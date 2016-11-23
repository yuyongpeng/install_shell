#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = storage
# 安装配置 cinder 的 存储 节点
#
cd $(dirname $0)
. ./openstack_config.sh
#----------------------------[ 安装 cinder 服务的存储节点 ]----------------------------------------o
#安装 LVM 包：
yum install -y lvm2
#启动LVM的metadata服务并且设置该服务随系统启动：
systemctl enable lvm2-lvmetad.service
systemctl restart lvm2-lvmetad.service

# 判断是否存在配置文件中定义好的volume_group
volumeGroupCount=`vgs | grep ${VOLUME_GROUP} | wc -l`
if (( volumeGroupCount = 0  )); then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!! Error not volume group [${VOLUME_GROUP}] !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi


# 配置lvm允许访问的磁盘，cinder-volumes所在的磁盘。
lvmConf=/etc/lvm/lvm.conf
cp -rf ${lvmConf} ${lvmConf}_bak
cp config/lvm.conf ${lvmConf}

# 安装软件包：
yum install -y openstack-cinder targetcli python-keystone 

# 在 [database] 部分，配置数据库访问：
openstack-config --set /etc/nova/nova.conf database connection mysql+pymysql://cinder:${CINDER_DBPASS}@${CONTROLLER_HOSTNAME}/cinder
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:${RABBIT_PASS}@${CONTROLLER_HOSTNAME} 
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone 
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://${CONTROLLER_HOSTNAME}:5000 
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url http://${CONTROLLER_HOSTNAME}:35357 
openstack-config --set /etc/nova/nova.conf keystone_authtoken memcached_servers ${CONTROLLER_HOSTNAME}:11211 
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_type password 
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_name default 
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_name default 
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service 
openstack-config --set /etc/nova/nova.conf keystone_authtoken username cinder 
openstack-config --set /etc/nova/nova.conf keystone_authtoken password ${CINDER_PASS} 
openstack-config --set /etc/nova/nova.conf DEFAULT ${CONTROLLER_MANAGE_IP}
openstack-config --set /etc/nova/nova.conf lvm volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver 
openstack-config --set /etc/nova/nova.conf lvm volume_group ${VOLUME_GROUP}
openstack-config --set /etc/nova/nova.conf lvm iscsi_protocol iscsi 
openstack-config --set /etc/nova/nova.conf lvm iscsi_helper lioadm 
# 启用 LVM 后端
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_backends lvm 
# 配置镜像服务 API 的位置
openstack-config --set /etc/nova/nova.conf DEFAULT glance_api_servers http://${CONTROLLER_HOSTNAME}:9292 
# 配置锁路径 
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/cinder/tmp 

# 启动块存储卷服务及其依赖的服务，并将其配置为随系统启动：
systemctl enable openstack-cinder-volume.service target.service
systemctl restart openstack-cinder-volume.service target.service

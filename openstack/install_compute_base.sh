#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#
cd $(dirname $0)
. ./openstack_config.sh
#----------------------------[ 修改hosts ]----------------------------------------
hostnamectl set-hostname ${COMPUTE_HOSTNAME}
controller_row=`cat /etc/hosts | grep ${COMPUTE_HOSTNAME} | wc -l`
if (( controller_row>=1 )); then
	sed -i "s/.* ${COMPUTE_HOSTNAME}/${COMPUTE_MANAGE_IP}    ${COMPUTE_HOSTNAME}/g" /etc/hosts
else
	echo "${COMPUTE_MANAGE_IP}    ${COMPUTE_HOSTNAME}" >> /etc/hosts
fi
#----------------------------[ 安装ntp ]----------------------------------------
yum install -y chrony

sed -i "s/#allow.*$/allow ${CONTROLLER_MANAGE_IP}\/24/g" /etc/chrony.conf
systemctl enable chronyd.service
systemctl restart chronyd.service

#----------------------------[ 安装安装openstack client和selinux的管理 ]----------------------------------------
yum install -y python-openstackclient
yum install -y openstack-selinux


#----------------------------[ 安装openstack-utils ]----------------------------------------
yum install -y openstack-utils

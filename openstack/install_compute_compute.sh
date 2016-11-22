#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
# 安装配置计算节点
#
cd $(dirname $0)
. ./openstack_config.sh
#----------------------------[ 安装计算服务的compute节点 ]----------------------------------------

#安装软件包：
yum install -y openstack-nova-compute sysfsutils

# 编辑``/etc/nova/nova.conf``文件
# 在``[DEFAULT]``部分，配置``RabbitMQ``消息队列访问权限：
openstack-config --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:${RABBIT_PASS}@${CONTROLLER_HOSTNAME}
openstack-config --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit 
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host ${CONTROLLER_HOSTNAME}
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
openstack-config --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password ${RABBIT_PASS}
# 在 “[DEFAULT]” 和 “[keystone_authtoken]” 部分，配置认证服务访问：
openstack-config --set /etc/nova/nova.conf DEFAULT auth_strategy keystone 
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_uri http://${CONTROLLER_HOSTNAME}:5000 
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_url  http://${CONTROLLER_HOSTNAME}:35357 
openstack-config --set /etc/nova/nova.conf keystone_authtoken auth_plugin password 
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_domain_id default 
openstack-config --set /etc/nova/nova.conf keystone_authtoken user_domain_id default 
openstack-config --set /etc/nova/nova.conf keystone_authtoken project_name service 
openstack-config --set /etc/nova/nova.conf keystone_authtoken username nova 
openstack-config --set /etc/nova/nova.conf keystone_authtoken password ${NOVA_PASS}
# 在 [DEFAULT] 部分，配置 my_ip 选项：
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip ${COMPUTE_MANAGE_IP}
# 在 ``[DEFAULT]``部分，启用网络服务支持：
openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron 
openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
openstack-config --set /etc/nova/nova.conf vnc enabled True 
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0 
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address \$my_ip 
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://${CONTROLLER_HOSTNAME}:6080/vnc_auto.html 
openstack-config --set /etc/nova/nova.conf glance host ${CONTROLLER_HOSTNAME}
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp 
openstack-config --set /etc/nova/nova.conf DEFAULT verbose True 

# 
cpuinfo=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if (( cpuinfo>0 )); then
openstack-config --set /etc/nova/nova.conf DEFAULT virt_type kvm
else
openstack-config --set /etc/nova/nova.conf DEFAULT virt_type qemu
fi

# 启动计算服务及其依赖，并将其配置为随系统自动启动：
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl restart libvirtd.service openstack-nova-compute.service

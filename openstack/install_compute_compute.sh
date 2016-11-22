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
yum install -y openstack-nova-compute 

# 编辑``/etc/nova/nova.conf``文件
# 在``[DEFAULT]``部分，只启用计算和元数据API：
openstack-config --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata 
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
# 在 [DEFAULT] 部分，配置 my_ip 选项：
openstack-config --set /etc/nova/nova.conf DEFAULT my_ip ${COMPUTE_MANAGE_IP}
# 在 ``[DEFAULT]``部分，启用网络服务支持：
# 缺省情况下，Compute 使用内置的防火墙服务。由于 Networking 包含了防火墙服务，所以你必须通过使用 nova.virt.firewall.NoopFirewallDriver 来去除 Compute 内置的防火墙服务。
openstack-config --set /etc/nova/nova.conf DEFAULT use_neutron True
openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver 
# 在``[vnc]``部分，启用并配置远程控制台访问：
openstack-config --set /etc/nova/nova.conf vnc enabled True 
openstack-config --set /etc/nova/nova.conf vnc vncserver_listen 0.0.0.0 
openstack-config --set /etc/nova/nova.conf vnc vncserver_proxyclient_address \$my_ip 
openstack-config --set /etc/nova/nova.conf vnc novncproxy_base_url http://${CONTROLLER_HOSTNAME}:6080/vnc_auto.html 
# 在 [glance] 区域，配置镜像服务 API 的位置：
openstack-config --set /etc/nova/nova.conf glance api_servers http://${CONTROLLER_HOSTNAME}:9292
# 在 [oslo_concurrency] 部分，配置锁路径：
openstack-config --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp 
openstack-config --set /etc/nova/nova.conf DEFAULT verbose True 


#### 在 ``[DEFAULT]``部分，启用网络服务支持：
###openstack-config --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
###openstack-config --set /etc/nova/nova.conf DEFAULT security_group_api neutron 
###openstack-config --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
###openstack-config --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

# 确定您的计算节点是否支持虚拟机的硬件加速。 
cpuinfo=`egrep -c '(vmx|svm)' /proc/cpuinfo`
if (( cpuinfo>0 )); then
openstack-config --set /etc/nova/nova.conf DEFAULT virt_type kvm
else
openstack-config --set /etc/nova/nova.conf DEFAULT virt_type qemu
fi

# 启动计算服务及其依赖，并将其配置为随系统自动启动：
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl restart libvirtd.service openstack-nova-compute.service

#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
# 安装配置计算节点
#
cd $(dirname $0)
. ./openstack_config.sh
#----------------------------[ 安装网络服务 ]----------------------------------------o
yum install -y openstack-neutron-linuxbridge ebtables ipset
neutronConf=/etc/neutron/neutron.conf
openstack_config --set ${neutronConf} DEFAULT transport_url rabbit://openstack:RABBIT_PASS@controller 
openstack_config --set ${neutronConf} DEFAULT auth_strategy keystone 
openstack_config --set ${neutronConf} keystone_authtoken keystone_authtoken http://controller:5000 
openstack_config --set ${neutronConf} keystone_authtoken auth_url http://controller:35357 
openstack_config --set ${neutronConf} keystone_authtoken memcached_servers controller:11211 
openstack_config --set ${neutronConf} keystone_authtoken auth_type password 
openstack_config --set ${neutronConf} keystone_authtoken project_domain_name default 
openstack_config --set ${neutronConf} keystone_authtoken user_domain_name default 
openstack_config --set ${neutronConf} keystone_authtoken project_name service 
openstack_config --set ${neutronConf} keystone_authtoken username neutron 
openstack_config --set ${neutronConf} keystone_authtoken password ${NEUTRON_PASS}
openstack_config --set ${neutronConf} oslo_concurrency lock_path /var/lib/neutron/tmp 

# 配置网络选项
# 网络选项2：自服务网络
# 配置Linuxbridge代理
LinuxbridgeAgent=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
openstack_config --set ${LinuxbridgeAgent} linux_bridge physical_interface_mappings provider:PROVIDER_INTERFACE_NAME
# 启用VXLAN覆盖网络，配置覆盖网络的物理网络接口的IP地址，启用layer－2 population：
openstack_config --set ${LinuxbridgeAgent} vxlan enable_vxlan True 
openstack_config --set ${LinuxbridgeAgent} vxlan local_ip OVERLAY_INTERFACE_IP_ADDRESS 
openstack_config --set ${LinuxbridgeAgent} vxlan l2_population True 
# 启用安全组并配置 Linux 桥接 iptables 防火墙驱动：
openstack_config --set ${LinuxbridgeAgent} securitygroup enable_security_group True 
openstack_config --set ${LinuxbridgeAgent} securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver 




# 配置计算服务来使用网络服务
novaConf=/etc/nova/nova.conf 
openstack_config --set ${novaConf} neutron url http://controller:9696 
openstack_config --set ${novaConf} neutron auth_url http://controller:35357 
openstack_config --set ${novaConf} neutron auth_type password 
openstack_config --set ${novaConf} neutron project_domain_name default 
openstack_config --set ${novaConf} neutron user_domain_name default 
openstack_config --set ${novaConf} neutron region_name ${REGION_NAME}
openstack_config --set ${novaConf} neutron project_name service 
openstack_config --set ${novaConf} neutron username neutron 
openstack_config --set ${novaConf} neutron password ${NEUTRON_PASS}
# 重启计算服务：
systemctl restart openstack-nova-compute.service
# 启动Linuxbridge代理并配置它开机自启动：
systemctl enable neutron-linuxbridge-agent.service
systemctl restart neutron-linuxbridge-agent.service

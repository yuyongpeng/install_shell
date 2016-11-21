#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#

#----------------------------[ 修改hosts ]----------------------------------------
controller_row=`cat /etc/hosts | grep ${CONTROLLER_HOSTNAME} | wc -l`
if (( controller_row>=1 )); then
	sed -i "s/.* controller/${CONTROLLER_MANAGE_IP}    ${CONTROLLER_HOSTNAME}/g" /etc/hosts
else
	echo "${CONTROLLER_MANAGE_IP}    ${CONTROLLER_HOSTNAME}" >> /etc/hosts
fi
#----------------------------[ 安装ntp ]----------------------------------------
yum install -y chrony

sed -i "s/#allow.*$/allow ${CONTROLLER_MANAGE_IP}\/24/g" /etc/chrony.conf
systemctl enable chronyd.service
systemctl restart chronyd.service

#----------------------------[ 安装安装openstack client和selinux的管理 ]----------------------------------------
yum install -y python-openstackclient
yum install -y openstack-selinux

#----------------------------[ 安装mariaDB ]----------------------------------------
yum install -y mariadb mariadb-server python2-PyMySQL
cat > /etc/my.cnf.d/openstack.cnf <<EOF
[mysqld]
#bind-address = ${CONTROLLER_MANAGE_IP}
bind-address = 0.0.0.0

default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

systemctl enable mariadb.service
systemctl restart mariadb.service

cd $(dirname $0)
#expect -f ./mysql_secure_installation.exp ${MYSQL_ROOT_PASS}
expect<<END
spawn mysql_secure_installation
expect {
"Enter current password for root (enter for none): " {send "${MYSQL_ROOT_OLD_PASS}\n"; exp_continue}
"Set root password?" {send "\n"; exp_continue}
"Change the root password?" {send "Y\n"; exp_continue}
"New password:" {send "${MYSQL_ROOT_PASS}\n"; exp_continue}
"Re-enter new password:" {send "${MYSQL_ROOT_PASS}\n"; exp_continue}
"Remove anonymous users?" {send "Y\n"; exp_continue}
"Disallow root login remotely?" {send "n\n"; exp_continue}
"Remove test database and access to it?" {send "Y\n"; exp_continue}
"Reload privilege tables now?" {send "Y\n"}
}
interact
END
sleep 3

#----------------------------[ 安装rabbitmq ]----------------------------------------
yum install -y rabbitmq-server
systemctl enable rabbitmq-server.service
systemctl restart rabbitmq-server.service
rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#----------------------------[ 安装memcached ]----------------------------------------
yum install -y memcached python-memcached
systemctl enable memcached.service
systemctl restart memcached.service

#----------------------------[ 安装openstack-utils ]----------------------------------------
yum install -y openstack-utils

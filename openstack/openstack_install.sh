#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#

# 网络信息
# 管理网段 ip
CONTROLLER_MANAGE_IP=10.10.10.240
CONTROLLER_MANAGE_IFNO=em1
# 公网ip
CONTROLLER_PUBLIC_IP=
CONTROLLER_PUBLIC_IFNO=em2

# 账号信息
MYSQL_ROOT_PASS=1q2w3e4r
#admin 用户密码
ADMIN_PASS=1q2w3e4r
#块设备存储服务的数据库密码
CINDER_DBPASS=1q2w3e4r
#块设备存储服务的 cinder 密码
CINDER_PASS=1q2w3e4r
#Database password for the dashboard
DASH_DBPASS=1q2w3e4r
#demo 用户的密码
DEMO_PASS=1q2w3e4r
#镜像服务的数据库密码
GLANCE_DBPASS=1q2w3e4r
#镜像服务的 glance 用户密码
GLANCE_PASS=1q2w3e4r
#认证服务的数据库密码
KEYSTONE_DBPASS=1q2w3e4r
#网络服务的数据库密码
NEUTRON_DBPASS=1q2w3e4r
#网络服务的 neutron 用户密码
NEUTRON_PASS=1q2w3e4r
#计算服务的数据库密码
NOVA_DBPASS=1q2w3e4r
#计算服务中``nova``用户的密码
NOVA_PASS=1q2w3e4r
#RabbitMQ的guest用户密码
RABBIT_PASS=1q2w3e4r

#----------------------------[ 安装yum源 ]----------------------------------------
#当使用RDO包时，我们推荐禁用EPEL，原因是EPEL中的更新破坏向后兼容性。或者使用``yum-versionlock``插件指定包版本号。
yum install -y wget vim expect
cd /etc/yum.repos.d/
rm -rf ./*
#增加centos7的阿里云源
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
#增加openstack newton源（阿里云）
rpm -e --nodeps centos-release-openstack-newton
yum install -y centos-release-openstack-newton
sed -i "s/mirror.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/CentOS-Ceph-Jewel.repo
sed -i "s/buildlogs.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/CentOS-Ceph-Jewel.repo
sed -i "s/debuginfo.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/CentOS-Ceph-Jewel.repo
sed -i "s/mirror.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/CentOS-OpenStack-newton.repo
sed -i "s/buildlogs.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/CentOS-OpenStack-newton.repo
sed -i "s/debuginfo.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/CentOS-OpenStack-newton.repo
sed -i "s/debuginfo.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/CentOS-QEMU-EV.repo
sed -i "s/debuginfo.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/CentOS-QEMU-EV.repo
sed -i "s/debuginfo.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/CentOS-QEMU-EV.repo
#增加rdo源（阿里云）
rpm -e --nodeps rdo-release
yum install -y https://rdoproject.org/repos/rdo-release.rpm
sed -i "s/mirror.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/rdo-qemu-ev.repo
sed -i "s/buildlogs.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/rdo-qemu-ev.repo
sed -i "s/mirror.centos.org/mirrors.aliyun.com/g" /etc/yum.repos.d/rdo-release.repo
rm -rf /etc/yum.repos.d/rdo-testing.repo
# epel源（阿里云）
rpm -e --nodeps epel-release-7
yum install -y yum install http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
sed -i "s/download.fedoraproject.org\/pub/mirrors.aliyun.com/g" /etc/yum.repos.d/epel.repo
rm -rf /etc/yum.repos.d/epel-testing.repo
#更新yum缓存
yum clean all
yum makecache
yum -y update
yum -y upgrade

#----------------------------[ 安装ntp ]----------------------------------------
yum install -y chrony

sed -i "s/#allow.*$/allow ${CONTROLLER_MANAGE_IP}\/24/g" /etc/chrony.conf
systemctl enable chronyd.service
systemctl start chronyd.service


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
systemctl start mariadb.service

expect<<END
spawn mysql_secure_installation
expect “Enter current password for root (enter for none):”
send "\n"
expect “Change the root password? [Y/n]”
send "Y\n"
expect “New password:”
send "${MYSQL_ROOT_PASS}\n"
expect “Re-enter new password:”
send "${MYSQL_ROOT_PASS}\n"
expect “Remove anonymous users? [Y/n]”
send "Y\n"
expect “Disallow root login remotely? [Y/n]”
send "n\n"
expect “Remove test database and access to it? [Y/n]”
send "Y\n"
expect “Reload privilege tables now? [Y/n]”
send "Y\n"
END
#----------------------------[ 安装rabbitmq ]----------------------------------------
yum install -y rabbitmq-server
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service
rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

#----------------------------[ 安装memcached ]----------------------------------------
yum install -y memcached python-memcached
systemctl enable memcached.service
systemctl start memcached.service

#----------------------------[ 安装openstack-utils ]----------------------------------------
yum install -y openstack-utils

#----------------------------[ 安装keystone ]----------------------------------------
mysql -uroot -p${MYSQL_ROOT_PASS} -e "create database keystone default charset=utf8;"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -uroot -p${MYSQL_ROOT_PASS} -e "flush privileges;"
yum install -y openstack-keystone httpd mod_wsgi
#配置keystone.conf
openstack-config --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:${KEYSTONE_DBPASS}@controller/keystone
openstack-config --set /etc/keystone/keystone.conf token provider fernet
# 初始化数据库
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password ${ADMIN_PASS} \
  --bootstrap-admin-url http://controller:35357/v3/ \
  --bootstrap-internal-url http://controller:35357/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne
# 修改apache 配置
sed -i "s/#ServerName www.*$/ ServerName controller:80/g" /etc/httpd/conf/httpd.conf
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service
systemctl start httpd.service
# 配置admin账号环境变量
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_DOMAIN_NAME=default
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3

openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password-prompt demo
openstack role create user
openstack role add --project demo --user demo user


expect<<END
spawn openstack user create --domain default --password-prompt demo4
expect "User Password:"
send "123456\n"
expect "Repeat User Password:"
send "123456\n"
END
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------
#----------------------------[ 安装 ]----------------------------------------

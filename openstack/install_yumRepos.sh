#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#

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



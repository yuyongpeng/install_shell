#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#

# 包含 配置信息
cd $(dirname $0)
#. openstack_config.sh
#. install_controller_base.sh
. install_keystone.sh
. install_glance.sh
. install_compute_controller.sh

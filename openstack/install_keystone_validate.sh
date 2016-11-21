#!/bin/bash
#
# CentOS 7 
# OpenStack = mitaka
# node = controller
#
#
cd $(dirname $0)
. ./openstack_config.sh
#----------------------------[ 验证keystone ]----------------------------------------
vim /etc/keystone/keystone-paste.ini
# 撤销临时环境变量``OS_AUTH_URL``和``OS_PASSWORD``
unset OS_AUTH_URL OS_PASSWORD
# 作为 admin 用户，请求认证令牌：
expect<<END
openstack --os-auth-url http://${CONTROLLER_HOSTNAME}:35357/v3 \
  --os-project-domain-name default --os-user-domain-name default \
  --os-project-name admin --os-username admin token issue
expect {
"Password:" {send "${ADMIN_PASS}\n"}
}
interact
END
# 作为``demo`` 用户，请求认证令牌：
expect<<END
spawn openstack --os-auth-url http://${CONTROLLER_HOSTNAME}:5000/v3 \
  --os-project-domain-name default --os-user-domain-name default \
  --os-project-name demo --os-username demo token issue
expect {
"Password:" {send "${DEMO_PASS}\n"}
}
interact
END
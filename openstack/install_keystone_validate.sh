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
keystone-paste=/etc/keystone/keystone-paste.ini
#vim /etc/keystone/keystone-paste.ini
cp /etc/keystone/keystone-paste.ini /etc/keystone/keystone-paste.ini_bak
openstack-config --set ${keystone-paste} pipeline:public_api pipeline "cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id build_auth_context token_auth json_body ec2_extension public_service"
openstack-config --set ${keystone-paste} pipeline:admin_api pipeline "cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id build_auth_context token_auth json_body ec2_extension s3_extension admin_service"
openstack-config --set ${keystone-paste} pipeline:api_v3 pipeline "cors sizelimit http_proxy_to_wsgi osprofiler url_normalize request_id build_auth_context token_auth json_body ec2_extension_v3 s3_extension service_v3"

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

#!/usr/bin/env bash

sudo su -

cat <<EOF > /etc/resolv.conf
search ${DOMAIN_NAME}
nameserver ${IP_PREFIX}.100
EOF

# TODO ... check after a full build
echo "HWADDR=\"$(ifconfig eth0  | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "HWADDR=\"$(ifconfig eth1  | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')\"" >> /etc/sysconfig/network-scripts/ifcfg-eth1
systemctl restart network

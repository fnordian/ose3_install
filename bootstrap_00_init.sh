#!/usr/bin/env bash

sudo su -

# Create some aliases
cat <<EOF >> ~/.bashrc
source /home/vagrant/sync/ENV
source /home/vagrant/sync/docker_images.sh

alias vb='vi ~/.bashrc'
alias sb='source ~/.bashrc'
alias ls="ls "
alias ll='ls -all'
alias la='ll -all'
alias l='ll'
alias ose_ps='ps -elf | grep openshift'
alias node_stop='systemctl stop openshift-node'
alias node_start='systemctl start openshift-node'
alias node_restart='systemctl restart openshift-node'
alias node_status='systemctl status openshift-node'
EOF

source ~/.bashrc

# Change the root password of the instance.
echo "root:${ROOT_PASSWORD}" | chpasswd

# Register host with RHN
subscription-manager register --username="${RHN_USERNAME}" --password="${RHN_PASSWORD}"
# Attach to the correct pool
# Note: a valid pool can be found executing "subscription-manager list --available"
# Note: to remove an attached subscrption, you should execute "subscription-manager unsubscribe --all"
subscription-manager attach --pool="${RHN_POOL}"

# Disable all Repositories
subscription-manager repos --disable="*"
# Enable the OpenShift Enterprise dependencies
subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-ose-3.0-rpms"

# Remove NetworkManager 
# CHECKME: this is recommended in the installation but causing problems to log remotely over ssh ... 
systemctl stop NetworkManager
chkconfig NetworkManager off
yum -y remove NetworkManager*

# Install deltarpm
yum -y install deltarpm;

# Install basic packages
yum -y install wget git net-tools bind-utils iptables-services bridge-utils python-virtualenv psmisc gcc httpd-tools
# Improve the cache
yum makecache fast;
# Update the base system
yum -y update;

# Configure ssh access
mkdir -p /root/.ssh
chmod 700 /root/.ssh
#cp /home/vagrant/sync/ssh/id_rsa.pub /root/.ssh/authorized_keys
cat <<EOF >> ~/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmmlUTyUVTtm8enVxfR8sJvXAhEMJ4wg1TN3owefelcfNjd+327j1jJ4NbjzSGRwfV2i/TLKkA747+SXnebeJbQ5L8p1Fi9SHMuRm6H/1q5J6Y1mhjm0G+fVKOGy0gM5ax8NQfUQHTX08tv8Khfdzm7p9Fq/qMG/EANmm9Zh2+ExUVDakCDLl5IppHoxieiiE61f+159V9enjnKoaagBgRW+/tITwj6irbXcM545+j0x05kfAeLbmyDh2zLpaPRSAouvx58UE+toZANykGNS4PE1IbMmDPylfAC7e9evVtwH58g/rM5K1G4mvpGPajAEiBLtBPwxRYa/iwiQdumvoT root@master.giraffe-cloud.com
EOF
chown root:root /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# Update the host file 
cat <<EOF > /etc/hosts
${IP_PREFIX}.100   master.${DOMAIN_NAME} master
${IP_PREFIX}.101   node01.${DOMAIN_NAME} node01
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

# Update the grub config for a faster startup
cat <<EOF >> /etc/default/grub
GRUB_HIDDEN_TIMEOUT=0
GRUB_HIDDEN_TIMEOUT_QUIET=true
EOF
sed -i.bak "s:GRUB_TIMEOUT=5:GRUB_TIMEOUT=1:" /etc/default/grub
sed -i.bak "s:GRUB_DEFAULT=saved:GRUB_DEFAULT=0:" /etc/default/grub




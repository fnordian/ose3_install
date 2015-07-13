#!/usr/bin/env bash

############ Install ...
ansible-playbook ~/openshift-ansible/playbooks/byo/config.yml

### Check if all nodes are running
# (1) oc get nodes
### ... if a node is missing ...
# (2) oadm manage-node "master.${DOMAIN_NAME}" --schedulable=true

#oadm manage-node ip-172-31-18-252.eu-central-1.compute.internal --schedulable=true
oc label node master.${DOMAIN_NAME} region=infra zone=default
oc label node node01.${DOMAIN_NAME} region=primary zone=east

# Create the directory for the registry
mkdir -p /mnt/registry
oadm registry --credentials=/etc/openshift/master/openshift-registry.kubeconfig --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' --selector="region=infra" --mount-host=/mnt/registry

## Deploy the OpenShift Internal Docker Registry
#oadm registry --config=/etc/openshift/master/admin.kubeconfig --credentials=/etc/openshift/master/openshift-registry.kubeconfig --mount-host=/opt/ose_registry_images
## Create The Service Account for the Registry
echo '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"registry"}}' | oc create -f -

# Router
CA=/etc/openshift/master
oadm create-server-cert --signer-cert=${CA}/ca.crt --signer-key=${CA}/ca.key --signer-serial=${CA}/ca.serial.txt --hostnames="*.${DOMAIN_NAME}" --cert=${DOMAIN_NAME}.crt --key=${DOMAIN_NAME}.key

cat ${DOMAIN_NAME}.crt ${DOMAIN_NAME}.key ${CA}/ca.crt > ${DOMAIN_NAME}.router.pem

oadm router --default-cert=${DOMAIN_NAME}.router.pem --credentials=/etc/openshift/master/openshift-router.kubeconfig --selector='region=infra' --images='registry.access.redhat.com/openshift3/ose-${component}:${version}'

# password for stats user admin has been set to sGildgBwJH
#http://admin:$YOURPASSWORDHERE@ose3-master.example.com:1936 

iptables -I OS_FIREWALL_ALLOW -p tcp -m tcp --dport 1936 -j ACCEPT

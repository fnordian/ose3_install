# Vagrant OSE 3 setup

This project setups OSE 3 on one or several running virtualbox VMs orchestrated by Vagrant.

Currently it is still in development and not final.

## Install

1) Preparations
    - Install vagrant (1.7.3) and virtualbox (5.0)
    - git clone https://github.com/Maarc/ose3_install
	- Rename ENV.sample to ENV and replace the values by your own
		$ mv ENV.sample ENV
		$ vi ENV
	- Download the RHEL 7.1 virtualbox image (https://access.redhat.com/downloads/content/290/ver=3.0.0.0/rhel---7/3.0.0.0/x86_64/product-downloads)
	- Install the dowloaded image
		$ vagrant box add --name rhel-7 ~/install/distributions/RHEL/rhel-server-virtualbox-7.1-3.x86_64.box
	- (optional) Install the vagrant vbguest plugin
		$ vagrant plugin install vagrant-vbguest

3) Creation / setup of the VMs

	$ ./vagrant_ose_setup.sh

4) Finish the installation
	
	$ source ./ENV
	$ vagrant ssh master
	$ sudo su -
	$ /home/vagrant/sync/postinstall_master.sh

4) Check the installation
	- oc get nodes
	- oc get pods
	- Open https://master.${DOMAIN_NAME}:8443/ and log with the chosen HTTP_USER / HTTP_PASSWORD


## Q(&A)


### Q (open)

- How can I do an offline installation? (pre-load images, rpms, satellite 6, ...)
Background: Need to install it in an environment without Internet connectivity.

- How can I restrict the images allowed in my repository?

- How to destroy and re-create a router / registry?
Background: after a router / registry has been created, it is not possible anymore to delete it and create a new one:
	Error: deploymentConfig "docker-registry" already exists
services/docker-registry

- What does exit codes (ExitCode:255) mean for images?

	[root@master opt]# oc get pods
	NAME                       READY     REASON    RESTARTS   AGE
	docker-registry-1-deploy   0/1       Pending   0          31s
	[root@master opt]# oc get pods
	NAME                       READY     REASON         RESTARTS   AGE
	docker-registry-1-deploy   0/1       ExitCode:255   0          10m


### Q&A (answered)

- What are the differences between a docker registry and an openshift registry? Can I use the same storage for both?

	-> docker storage => stores locally the docker images
	-> openshift registry => instance 

- How do I see the status of the download of the docker images? How do I see why a node is "pending"?

	> oc get pods
	> oc describe pod docker-registry-1-deploy
	> oc stop pod docker-registry-1-deploy
	...
	> oc stop svc docker-registry
	> oc delete svc docker-registry
	...
	> oadm registry --config=/etc/openshift/master/admin.kubeconfig --credentials=/etc/openshift/master/openshift-registry.kubeconfig


- How to use the persistent storage properly?

The registry stores Docker images and metadata. If you simply deploy a pod with the registry, it uses an ephemeral volume that is destroyed if the pod exits. Any images anyone has built or pushed into the registry would disappear. For production use, you should use persistent storage using PersistentVolume and PersistentVolumeClaim objects for storage for the registry. 

Cf. https://access.redhat.com/beta/documentation/en/openshift-enterprise-30-administrator-guide#persistent-storage-using-nfs

- How can I restart OSE?

	> systemctl stop openshift-master
	> systemctl start openshift-master
	> systemctl restart openshift-master

- Can I install the master witout a node on the same host?

NO! The master has to be a node too ...

- Can I use a shared disk for sharing the docker registries across my nodes?

NO!


## Todo

- Try dns server integrated in vagrant
- Write autocomplete script for oc and co ...
- Consider an ansible- based provisioning instead of shell in vagrant ...


## Notes

- Understanding the docker structure http://jackiechen.org/2015/04/20/understanding-docker-directory-structure/

	> rpm -ql docker

- Attaching shared storage only works with the guest additions ... and it makes it really difficult to automate it ... (restart required)

	> config.vm.synced_folder docker_backup_repository, "/opt/backup_repository"

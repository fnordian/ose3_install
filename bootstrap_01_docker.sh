
sudo su -

# Necessary for docker_restore_all_images / docker_backup_all_images
shopt -s expand_aliases
source ~/.bashrc

# Install docker
yum -y install docker

# Stop the docker service
systemctl stop docker;

# Enable insecure registry
sed -i.bak -e "s|^OPTIONS='--selinux-enabled'|OPTIONS='--selinux-enabled --insecure-registry 0.0.0.0/0'|" /etc/sysconfig/docker


#############################################################################
########## Storage
#############################################################################

# If it is not a block device ...
if [ ! -b /dev/sdb1 ] ; then
	# Format the partition table of the mounted volume 
	(echo d; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdb

	# Create a physical volume out of the partition
	pvcreate /dev/sdb1

	# Create a volume group
	vgcreate docker-storage /dev/sdb1
fi

# Configure the storage
cat <<EOF > /etc/sysconfig/docker-storage-setup
VG=docker-storage
SETUP_LVM_THIN_POOL=yes
EOF

# Setup the docker storage
docker-storage-setup

# Remove any docker leftovers
rm -rf /var/lib/docker/*

# Start the docker service
systemctl start docker
# Note: the docker container could be troubleshooted using "docker info" and "docker -d -D"


#############################################################################
#### Restore images from disk-backup (if existing)
#############################################################################

if [ -b /dev/sdc ] ; then

	if [ ! -b /dev/sdc1 ] ; then
		# Format the partition table of the mounted volume 
		(echo d; echo n; echo p; echo 1; echo ; echo; echo w) | fdisk /dev/sdc

		## Create a physical volume out of the partition
		#pvcreate /dev/sdc1
		## Create a volume group
		#vgcreate docker-backup /dev/sdc1
		mkfs.ext4 /dev/sdc1
	fi

	mkdir -p $DOCKER_BACKUP_DIR
	mount /dev/sdc1 $DOCKER_BACKUP_DIR
	#echo "UUID=$(blkid /dev/sdc1 -o value | head -1)       ext4    defaults        1 1" >> /etc/fstab

	docker_restore_all_images
fi

#############################################################################
#### Pre-load further images
#############################################################################

if [ ${PRE_DOWNLOAD_DOCKER_IMAGES} ] ; then

	# cf. https://access.redhat.com/search/#/container-images
	# Preloads many docker images. This could take a very long time and require a lot of space. 
	docker pull openshift3/ose-haproxy-router
	docker pull openshift3/ose-deployer
	docker pull openshift3/ose-sti-builder
	docker pull openshift3/ose-sti-image-builder
	docker pull openshift3/ose-docker-builder
	docker pull openshift3/ose-pod
	docker pull openshift3/ose-docker-registry
	docker pull openshift3/ose-keepalived-ipfailover
	#docker pull openshift3/sti-basicauthurl
	docker pull jboss-eap-6/eap-openshift
	#docker pull openshift3/ruby-20-rhel7
	#docker pull openshift3/mysql-55-rhel7
	#docker pull openshift3/php-55-rhel7
	#docker pull openshift/hello-openshift

	docker_backup_all_images
fi
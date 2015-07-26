#!/usr/bin/env bash

# This is the main shell script to execute in order to create and configure your virtualbox machines.

source ./ENV

# Destroys all existing vagrant managed VirtualBox VMs (master and node0x only)
vagrant destroy -f
# When this variable is set, a disk is mounted and will be use to retr
export PRELOAD=true
# FIXME: iterate on ${NODES}
# Setup node0x
vagrant up node01
vagrant halt node01
# Setup master
vagrant up master
vagrant halt master
export PRELOAD=false
# Start all created VirtualBox VMs
vagrant up

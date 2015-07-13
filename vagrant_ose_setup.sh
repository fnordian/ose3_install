#!/usr/bin/env bash

source ./ENV

vagrant destroy -f
# When this variable is set, a disk is mounted and will be use to retr
export PRELOAD=true
vagrant up node01
vagrant halt node01
vagrant up master
vagrant halt master
export PRELOAD=false
vagrant up

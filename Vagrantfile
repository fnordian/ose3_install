disk_directory = ENV['HOST_VIRTUALBOX_DISK_DIR']
disk_prefix = disk_directory + '/large_disk_' 
domain_name = ENV['DOMAIN_NAME']
preload = ENV['PRELOAD'] || 'false'
ip_prefix = ENV['IP_PREFIX'] + '.'
nodes = ENV['NODES'].to_i

ip = ''
name = ''

Vagrant.configure(2) do |config|

  config.vm.box = "rhel-7"
  config.vm.provision :shell, path: "bootstrap_00_init.sh"
  config.vm.provision :shell, path: "bootstrap_01_docker.sh"

  # set auto_update to false, if you do NOT want to check the correct additions version when booting this machine
  config.vbguest.auto_update = false

  # do NOT download the iso file from a webserver
  config.vbguest.no_remote = true

  # Build nodes
  (1..nodes).each do |i|
    config.vm.define "node0#{i}" do |node|
        name = "node0#{i}"
        ip = ip_prefix+"10#{i}"
        node.vm.hostname = name + '.' + domain_name
        node.vm.network "public_network", bridge: 'en0: Wi-Fi (AirPort)', ip: ip
    end
  end

  # Build master
  config.vm.define "master", primary: true do |node|
    name = 'master'
    ip = ip_prefix+'100'
    node.vm.hostname = name + '.' + domain_name
    node.vm.provision :shell, path: "bootstrap_02_master.sh"
    node.vm.network "public_network", bridge: 'en0: Wi-Fi (AirPort)', ip: ip
  end

  config.vm.provision :shell, path: "bootstrap_03_end.sh"
 
  config.vm.provider "virtualbox" do |vb|

    # Once the NetworkManager has been disabled we need to ssh over the public IP
    if preload != 'true'
       config.ssh.port = 22
       config.ssh.host = ip
       config.ssh.password = 'vagrant'
       #p 'ssh on ' + ip + ':22'
    end

    vb.name = 'ose3_'+name
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    vb.memory = 4096

    # Creates a first disk for the docker storage
    disk = disk_prefix + name + '.vdi'
    unless File.exist?(disk)
        vb.customize ['createhd', '--filename', disk, '--variant', 'Fixed', '--size', 8 * 1024]
    end
    vb.customize ['storageattach', :id,  '--storagectl', 'IDE Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk]

    # Creates a shared second disk for backuping the docker images
    if preload == 'true'
      disk2 = disk_prefix + 'docker_backup.vdi'
      unless File.exist?(disk2)
          vb.customize ['createhd', '--filename', disk2, '--variant', 'Fixed', '--size', 10 * 1024]
      end
      vb.customize ['storageattach', :id,  '--storagectl', 'IDE Controller', '--port', 1, '--device', 1, '--type', 'hdd', '--medium', disk2]
    else
      vb.customize ['storageattach', :id,  '--storagectl', 'IDE Controller', '--port', 1, '--device', 1, '--medium', 'emptydrive']

    end
  end
end

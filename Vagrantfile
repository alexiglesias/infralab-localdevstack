# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile for infralab-localdevstack — a 5-VM lab running the VProfile
# Java application stack (Nginx → Tomcat → MariaDB + Memcached + RabbitMQ).
#
# Designed for Apple Silicon (M1/M2/M3/M4) using VMware Fusion.
# All backend VMs use bandit145/centos_stream9_arm (ARM64 CentOS Stream 9).
# The web VM uses spox/ubuntu-arm (ARM64 Ubuntu) as nginx is simpler there.
#
# Use --no-parallel to bring VMs up in dependency order:
#   vagrant up --no-parallel

VMS = {
  "db01"  => { ip: "192.168.56.25", memory: 1024, script: "mysql.sh",     box: "bandit145/centos_stream9_arm" },
  "mc01"  => { ip: "192.168.56.24", memory: 1024, script: "memcache.sh",  box: "bandit145/centos_stream9_arm" },
  "rmq01" => { ip: "192.168.56.23", memory: 1024, script: "rabbitmq.sh",  box: "bandit145/centos_stream9_arm" },
  "app01" => { ip: "192.168.56.22", memory: 2048, script: "tomcat.sh",    box: "bandit145/centos_stream9_arm" },
  "web01" => { ip: "192.168.56.21", memory: 512,  script: "nginx.sh",     box: "spox/ubuntu-arm"              },
}

Vagrant.configure("2") do |config|
  # vagrant-hostmanager plugin maintains /etc/hosts on guests and the host
  # so the VMs can resolve each other by hostname.
  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled           = true
    config.hostmanager.manage_host       = true
    config.hostmanager.manage_guest      = true
    config.hostmanager.ignore_private_ip = false
  end

  config.vm.boot_timeout = 900

  VMS.each do |name, cfg|
    config.vm.define name do |node|
      node.vm.box      = cfg[:box]
      node.vm.hostname = name
      node.vm.network "private_network", ip: cfg[:ip]
      node.vm.provision "shell", path: "provisioning/#{cfg[:script]}"

      node.vm.provider "vmware_desktop" do |vmware|
        vmware.gui                = false
        vmware.allowlist_verified = true
        vmware.memory             = cfg[:memory]
        vmware.cpus               = 1
      end
    end
  end
end

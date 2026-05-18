# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile for infralab-localdevstack — a 5-VM lab running the VProfile
# Java application stack (Nginx → Tomcat → MariaDB + Memcached + RabbitMQ).
#
# Supports two providers:
#   - VirtualBox       (free, Linux/Windows/Intel Mac)
#   - VMware Fusion    (free for personal use since 2024, Apple Silicon)
#
# Auto-detects whichever hypervisor is installed. Force one explicitly with:
#   vagrant up --provider=virtualbox
#   vagrant up --provider=vmware_desktop
#
# All five VMs are provisioned in a specific order (db → mc → rmq → app → web)
# because the application VM expects backend services to exist at boot time.
# Use --no-parallel to honor the order:
#   vagrant up --no-parallel

# CentOS Stream 9 boxes per provider
VIRTUALBOX_BOX = "eurolinux-vagrant/centos-stream-9"
VMWARE_ARM_BOX = "bento/centos-stream-9"

# Network: all VMs on 192.168.56.0/24 private network
# Hostnames resolved via the vagrant-hostmanager plugin
VMS = {
  "db01"  => { ip: "192.168.56.15", memory: 1024, script: "mysql.sh"    },
  "mc01"  => { ip: "192.168.56.14", memory: 512,  script: "memcache.sh" },
  "rmq01" => { ip: "192.168.56.16", memory: 1024, script: "rabbitmq.sh" },
  "app01" => { ip: "192.168.56.12", memory: 2048, script: "tomcat.sh"   },
  "web01" => { ip: "192.168.56.11", memory: 512,  script: "nginx.sh"    },
}

Vagrant.configure("2") do |config|
  # vagrant-hostmanager plugin maintains /etc/hosts on guests and the host so
  # the VMs can resolve each other (and you, on the host, can resolve them)
  # by hostname instead of by IP.
  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled           = true
    config.hostmanager.manage_host       = true
    config.hostmanager.manage_guest      = true
    config.hostmanager.ignore_private_ip = false
  end

  VMS.each do |name, cfg|
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", ip: cfg[:ip]
      node.vm.provision "shell", path: "provisioning/#{cfg[:script]}"

      node.vm.provider "virtualbox" do |vb, override|
        override.vm.box = VIRTUALBOX_BOX
        vb.name = "infralab-#{name}"
        vb.memory = cfg[:memory]
        vb.cpus = 1
        vb.gui = false
        vb.customize ["modifyvm", :id, "--audio", "none"]
      end

      node.vm.provider "vmware_desktop" do |vmware, override|
        override.vm.box = VMWARE_ARM_BOX
        vmware.gui = false
        vmware.allowlist_verified = true
        vmware.memory = cfg[:memory]
        vmware.cpus = 1
      end
    end
  end
end

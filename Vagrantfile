Vagrant.configure("2") do |config|

  config.vm.box         = "spox/ubuntu-arm"
  config.vm.box_version = "1.0.0"

  config.vm.provider "vmware_desktop" do |vmware|
    vmware.gui                = false
    vmware.allowlist_verified = true
    vmware.ssh_info_public    = true
    vmware.memory             = "600"
    vmware.cpus               = 1
  end

# Nginx - Reverse Proxy / Frontend

  config.vm.define "web01" do |web01|
    web01.vm.hostname = "web01"
    web01.vm.network "private_network", ip: "192.168.56.11"
    web01.vm.provision "shell", path: "nginx.sh"
  end

# Tomcat - App Server

  config.vm.define "app01" do |app01|
    app01.vm.hostname = "app01"
    app01.vm.network "private_network", ip: "192.168.56.12"
    app01.vm.provider "vmware_desktop" do |vmware|
      vmware.memory = "800"
    end
    app01.vm.provision "shell", path: "tomcat.sh"
  end

# MySQL - DataBase

  config.vm.define "db01" do |db01|
    db01.vm.hostname = "db01"
    db01.vm.network "private_network", ip: "192.168.56.15"
    db01.vm.provision "shell", path: "mysql.sh"
  end

# Memcache - Cache

  config.vm.define "mc01" do |mc01|
    mc01.vm.hostname = "mc01"
    mc01.vm.network "private_network", ip: "192.168.56.14"
    mc01.vm.provision "shell", path: "memcache.sh"
  end

# Rabbit MQ - Message Broker

  config.vm.define "rmq01" do |rmq01|
    rmq01.vm.hostname = "rmq01"
    rmq01.vm.network "private_network", ip: "192.168.56.16"
    rmq01.vm.provision "shell", path: "rabbitmq.sh"
  end

end

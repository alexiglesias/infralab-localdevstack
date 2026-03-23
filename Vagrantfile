Vagrant.configure("2") do |config|
  config.hostmanager.enabled = true 
  config.hostmanager.manage_host = true
  
### DB vm  ####
  config.vm.define "db01" do |db01|
    db01.vm.box = "bandit145/centos_stream9_arm"
    db01.vm.hostname = "db01"
    db01.vm.network "private_network", ip: "192.168.56.15"
    db01.vm.provider "vmware_desktop" do |vmware|
      vmware.gui = true
      vmware.allowlist_verified = true
    end
    db01.vm.provision "shell", path: "mysql.sh"
  end
  
### Memcache vm  #### 
  config.vm.define "mc01" do |mc01|
    mc01.vm.box = "bandit145/centos_stream9_arm"
    mc01.vm.hostname = "mc01"
    mc01.vm.network "private_network", ip: "192.168.56.14"
    mc01.vm.provider "vmware_desktop" do |vmware|
      vmware.gui = true
      vmware.allowlist_verified = true
    end
    mc01.vm.provision "shell", path: "memcache.sh"
  end
  
### RabbitMQ vm  ####
  config.vm.define "rmq01" do |rmq01|
    rmq01.vm.box = "bandit145/centos_stream9_arm"
    rmq01.vm.hostname = "rmq01"
    rmq01.vm.network "private_network", ip: "192.168.56.16"
    rmq01.vm.provider "vmware_desktop" do |vmware|
      vmware.gui = true
      vmware.allowlist_verified = true
    end
    rmq01.vm.provision "shell", path: "rabbitmq.sh"
  end
  
### tomcat vm ###
  config.vm.define "app01" do |app01|
    app01.vm.box = "bandit145/centos_stream9_arm"
    app01.vm.hostname = "app01"
    app01.vm.network "private_network", ip: "192.168.56.12"
    app01.vm.provider "vmware_desktop" do |vb|
     vb.memory = "1024"
     vb.gui = true
     vb.allowlist_verified = true
    end
    app01.vm.provision "shell", path: "tomcat.sh"
  end
   
  
### Nginx VM ###
  config.vm.define "web01" do |web01|
    web01.vm.box = "spox/ubuntu-arm"
    web01.vm.hostname = "web01"
    web01.vm.network "private_network", ip: "192.168.56.11"
    web01.vm.provider "vmware_desktop" do |vmware|
      vmware.gui = true
      vmware.allowlist_verified = true
    end
    web01.vm.provision "shell", path: "nginx.sh"
  end
  
end

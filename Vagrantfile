Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.provision :shell, path: "bootstrap.sh"
  config.vm.synced_folder "~/regal-dev", "/opt/regal/src",type: "virtualbox"
  config.vm.synced_folder ".", "/vagrant",type: "virtualbox"
  config.vm.network "forwarded_port", guest: 80, host: 9080
  config.vm.network "forwarded_port", guest: 9100, host: 9100
  config.vm.network "forwarded_port", guest: 9001, host: 9001
  config.vm.network "forwarded_port", guest: 9002, host: 9002
  config.vm.network "forwarded_port", guest: 9003, host: 9003
  config.vm.network "forwarded_port", guest: 9004, host: 9004
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.provider "virtualbox" do |v|
     v.memory = 2048
     v.cpus = 2
     v.name = "regal"
  end
Vagrant.configure("2") do |config|
  config.vm.network "public_network", type: "dhcp"
end

end



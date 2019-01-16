Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.provision :shell, path: "bootstrap.sh"
  config.vm.synced_folder "/tmp/regal-dev", "/opt/regal/src",type: "virtualbox"
end



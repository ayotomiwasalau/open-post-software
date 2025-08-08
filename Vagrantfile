# set up the default terminal
ENV["TERM"]="linux"

# set minimum version for Vagrant
Vagrant.require_version ">= 2.2.10"
Vagrant.configure("2") do |config|
  config.vm.provision "shell",
    inline: "sudo su - && zypper update && zypper install -y apparmor-parser"
  
  # Set the image for the vagrant box
  config.vm.box = "opensuse/Leap-15.6.x86_64"
  # Set the image version
  # config.vm.box_version = "15.3.0"
  config.vm.synced_folder "./", "/vagrant"

  # Forward the ports from the guest VM to the local host machine
  # Forward more ports, as needed
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.network "forwarded_port", guest: 3111, host: 3111
  config.vm.network "forwarded_port", guest: 6112, host: 6112
  config.vm.network "forwarded_port", guest: 30008, host: 30008
  config.vm.network "forwarded_port", guest: 31852, host: 31852
  config.vm.network "forwarded_port", guest: 3001, host: 3001
  config.vm.network "forwarded_port", guest: 9090, host: 9090
  config.vm.network "forwarded_port", guest: 16685, host: 16685
  config.vm.network "forwarded_port", guest: 16686, host: 16686
  config.vm.network "forwarded_port", guest: 4317, host: 4317
  config.vm.network "forwarded_port", guest: 9376, host: 9376

  # Set the static IP for the vagrant box
  config.vm.network "private_network", ip: "192.168.56.4"
  
  # Configure the parameters for VirtualBox provider
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "8192" 
    vb.cpus = 4
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end
end

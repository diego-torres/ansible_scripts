# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

$vmMemory = ENV['FUSE_VM_MEMORY'] || 3000
$mavenVersion = ENV['MAVEN_VERSION'] || "3.2.3"
$javaPackage = ENV['JAVA_PKG'] || "java-1.8.0-openjdk-devel.x86_64"
$javaVersion = ENV['JAVA_VERSION'] || "java-1.8.0"
$hostname = "centos7"
$pluginToCheck = "landrush"

unless Vagrant.has_plugin?($pluginToCheck)
  raise 'Please type this command then try again: vagrant plugin install ' + $pluginToCheck
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Top level domain
  $tld = "vagrant.f8"
  $fullName = $hostname + "." + $tld

  # Landrush DNS Setup
  config.landrush.enabled = true
  config.landrush.tld = $tld
  config.landrush.guest_redirect_dns = false
  config.landrush.host_ip_address = '172.28.128.4'

  # Add the hostname to the DNS domain
  config.vm.hostname = $fullName

  config.vm.box = "centos/7"

  config.vm.network "private_network", ip: "172.28.128.4"

  # Use NFS for shared folders for better performance
  config.vm.synced_folder "tmp/", "/home/vagrant/tmp", nfs: true

  # set auto_update to false, if you do NOT want to check the correct
  # additions version when booting this machine
  config.vbguest.auto_update = false

  config.vm.provider "virtualbox" do |v|
    v.memory = $vmMemory
    v.cpus = 2
    # Virtual VM Name
    v.name = $hostname
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.provision "shell" do |s|
    s.path       = "bootstrap-light.sh"
    s.keep_color = true
    s.args       = [$vmMemory,$mavenVersion,$javaPackage,$javaVersion]
  end

  # Install Docker Daemon & Client
  config.vm.provision "shell", path: "docker-install.sh"

end

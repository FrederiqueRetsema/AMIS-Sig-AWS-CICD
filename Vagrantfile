# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  # alternatives to this Ubuntu 19.10 box are "v0rtex/xenial64" with the 16.04 LTS and ubuntu/trusty64 with 14.04 LTS
  config.vm.box = "bento/ubuntu-18.04" 
  # access a port on your host machine (via localhost) and have all data forwarded to a port on the guest machine.
  # config.vm.network "forwarded_port", guest: 9092, host: 9192
  # config.vm.network "forwarded_port", guest: 4040, host: 5050
  # config.vm.network "forwarded_port", guest: 8080, host: 8180
  # Create a private network, which allows host-only access to the machine
  # using a specific IP - I have arbitrarily decided on 192.168.188.142. Feel free to change this
  config.vm.network "private_network", ip: "192.168.188.142"

  # define a larger than default (40GB) disksize
  # note: this requires the Vagrant plugin vagrant-disksize (see https://github.com/sprotheroe/vagrant-disksize) using "vagrant plugin install vagrant-disksize"
  # config.disksize.size = '50GB'
  
  config.vm.provider "virtualbox" do |vb|
    vb.name = 'ubuntu19-sig-cicd'
    vb.memory = 4096
    vb.cpus = 1
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # set up git and python3 in the new VM:
  config.vm.provision "shell",
      inline: "apt update; apt upgrade -y; apt install python3 git unzip python3-pip awscli -y; curl https://releases.hashicorp.com/terraform/0.12.23/terraform_0.12.23_linux_amd64.zip --output terraform_0.12.23_linux_amd64.zip;pip3 install boto3"
	  
end
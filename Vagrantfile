#!/usr/bin/env ruby

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'utm'

Vagrant.configure("2") do |config|
  config.vm.box = "utm/ubuntu-24.04"
  config.ssh.port = 22
  config.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh", disabled: true

  config.vm.define "management" do |management|
    management.vm.provision "shell", inline: "echo Hello management"
    management.vm.hostname = "management"
    management.vm.synced_folder ".", "/vagrant", disabled: true
    management.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/management.yml"
    end
    management.ssh.host = "192.168.64.2"
    management.ssh.port = 22
    management.vm.provider "utm" do |utm|
      utm.cpus = 4
      utm.memory = 4096
      utm.directory_share_mode = "none"
      utm.check_guest_additions = false
    end
  end

  config.vm.define "hypervisor" do |hypervisor|
    hypervisor.vm.hostname = "hypervisor"
    hypervisor.vm.synced_folder ".", "/vagrant", disabled: true
    hypervisor.ssh.host = "192.168.64.3"
    hypervisor.ssh.port = 22
    hypervisor.vm.provider "utm" do |utm|
      utm.cpus = 4
      utm.memory = 4096
      utm.directory_share_mode = "none"
      utm.check_guest_additions = false
    end
  end
end

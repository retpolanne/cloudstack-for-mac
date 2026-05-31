#!/usr/bin/env ruby

Vagrant.configure("2") do |config|
  config.vm.define "management" do |management|
    management.vm.provider "tart" do |tart|
      tart.image = "ghcr.io/cirruslabs/ubuntu:24.04"
      tart.name = "management"
      tart.disk = 25
      tart.cpus = 4
      tart.memory = 8192
    end
    management.vm.provision "shell", inline: "echo Hello management"
    management.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/management.yml"
    end
  end

  config.vm.define "hypervisor" do |hypervisor|
    hypervisor.vm.provider "tart" do |tart|
      tart.image = "ghcr.io/cirruslabs/ubuntu:24.04"
      tart.name = "hypervisor"
      tart.extra_run_args = ["--nested"]
      tart.disk = 25
      tart.cpus = 4
      tart.memory = 8192
    end
    hypervisor.vm.provision "shell", inline: "ls /dev/kvm"
  end

  # Local use only!
  config.ssh.username = "admin"
  config.ssh.password = "admin"
end

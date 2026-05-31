#!/usr/bin/env ruby

Vagrant.configure("2") do |config|
  config.vm.define "management" do |management|
    management.vm.provider "tart" do |tart|
      tart.image = "ghcr.io/cirruslabs/ubuntu:24.04"
      tart.name = "management"
      tart.disk = 25
      tart.cpus = 4
      tart.memory = 8192
      tart.extra_run_args = ["--net-bridged", "Wi-Fi"]
      tart.ip_resolver = "arp"
    end
    management.vm.provision "shell", inline: "sudo hostnamectl set-hostname management"
    management.vm.provision "shell", inline: "echo Hello management"
    management.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/management.yml"
    end
  end

  config.vm.define "hypervisor" do |hypervisor|
    hypervisor.vm.provider "tart" do |tart|
      tart.image = "ghcr.io/cirruslabs/ubuntu:24.04"
      tart.name = "hypervisor"
      tart.extra_run_args = ["--nested", "--net-bridged", "Wi-Fi"]
      tart.disk = 25
      tart.cpus = 4
      tart.memory = 8192
    end
    hypervisor.trigger.before :all do |trigger|
      trigger.ruby do |env, machine|
        ip = `tart ip --resolver=agent hypervisor 2>/dev/null`.strip
        machine.config.ssh.host = ip unless ip.empty?
      end
    end
    hypervisor.vm.provision "shell", inline: "sudo hostnamectl set-hostname hypervisor"
    hypervisor.vm.provision "shell", inline: "ls /dev/kvm"
  end

  # Local use only!
  config.ssh.username = "admin"
  config.ssh.password = "admin"
end

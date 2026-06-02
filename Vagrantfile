#!/usr/bin/env ruby

Vagrant.configure("2") do |config|
  config.vm.define "driver" do |driver|
    driver.vm.provider "tart" do |tart|
      tart.image = "ghcr.io/cirruslabs/ubuntu:24.04"
      tart.name = "driver"
      tart.disk = 25
      tart.cpus = 4
      tart.memory = 8192
      tart.extra_run_args = ["--net-bridged", "Wi-Fi"]
    end
    driver.trigger.before :all do |trigger|
      trigger.ruby do |env, machine|
        ip = `tart ip --resolver=agent driver 2>/dev/null`.strip
        machine.config.ssh.host = ip unless ip.empty?
      end
    end
    driver.vm.provision "shell", inline: "echo Hello driver"
    driver.vm.provision "shell", inline: "sudo hostnamectl set-hostname driver"
    driver.vm.provision "shell", inline: "sudo systemctl stop unattended-upgrades"
    driver.vm.provision "shell", inline: "sudo systemctl disable --now unattended-upgrades apt-daily.timer apt-daily-upgrade.timer"
    driver.vm.provision "shell", inline: "sudo apt update && sudo apt install -y avahi-daemon avahi-utils libnss-mdns"
    driver.vm.provision "ansible" do |ansible|
      ansible.playbook = ENV['ANSIBLE_PLAYBOOK_DRIVER']
      ansible.ask_vault_pass = ENV['ANSIBLE_ASK_VAULT_PASS'] || false
    end
  end

  config.vm.define "worker" do |worker|
    worker.vm.provider "tart" do |tart|
      tart.image = "ghcr.io/cirruslabs/ubuntu:24.04"
      tart.name = "worker"
      tart.extra_run_args = ["--nested", "--net-bridged", "Wi-Fi"]
      tart.disk = 25
      tart.cpus = 4
      tart.memory = 8192
    end
    worker.trigger.before :all do |trigger|
      trigger.ruby do |env, machine|
        ip = `tart ip --resolver=agent worker 2>/dev/null`.strip
        machine.config.ssh.host = ip unless ip.empty?
      end
    end
    worker.vm.provision "shell", inline: "echo Hello worker"
    worker.vm.provision "shell", inline: "sudo systemctl stop unattended-upgrades"
    worker.vm.provision "shell", inline: "sudo systemctl disable --now unattended-upgrades apt-daily.timer apt-daily-upgrade.timer"
    worker.vm.provision "shell", inline: "sudo apt update && sudo apt install -y avahi-daemon avahi-utils libnss-mdns"
    worker.vm.provision "shell", inline: "sudo hostnamectl set-hostname worker"
    worker.vm.provision "shell", inline: "ls /dev/kvm"
    worker.vm.provision "ansible" do |ansible|
      ansible.playbook = ENV['ANSIBLE_PLAYBOOK_WORKER']
      ansible.ask_vault_pass = ENV['ANSIBLE_ASK_VAULT_PASS'] || false
    end
  end

  # Local use only!
  config.ssh.username = "admin"
  config.ssh.password = "admin"
end

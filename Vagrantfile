# -*- mode: ruby -*-
# vi: set ft=ruby :

SSH_USER = "admin"
SSH_PASS = "admin"
SHARED_FOLDER = "/home/#{SSH_USER}/git/k0s_reigns"

Vagrant.configure("2") do |config|
  config.vm.provider "tart" do |tart|
    tart.image = "ghcr.io/cirruslabs/ubuntu:latest"             # required
    tart.name = "ubuntu"                                        # required
    tart.gui = true
    tart.cpus = 2
    tart.memory = 3072
    tart.disk = 32
    tart.display = "1366x768"
    tart.suspendable = false                                    # not supported when shared folders are enabled
    tart.vnc = false
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true        # disable default synced folder
  config.vm.synced_folder ".", SHARED_FOLDER, disabled: false

  config.ssh.username = SSH_USER
  config.ssh.password = SSH_PASS

  config.vm.provision "shell", path: "bootstrap.sh", env: {
    "SSH_USER" => SSH_USER,
    "SSH_PASS" => SSH_PASS,
    "SHARED_FOLDER" => SHARED_FOLDER,
  }
end

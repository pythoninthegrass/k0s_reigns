# -*- mode: ruby -*-
# vi: set ft=ruby :

COUNT_CONTROLLER = (ENV['COUNT_CONTROLLER'] || 1).to_i
COUNT_WORKER = (ENV['COUNT_WORKER'] || 1).to_i
CPU_CONTROLLER = (ENV['CPU_CONTROLLER'] || 2).to_i
CPU_WORKER = (ENV['CPU_WORKER'] || 2).to_i
RAM_CONTROLLER = (ENV['RAM_CONTROLLER'] || 2048).to_i
RAM_WORKER = (ENV['RAM_WORKER'] || 4096).to_i
DISK_SIZE = (ENV['DISK_SIZE'] || 32).to_i
SSH_USER = ENV['SSH_USER'] || "admin"
SSH_PASS = ENV['SSH_PASS'] || "admin"
SHARED_FOLDER = ENV['SHARED_FOLDER'] || "/home/#{SSH_USER}/git/k0s_reigns"

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

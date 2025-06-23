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
  (1..COUNT_CONTROLLER).each do |i|
    config.vm.define "control-plane-#{i}" do |controller|
      controller.vm.hostname = "control-plane-#{i}"

      controller.vm.provider "tart" do |tart|
        tart.image = "ghcr.io/cirruslabs/ubuntu:latest"
        tart.name = "control-plane-#{i}"
        tart.gui = false
        tart.cpus = CPU_CONTROLLER
        tart.memory = RAM_CONTROLLER
        tart.disk = DISK_SIZE
        tart.ip_resolver = "dhcp"
        tart.display = "1366x768"
        tart.suspendable = false
        tart.vnc = false
      end

      controller.vm.synced_folder ".", "/vagrant", disabled: true
      controller.vm.synced_folder ".", SHARED_FOLDER, disabled: false

      controller.ssh.username = SSH_USER
      controller.ssh.password = SSH_PASS

      # TODO: debug bootstrap.sh
      controller.vm.provision "shell", path: "bootstrap.sh", env: {
        "SSH_USER" => SSH_USER,
        "SSH_PASS" => SSH_PASS,
        "SHARED_FOLDER" => SHARED_FOLDER,
        "NODE_TYPE" => "controller",
        "NODE_INDEX" => i.to_s,
        "CONTROLLER_COUNT" => COUNT_CONTROLLER.to_s,
        "WORKER_COUNT" => COUNT_WORKER.to_s,
      }
    end
  end

  (1..COUNT_WORKER).each do |i|
    config.vm.define "worker-#{i}" do |worker|
      worker.vm.hostname = "worker-#{i}"

      worker.vm.provider "tart" do |tart|
        tart.image = "ghcr.io/cirruslabs/ubuntu:latest"
        tart.name = "worker-#{i}"
        tart.gui = false
        tart.cpus = CPU_WORKER
        tart.memory = RAM_WORKER
        tart.disk = DISK_SIZE
        tart.ip_resolver = "dhcp"
        tart.display = "1366x768"
        tart.suspendable = false
        tart.vnc = false
      end

      worker.vm.synced_folder ".", "/vagrant", disabled: true
      worker.vm.synced_folder ".", SHARED_FOLDER, disabled: false

      worker.ssh.username = SSH_USER
      worker.ssh.password = SSH_PASS

      # TODO: debug bootstrap.sh
      worker.vm.provision "shell", path: "bootstrap.sh", env: {
        "SSH_USER" => SSH_USER,
        "SSH_PASS" => SSH_PASS,
        "SHARED_FOLDER" => SHARED_FOLDER,
        "NODE_TYPE" => "worker",
        "NODE_INDEX" => i.to_s,
        "CONTROLLER_COUNT" => COUNT_CONTROLLER.to_s,
        "WORKER_COUNT" => COUNT_WORKER.to_s,
      }
    end
  end
end

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This repository provides a k0s (Kubernetes distribution) development environment using:

- **Vagrant** with **Tart provider** for macOS virtualization
- **Task runner** (Taskfile.yml) for command orchestration
- **k0s** single-node Kubernetes cluster setup
- **Ubuntu VM** with static IP configuration

The setup creates an Ubuntu VM that automatically installs k0s and generates a kubeconfig file for local development.

## Common Commands

**IMPORTANT**: Always use the taskfile commands instead of running vagrant or tart directly. The taskfile provides abstracted commands that handle proper configuration and environment setup.

### Task Management

- `task` or `task --list` - List all available tasks
- `task vagrant:up` - Start the Vagrant VM and install k0s
- `task vagrant:destroy` - Destroy the VM completely
- `task vagrant:ssh` - SSH into the VM
- `task vagrant:halt` - Stop the VM
- `task vagrant:suspend` - Suspend the VM
- `task vagrant:resume` - Resume suspended VM
- `task vagrant:reload` - Reload VM configuration

### Tart VM Management

- `task tart:list` - List all VMs and images
- `task tart:pull -- <image>` - Pull a VM image
- `task tart:run -- <vm-name>` - Run a VM directly
- `task tart:stop -- <vm-name>` - Stop a VM

### Setup Requirements

- `task vagrant:plugin` - Install vagrant-tart plugin (run once)

### Direct Command Usage (NOT RECOMMENDED)

The following commands should be avoided in favor of the taskfile equivalents:

- ❌ `vagrant up` → ✅ `task vagrant:up`
- ❌ `vagrant destroy` → ✅ `task vagrant:destroy`
- ❌ `tart list` → ✅ `task tart:list`
- ❌ `tart pull <image>` → ✅ `task tart:pull -- <image>`

### Ad Hoc Commands for Validation

When validating work or troubleshooting, you can run commands directly in the VM:

- `vagrant ssh -c "command"` - Run a single command in the VM
- `vagrant ssh -c "sudo k0s status"` - Check k0s status
- `vagrant ssh -c "sudo systemctl status k0scontroller"` - Check k0s service status
- `vagrant ssh -c "ls -la /var/lib/k0s/pki/"` - Check k0s PKI files
- `vagrant ssh -c "ls -la ~/git/k0s_reigns/"` - Check shared folder contents

## Configuration Files

- `Vagrantfile` - Standard Vagrant configuration (DHCP)
- `Vagrantfile.dev` - Development configuration with static IP (192.168.64.100)
- `01-netcfg.yaml.tpl` - Netplan template for static IP configuration
- `taskfile.yml` - Main task definitions
- `taskfiles/vagrant.yml` - Vagrant-specific tasks
- `taskfiles/tart.yml` - Tart-specific tasks

## Development Workflow

**Always use taskfile commands for consistency and proper environment setup:**

1. Install vagrant-tart plugin: `task vagrant:plugin`
2. Start development environment: `task vagrant:up`
3. Access Kubernetes cluster using generated `kubeconfig` file
4. SSH into VM for debugging: `task vagrant:ssh`
5. Clean up: `task vagrant:destroy`

**Note**: The taskfile abstracts the underlying vagrant and tart commands, ensuring proper configuration and environment variables are set.

## Testing Configuration Changes

When making changes to Vagrantfile or VM configuration:

- **Always test changes by running**: `task vagrant:destroy && task vagrant:up`
- This ensures a clean VM rebuild with the new configuration

## Key Details

- VM uses admin/admin credentials
- k0s runs as single-node controller
- Kubeconfig is automatically generated and configured
- Project directory is synced to `/home/admin/git/k0s_reigns` in VM
- Default VM uses DHCP; dev variant uses static IP 192.168.64.100

## Technology Stack Documentation

### Tart (https://github.com/cirruslabs/tart)

**Purpose**: Virtualization toolset for building, running, and managing macOS and Linux VMs on Apple Silicon

**Key Features**:

- Uses Apple's Virtualization.Framework for near-native performance
- Supports pushing/pulling VMs from OCI-compatible container registries
- Designed for CI and automation needs
- Includes Packer Plugin for VM automation

**Requirements**:

- Apple Silicon device
- macOS 13.0 (Ventura) or later

**Installation**: `brew install cirruslabs/cli/tart`
**Documentation**: https://tart.run

### k0s (https://docs.k0sproject.io)

**Purpose**: Zero friction Kubernetes distribution designed for simplicity and automation
**Key Features**:

- Single binary with no external dependencies
- Works on any Linux without additional packages
- Supports various deployment topologies (single-node, multi-node, HA)
- Built-in cluster lifecycle management
- Automatic certificate management

**Documentation**: https://docs.k0sproject.io

### Vagrant-Tart Plugin (https://github.com/letiemble/vagrant-tart)

**Purpose**: Vagrant plugin that adds Tart provider to Vagrant for Apple Silicon environments

**Features**:

- Integrates Vagrant workflow with Tart virtualization
- Supports provisioning and managing VMs on macOS
- Designed specifically for Apple Silicon platforms

**Installation**: Plugin is installed via `task vagrant:plugin` which runs `vagrant plugin install vagrant-tart`
**Documentation**: https://letiemble.github.io/vagrant-tart/

**Provider Configuration Options** (from Vagrantfile):

- `tart.image` - VM image to use (required)
- `tart.name` - VM name (required)
- `tart.gui` - Enable GUI (boolean)
- `tart.cpus` - Number of CPUs
- `tart.memory` - Memory in MB
- `tart.disk` - Disk size in GB
- `tart.display` - Display resolution
- `tart.suspendable` - Enable suspend (not supported with shared folders)
- `tart.vnc` - Enable VNC access
- `tart.ip_resolver` - IP resolution method (dhcp/arp)

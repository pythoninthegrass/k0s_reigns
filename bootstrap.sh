#!/usr/bin/env bash

# shellcheck disable=SC2086

set -e

# Global variables
SHARED_FOLDER="${SHARED_FOLDER:-/home/admin/git/k0s_reigns}"
SSH_USER="${SSH_USER:-admin}"
VM_IP="${VM_IP:-}"

# update system packages
update_system_packages() {
	echo "==> Updating system packages..."
	sudo apt-get update -y
}

# install required packages
install_required_packages() {
	echo "==> Installing required packages..."
	sudo apt-get install -y curl wget
}

# download and install k0s
install_k0s() {
	echo "==> Downloading and installing k0s..."
	curl --proto '=https' --tlsv1.2 -sSf https://get.k0s.sh | sudo sh
}

# install k0s as controller service
setup_k0s_controller() {
	echo "==> Installing k0s as controller service (single-node)..."
	sudo k0s install controller --single
}

# start k0s service
start_k0s_service() {
	echo "==> Starting k0s service..."
	sudo k0s start
}

# wait for k0s to be ready
wait_for_k0s_ready() {
	echo "==> Waiting for k0s to be ready..."
	timeout 60 bash -c 'until sudo k0s status 2>/dev/null | grep -q "Version:"; do sleep 2; done'
}

# detect VM IP address
detect_vm_ip() {
	echo "==> Detecting VM IP address..."
	if [ -z "$VM_IP" ]; then
		VM_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)
	fi
	echo "==> Final VM IP: $VM_IP"
}

# setup kubeconfig
setup_kubeconfig() {
	echo "==> Setting up kubeconfig..."
	if [ -f /var/lib/k0s/pki/admin.conf ]; then
		mkdir -p ${SHARED_FOLDER}
		sudo cp /var/lib/k0s/pki/admin.conf ${SHARED_FOLDER}/kubeconfig

		detect_vm_ip

		if [ -n "$VM_IP" ]; then
			sed -i "s/localhost/${VM_IP}/g" ${SHARED_FOLDER}/kubeconfig
			sed -i "s/127.0.0.1/${VM_IP}/g" ${SHARED_FOLDER}/kubeconfig
		else
			echo "ERROR: Could not detect VM IP address"
		fi
		sudo chown ${SSH_USER}:${SSH_USER} ${SHARED_FOLDER}/kubeconfig
		sudo chmod 600 ${SHARED_FOLDER}/kubeconfig
		echo "==> Kubeconfig created at ${SHARED_FOLDER}/kubeconfig"
	else
		echo "ERROR: admin.conf not found at /var/lib/k0s/pki/admin.conf"
		exit 1
	fi
}

# display completion message and cluster info
show_completion_info() {
	echo "==> k0s installation completed successfully!"
	echo "==> Cluster info:"
	sudo k0s kubectl cluster-info
}

main() {
	update_system_packages
	install_required_packages
	install_k0s
	setup_k0s_controller
	start_k0s_service
	wait_for_k0s_ready
	setup_kubeconfig
	show_completion_info
}

main "$@"

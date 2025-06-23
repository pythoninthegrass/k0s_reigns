#!/usr/bin/env bash

set -e

# Global variables from environment
SSH_USER="${SSH_USER:-admin}"
SHARED_FOLDER="${SHARED_FOLDER:-/home/${SSH_USER}/git/k0s_reigns}"
NODE_TYPE="${NODE_TYPE:-controller}"
NODE_INDEX="${NODE_INDEX:-1}"
CONTROLLER_COUNT="${CONTROLLER_COUNT:-1}"
WORKER_COUNT="${WORKER_COUNT:-1}"

# Config file path
K0S_CONFIG_FILE="/etc/k0s/k0s.yaml"
CONTROLLER_IP_FILE="${SHARED_FOLDER}/controller-ip"

echo "==> Starting k0s bootstrap for ${NODE_TYPE} node ${NODE_INDEX}"

# Update system packages
update_system_packages() {
	echo "==> Updating system packages..."
	sudo apt-get update -y >/dev/null 2>&1
}

# Install required packages
install_required_packages() {
	echo "==> Installing required packages..."
	sudo apt-get install -y curl wget >/dev/null 2>&1
}

# Download and install k0s
install_k0s() {
	echo "==> Downloading and installing k0s..."
	curl --proto '=https' --tlsv1.2 -sSf https://get.k0s.sh | sudo sh >/dev/null 2>&1
}

# Create k0s configuration
create_k0s_config() {
	echo "==> Creating k0s configuration..."
	sudo mkdir -p /etc/k0s
	sudo k0s config create | sudo tee /tmp/k0s.yaml > /dev/null
	sudo mv /tmp/k0s.yaml "${K0S_CONFIG_FILE}"
}

# Wait for k0s to be ready
wait_for_k0s_ready() {
	echo "==> Waiting for k0s to be ready..."
	timeout 60 bash -c 'until sudo k0s status 2>/dev/null | grep -q "Version:"; do sleep 2; done'
}

# Wait for first controller and get its IP
get_controller_ip() {
	echo "==> Waiting for controller IP file..."
	for i in {1..60}; do
		if [ -f "${CONTROLLER_IP_FILE}" ]; then
			CONTROLLER_IP=$(cat "${CONTROLLER_IP_FILE}")
			echo "==> Found controller IP: ${CONTROLLER_IP}"
			return 0
		fi
		echo "==> Waiting for controller IP... (${i}/60)"
		sleep 5
	done
	echo "ERROR: Controller IP not found"
	exit 1
}

# Wait for first controller to be ready (for non-first nodes)
wait_for_first_controller() {
	if [ "${NODE_TYPE}" != "controller" ] || [ "${NODE_INDEX}" != "1" ]; then
		get_controller_ip
		echo "==> Waiting for first controller to be ready..."
		timeout 300 bash -c "
			while ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \"${SSH_USER}@${CONTROLLER_IP}\" 'sudo k0s status >/dev/null 2>&1'; do
				echo 'Waiting for first controller...'
				sleep 10
			done
		"
	fi
}

# Setup first controller node
setup_first_controller() {
	echo "==> Setting up first controller node..."
	sudo k0s install controller -c "${K0S_CONFIG_FILE}"
	sudo k0s start
	wait_for_k0s_ready
	
	# Get and save controller IP for other nodes
	CONTROLLER_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -1)
	echo "==> Controller IP: ${CONTROLLER_IP}"
	
	# Save IP to shared folder (wait for mount)
	for i in {1..30}; do
		if mkdir -p "${SHARED_FOLDER}" 2>/dev/null && echo "${CONTROLLER_IP}" > "${CONTROLLER_IP_FILE}" 2>/dev/null; then
			echo "==> Saved controller IP to ${CONTROLLER_IP_FILE}"
			break
		fi
		echo "==> Waiting for shared folder... (${i}/30)"
		sleep 2
	done
	
	echo "==> First controller is ready"
}

# Setup additional controller nodes
setup_additional_controller() {
	echo "==> Setting up additional controller node (${NODE_INDEX})..."
	
	wait_for_first_controller
	
	# Get controller token
	CONTROLLER_TOKEN=$(ssh -o StrictHostKeyChecking=no "${SSH_USER}@${CONTROLLER_IP}" 'sudo k0s token create --role=controller --expiry=1h')
	if [ -z "$CONTROLLER_TOKEN" ]; then
		echo "ERROR: Failed to retrieve controller token"
		exit 1
	fi
	
	# Create temporary token file for k0s install
	TEMP_TOKEN_FILE=$(mktemp)
	echo "$CONTROLLER_TOKEN" > "$TEMP_TOKEN_FILE"
	
	sudo k0s install controller --token-file "$TEMP_TOKEN_FILE" -c ${K0S_CONFIG_FILE}
	sudo k0s start
	
	# Clean up temporary token file
	rm -f "$TEMP_TOKEN_FILE"
	
	wait_for_k0s_ready
}

# Setup worker node
setup_worker_node() {
	echo "==> Setting up worker node (${NODE_INDEX})..."
	
	wait_for_first_controller
	
	# Get worker token
	WORKER_TOKEN=$(ssh -o StrictHostKeyChecking=no "${SSH_USER}@${CONTROLLER_IP}" 'sudo k0s token create --role=worker')
	if [ -z "$WORKER_TOKEN" ]; then
		echo "ERROR: Failed to retrieve worker token"
		exit 1
	fi
	
	# Create temporary token file for k0s install
	TEMP_TOKEN_FILE=$(mktemp)
	echo "$WORKER_TOKEN" > "$TEMP_TOKEN_FILE"
	
	sudo k0s install worker --token-file "$TEMP_TOKEN_FILE"
	sudo k0s start
	
	# Clean up temporary token file
	rm -f "$TEMP_TOKEN_FILE"
	
	wait_for_k0s_ready
}

# Setup k0s based on node type and index
setup_k0s_node() {
	create_k0s_config
	
	case "${NODE_TYPE}" in
		"controller")
			if [ "${NODE_INDEX}" = "1" ]; then
				setup_first_controller
			else
				setup_additional_controller
			fi
			;;
		"worker")
			setup_worker_node
			;;
		*)
			echo "ERROR: Unknown node type: ${NODE_TYPE}"
			exit 1
			;;
	esac
}

# Setup kubeconfig (only for first controller)
setup_kubeconfig() {
	if [ "${NODE_TYPE}" = "controller" ] && [ "${NODE_INDEX}" = "1" ]; then
		echo "==> Setting up kubeconfig..."
		if [ -f /var/lib/k0s/pki/admin.conf ]; then
			sudo mkdir -p "${SHARED_FOLDER}"
			sudo cp /var/lib/k0s/pki/admin.conf "${SHARED_FOLDER}/kubeconfig"
			
			# Update kubeconfig to use the controller's IP
			CONTROLLER_IP=$(cat "${CONTROLLER_IP_FILE}")
			sudo sed -i "s/localhost/${CONTROLLER_IP}/g" "${SHARED_FOLDER}/kubeconfig"
			sudo sed -i "s/127.0.0.1/${CONTROLLER_IP}/g" "${SHARED_FOLDER}/kubeconfig"
			
			sudo chown "${SSH_USER}:${SSH_USER}" "${SHARED_FOLDER}/kubeconfig"
			sudo chmod 600 "${SHARED_FOLDER}/kubeconfig"
			echo "==> Kubeconfig created at ${SHARED_FOLDER}/kubeconfig"
		else
			echo "ERROR: admin.conf not found at /var/lib/k0s/pki/admin.conf"
			exit 1
		fi
	fi
}

# Display completion message and cluster info
show_completion_info() {
	echo "==> k0s installation completed successfully!"
	echo "==> Node Type: ${NODE_TYPE}"
	echo "==> Node Index: ${NODE_INDEX}"
	
	if [ "${NODE_TYPE}" = "controller" ]; then
		echo "==> Cluster info:"
		sudo k0s kubectl cluster-info || true
		echo "==> Node status:"
		sudo k0s kubectl get nodes || true
	fi
}

# Main execution
main() {
	update_system_packages
	install_required_packages
	install_k0s
	setup_k0s_node
	setup_kubeconfig
	show_completion_info
}

main "$@"
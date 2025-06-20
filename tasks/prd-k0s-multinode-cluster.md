# PRD: k0s Multi-Node Cluster with Vagrant

## Introduction/Overview

This feature expands the existing k0s Vagrant development environment from a single-node setup to a scalable multi-node Kubernetes cluster. The solution will refactor the current Vagrantfile to support a minimum configuration of 1 controller + 1 worker, with the ability to scale to high-availability setups (3 controllers + 2 workers) through environment variables. The feature integrates k0sctl for cluster management while maintaining the existing Task runner workflow and Tart provider virtualization on macOS.

**Problem Solved**: Developers need a realistic multi-node Kubernetes environment for testing distributed applications, node affinity, and cluster-level features that cannot be validated on single-node setups.

## Goals

1. **Scalable Architecture**: Enable programmatic scaling of controllers and workers via environment variables
2. **Production-like Development**: Provide a multi-node cluster that mimics real-world Kubernetes deployments
3. **Seamless Migration**: Refactor existing single-node setup without breaking current workflow
4. **Resource Optimization**: Implement differentiated resource allocation for controllers vs workers
5. **Network Reliability**: Establish stable inter-node communication using static IP addressing
6. **Cluster Management**: Integrate k0sctl for robust cluster lifecycle management

## User Stories

1. **As a developer**, I want to spin up a multi-node k0s cluster with `task vagrant:up` so that I can test distributed applications locally.

2. **As a developer**, I want to easily scale my cluster from 1 controller + 1 worker to 3 controllers + 2 workers by changing environment variables so that I can test high-availability scenarios.

3. **As a developer**, I want controllers to be able to run workloads in development mode so that I can maximize resource utilization on my local machine.

4. **As a developer**, I want automatic join token generation and node joining so that I don't have to manually configure cluster membership.

5. **As a developer**, I want to validate cluster health with task commands so that I can quickly verify my setup is working correctly.

6. **As a developer**, I want to access my cluster via kubeconfig from my host machine so that I can use local kubectl and development tools.

## Functional Requirements

1. **Cluster Configuration**
   - The system must support a minimum configuration of 1 controller + 1 worker
   - The system must scale controllers and workers based on environment variables: `control_plane_count` and `worker_count`
   - Controllers must be tainted to run workloads by default
   - In HA mode (3+ controllers), only 1/3 of controllers should be tainted to run workloads

2. **Resource Allocation**
   - Controllers must be allocated: 2048MB memory, 2 CPU cores, 32GB disk
   - Workers must be allocated: 4096MB memory, 2 CPU cores, 32GB disk
   - Resource allocation must be class-based (controller vs worker types)

3. **Network Configuration**
   - All nodes must use static IP addresses for reliable inter-node communication
   - The system must generate sequential IP addresses for each node type
   - The cluster must be accessible from the host machine via kubeconfig

4. **k0sctl Integration**
   - The system must use k0sctl for cluster configuration and management
   - Controller nodes must automatically generate join tokens for workers
   - The system must maintain a single cluster configuration file for the entire cluster

5. **Task Runner Integration**
   - Existing task commands (`task vagrant:up`, `task vagrant:destroy`, etc.) must work with multi-node setup
   - The system must provide cluster health validation commands
   - All VM management must remain unified through the task runner

6. **Provisioning and Bootstrap**
   - The system must automatically install k0s on all nodes
   - Controller nodes must be initialized before worker nodes attempt to join
   - The system must generate and distribute kubeconfig for host machine access

## Non-Goals (Out of Scope)

1. **Dynamic Scaling**: No support for adding/removing nodes without destroying the cluster
2. **Multiple OS Support**: Only Ubuntu VMs will be supported
3. **k0s Version Management**: Only latest k0s version will be supported
4. **Production Deployment**: This is for development/testing environments only
5. **External Load Balancer**: No external load balancer configuration for HA controllers
6. **Persistent Storage**: No persistent volume or storage class configuration
7. **Single-node Compatibility**: The existing single-node setup will be removed

## Design Considerations

### Environment Variables Configuration

```hcl
# Default values
control_plane_count = 1
worker_count = 1
memory_control = 2048
memory_worker = 4096
cpu_control = 2
cpu_worker = 2
disk_size = 32
```

### Static IP Allocation Strategy

- Controller nodes: 192.168.64.10, 192.168.64.11, 192.168.64.12
- Worker nodes: 192.168.64.20, 192.168.64.21, 192.168.64.22, etc.

### k0sctl Configuration Structure

- Single `k0sctl.yaml` file generated dynamically based on node count
- Automatic host inventory generation
- Controller initialization with worker join token distribution

### VM Naming Convention

- Controller nodes: `control-plane-1`, `control-plane-2`, `control-plane-3`
- Worker nodes: `worker-1`, `worker-2`, `worker-3`, etc.

## Technical Considerations

1. **Dependencies**: Requires k0sctl manual installation (not automated in bootstrap)
2. **VM Startup Orchestration**: Controllers must be fully initialized before workers can join
3. **Token Management**: Single-use join tokens with no rotation for development environments
4. **IP Address Management**: Dynamic IP allocation within static ranges
5. **Vagrant Provider**: Continue using vagrant-tart provider for Apple Silicon compatibility
6. **Bootstrap Sequencing**: Ensure proper initialization order for cluster formation
7. **Configuration Lifecycle**: All cluster configuration destroyed with `vagrant destroy` (no persistence)
8. **Error Handling**: Partial cluster failures treated as total failures requiring cluster rebuild
9. **Observability**: No built-in monitoring or alerting (future scope)

## Success Metrics

1. **Functionality**: Successfully deploy 1 controller + 1 worker cluster in under 5 minutes
2. **Scalability**: Scale to 3 controller + 2 worker HA cluster through environment variable changes
3. **Reliability**: 100% success rate for cluster formation and node joining
4. **Usability**: Existing task commands continue to work without modification
5. **Performance**: Workers allocated 2x memory of controllers handle workload distribution effectively
6. **Validation**: Cluster health checks pass for all deployed configurations

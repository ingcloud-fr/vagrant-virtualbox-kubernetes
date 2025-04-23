# Kubernetes with Vagrant and VirtualBox (Flannel / Cilium / WireGuard / Multi-ControlPlane)

This project lets you create a **Kubernetes cluster** (version configurable) on **Ubuntu** using **Vagrant** and **VirtualBox**. It supports **multi-node** and **multi-controlplane** setups (with *haproxy* on VIP), **extra VMs**, and **VirtualBox in Bridge (static and dynamic) or NAT mode**. You can choose the **CNI** (Flannel or Cilium with WireGuard), the container runtime (*containerd* or *Docker*), and it automatically handles node IPs.

> ⚠️ Multi-controlplane mode is **not supported** with `bridge_dyn`, because HAProxy must know the static IPs of the controlplanes to configure load balancing.

> 🧠 If no VIP is specified with `-p <num:VIP>`, the VIP will be set to the first address of `-a <ip_start>`.

> 🧪 In case of DHCP issues with `bridge_dyn`, try switching to `bridge_static` or `nat`.

---

## 🧱 Base Images

You must build at least one base image locally:

- `jammy64-updated` (Ubuntu 22.04): See [README](build_image_jammy/README.md)
- `noble64-updated` (Ubuntu 24.04): See [README](build_image_noble/README.md)

These images have **Falco pre-installed** for security labs.

---

## 🚀 Launch the Cluster with `vcluster`

Run with `--help`:
```bash
$ ./vcluster --help
```

### 🆙 Cluster Creation (up)
```bash
$ ./vcluster up -n <cluster_name> [-c <cni>] [-v <k8s_version>] [-w <workers>] [-m <build_mode>] [-i <ubuntu_box>] [-r <runtime>] [-a <ip_start>] [-p <num_controlplanes[:VIP]>] [-x <extra>] [--dry-run]
```

#### Examples

Basic cluster with defaults (creates or restarts cluster):
```bash
$ ./vcluster up -n k8s
```

Multi-controlplane named `k8s` with NAT and automatic VIP:
```bash
$ ./vcluster up -n k8s -v 1.32 -w 1 -p 2 -m nat -a 192.168.56.50
```

Multi-controlplane named `dev` with containerd:
```bash
$ ./vcluster up -n dev -w 1 -p 2 -r containerd -a 192.168.1.200
```

Cluster named `k8s` with DHCP IPs (bridge_dyn) with one controleplane, 1 worker node and a extra VM without Kubernetes :
```bash
$ ./vcluster up -n k8s -m bridge_dyn -w 2 -x 1
```

Dry-run preview:
```bash
$ ./vcluster up -n dev -i ubuntu-noble64 -c flannel -a 10.0.12.50 -x 1 --dry-run
🚀  Starting cluster ...
  Name: dev
  ControlPlanes: 1
  VIP: auto
  Workers: 1
  Extra nodes: 1
  CNI: cilium
  Kubernetes version: 1.32
  Runtime: docker
  Box: ubuntu-noble64
  Mode: bridge_static
[DRY-RUN] Vagrant up command that would be executed :
CLUSTER_NAME=dev K8S_VERSION=1.32 CNI_PLUGIN=cilium NUM_WORKER_NODES=1 NUM_CONTROLPLANE=1 NUM_EXTRA_NODES=1 BUILD_MODE=bridge_static UBUNTU_BOX=ubuntu-noble64 CONTAINER_RUNTIME=docker IP_START=10.0.12.50 vagrant up
```

---

### 📜 Options
```
-n <cluster_name>   Cluster name prefix (required for up and destroy)
-c <cni>            CNI plugin: cilium | flannel (default: cilium)
-v <k8s_version>    Kubernetes version (default: 1.32)
-w <workers>        Number of worker nodes (default: 1)
-m <build_mode>     Network mode: bridge_static | bridge_dyn | nat (default: bridge_static)
-i <ubuntu_box>     Ubuntu box image (default: jammy64-updated)
-r <runtime>        Container runtime: containerd | docker (default: docker)
-a <ip_start>       Static IP start address for bridge_static/net (default: 192.168.1.200)
-p <num[:VIP]>      Number of control planes and optional VIP (only in bridge_static and nat)
-x <extra>          Number of extra nodes without Kubernetes (default: 0)
--dry-run           Show the command without executing it
```

---

## 📄 Cluster Listing (list)

List existing clusters:
```bash
$ ./vcluster list
k8s
dev
```

List all nodes of all clusters:
```bash
$ ./vcluster list all
k8s-controlplane01
k8s-controlplane02
k8s-haproxy-vip
k8s-node01
dev-controlplane01
dev-node01
```

List nodes of a specific cluster:
```bash
$ ./vcluster list -n dev
dev-controlplane01
dev-node01
```

---

## 💣 Destroy Cluster (destroy)

Destroy a cluster:
```bash
$ ./vcluster destroy -n k8s
```

---

## ⏸️ Halt Cluster (halt)

Halt (shutdown) a cluster:
```bash
$ ./vcluster halt -n k8s
```

---

## 🔐 SSH Access (ssh)

SSH into a specific node:
```bash
$ ./vcluster ssh k8s-controlplane02
```

Or specify cluster prefix:
```bash
$ ./vcluster ssh -n dev dev-node01
```

---

## 🖥️ Launch manually with `vagrant up`

By default:
```bash
$ vagrant up
```

Override variables:
```bash
$ CLUSTER_NAME=dev CNI_PLUGIN=flannel K8S_VERSION=1.31 BUILD_MODE=nat \
  NUM_WORKER_NODES=2 NUM_CONTROLPLANE=3 CONTROLPLANE_VIP=192.168.1.10 \
  NUM_EXTRA_NODES=1 UBUNTU_BOX=noble64-updated CONTAINER_RUNTIME=containerd \
  IP_START=192.168.99.100 vagrant up
```

Destroy manually:
```bash
$ vagrant destroy -f
$ CLUSTER_NAME=dev vagrant destroy -f
```

SSH manually:
```bash
$ vagrant ssh dev-node01
```

---

## ✅ Features

- Multi-node and multi-controlplane support
- Optional Virtual IP (VIP) for control planes
- Add extra VMs for testing (no Kubernetes)
- Kubernetes installation via `kubeadm`
- Automatic kubeconfig setup
- NAT / BRIDGE_STATIC / BRIDGE_DYN networking
- Choice of CNI: Flannel or Cilium with WireGuard
- Choice of container runtime: Docker or containerd
- Persistent `.env.<cluster>` files for context reload
- Dry-run mode for safe preview of commands
- SSH shortcuts with `vcluster`
- Multi-cluster support with cluster name prefix

---

## 📚 Resources for High Availability Clusters

- [NERC HA Tutorial](https://nerc-project.github.io/nerc-docs/other-tools/kubernetes/kubeadm/HA-clusters-with-kubeadm/)
- [Kubernetes Official HA Guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)

---

## 🔧 Dependencies

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

**Tested on Ubuntu 22.04 host with Vagrant 2.4.3 and VirtualBox 7.0.**

---

## 📝 Author

Vincent Schultz — DevOps & Kubernetes Explorer 🚀
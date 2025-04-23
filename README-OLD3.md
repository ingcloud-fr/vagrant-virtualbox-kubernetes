# Kubernetes with Vagrant and VirtualBox (Flannel / Cilium / WireGuard / Multi-ControlPlane)

This project lets you create a **Kubernetes cluster** (version configurable) on **Ubuntu** using **Vagrant** and **VirtualBox**. It supports **multi-node** and **multi-controlplane** setups (with *haproxy* on VIP), **extra VMs**, and **VirtualBox in Bridge (static and dynamic) or NAT mode**. You can choose the **CNI** (Flannel or Cilium with WireGuard), the container runtime (*containerd* or *Docker*), and it automatically handles node IPs.

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

### Examples

Basic cluster with defaults:
```bash
$ ./vcluster up
```

Custom cluster with multi-controlplane and VIP:
```bash
$ ./vcluster up -n prod -w 2 -p 3:192.168.1.10 -c cilium -v 1.32 -m bridge_static -a 192.168.1.100
```

Create a cluster with extra VMs (no Kubernetes):
```bash
$ ./vcluster up -n dev -x 2
```

Dry-run:
```bash
$ ./vcluster up -n test --dry-run
```

### Options
```
-n <cluster_name>     Cluster name prefix (required)
-c <cni>              CNI: cilium | flannel (default: cilium)
-v <k8s_version>      Kubernetes version (default: 1.32)
-w <workers>          Number of worker nodes (default: 1)
-p <num[:VIP]>        Number of control planes (default: 1), optional VIP (e.g., 3:192.168.1.10)
-x <extra>            Number of extra nodes without Kubernetes (default: 0)
-m <build_mode>       bridge_static | bridge_dyn | nat (default: bridge_static)
-i <ubuntu_box>       Base image (default: jammy64-updated)
-r <runtime>          containerd | docker (default: docker)
-a <ip_start>         Static IP start for bridge_static (default: 192.168.1.200)
--dry-run             Show the command without executing
```

---

## 🔁 Other Commands

### Destroy a cluster:
```bash
$ ./vcluster destroy -n dev
```

### List clusters:
```bash
$ ./vcluster list
$ ./vcluster list -n dev
$ ./vcluster list all
```

### SSH into a node:
```bash
$ ./vcluster ssh dev-controlplane
$ ./vcluster ssh -n dev dev-node01
```

---

## 🖥️ Launch manually with `vagrant up`

By default:
```bash
$ vagrant up
```

### Override variables:
```bash
$ CLUSTER_NAME=dev CNI_PLUGIN=flannel K8S_VERSION=1.31 BUILD_MODE=nat \
  NUM_WORKER_NODES=2 NUM_CONTROLPLANE=3 CONTROLPLANE_VIP=192.168.1.10 \
  NUM_EXTRA_NODES=1 UBUNTU_BOX=noble64-updated CONTAINER_RUNTIME=containerd \
  BRIDGE_STATIC_IP_START=192.168.99.100 vagrant up
```

To destroy:
```bash
$ vagrant destroy -f
$ CLUSTER_NAME=dev vagrant destroy -f
```

To SSH manually:
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

## 🔧 Dependencies

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

**Tested on Ubuntu 22.04 host with Vagrant 2.4.3 and VirtualBox 7.0.**

---

## 📝 Author

Vincent Schultz — DevOps & Kubernetes Explorer 🚀


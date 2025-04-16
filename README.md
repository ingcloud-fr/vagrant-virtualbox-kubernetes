# Kubernetes with Vagrant and VirtualBox (Flannel / Cilium / WireGuard)

This project lets you create a Kubernetes cluster (version configurable) using Vagrant, with **VirtualBox in Bridge or NAT mode**. You can choose the CNI (**Flannel** or **Cilium with WireGuard encryption**) and it automatically manages the real IPs of the nodes.

---

## Base Image

- `jammy-updated`: See the [README](build_image/README.md) in the `build_image` folder

## 🚀 Launch the Cluster

### With vagrant up

Works out of the box:

```bash
$ vagrant up
```

With default values:
- BUILD_MOD="BRIDGE_STATIC"
- K8S_VERSION="1.32"
- NUM_WORKER_NODES=1
- CNI_PLUGIN="cillium"
- CLUSTER_NAME="k8s" (prefix)
- UBUNTU_BOX="jammy-updated"

Or by passing environment variables at launch, for example to create a cluster named `dev`:

```bash
$ CLUSTER_NAME=dev vagrant up
```

You can combine environment variables:

```bash
$ CLUSTER_NAME=dev CNI_PLUGIN=flannel K8S_VERSION=1.31 BUILD_MODE=nat NUM_WORKER_NODES=2 vagrant up
```

To cleanly destroy the machines:

```bash
$ vagrant destroy -f
```
Or if the cluster has a custom name:

```bash
$ CLUSTER_NAME=dev vagrant destroy -f
```

To connect via SSH:

```bash
$ vagrant ssh k8s-controlplane
```
Or if the cluster has a custom name:

```bash
$ CLUSTER_NAME=dev vagrant ssh dev-node01
```

### With vcluster (management script)

Help with `--help`:

```bash
$ ./vcluster --help
Usage:
  ./vcluster up -n <cluster_name> -c <cni> -v <k8s_version> -w <workers> -m <build_mode>
  ./vcluster destroy -n <cluster_name>
  ./vcluster ssh -n <cluster_name> <node> | ssh <cluster_name-node>
  ./vcluster list [-n <cluster_name>]
Options:
  -n <cluster_name>   Cluster name prefix (required for up, destroy)
  -c <cni>            CNI plugin: cilium | flannel (default: cilium)
  -v <k8s_version>    Kubernetes version (default: 1.32)
  -w <workers>        Number of worker nodes (default: 1)
  -m <build_mode>     Network mode: bridge_static | bridge_dyn | nat (default: bridge_static)

For bridge_static and bridge_dyn, you have to set IPs in the Vagrantfile
```

Start a cluster with default values:

```bash
$ ./vcluster up
```

Equivalent to:

```bash
$ ./vcluster up -n k8s -c cillium -w 1 -v 1.32
```

Example: Create a cluster named `dev` with 3 nodes (1 controlplane + 2 workers), using *flannel* as CNI, Kubernetes v1.31 in *NAT* mode:

```bash
$ ./vcluster up -n dev -c flannel -v 1.31 -w 2 -m nat
```

List clusters:

```bash
$ ./vcluster list
```

List nodes of a cluster:

```bash
$ ./vcluster list -n <cluster_name>
```

To SSH into a node:

```bash
$ ./vcluster ssh <cluster_name-node>
```

Or:

```bash
$ ./vcluster ssh -n <cluster_name> <node>
```

## Other

You can specify another Ubuntu image (may not work):

```bash
$ UBUNTU_BOX="bento/ubuntu-24.04" vagrant up
```

or modify it directly in the **Vagrantfile**

- Note: Not supported in **vcluster**.

## ✅ Current Features

- Multi-node deployment
- Multi-cluster support using `CLUSTER_NAME`
- Kubernetes installation via `kubeadm`
- Automatic `kubectl` configuration
- Support for **NAT**, **BRIDGE_STATIC**, and **BRIDGE_DYN**
- Choice of **CNI** (`flannel` or `cilium + WireGuard encryption`)
- Automatic generation of the `kubeadm join` command

## 🛠 Minimum Dependencies

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

Tested with Ubuntu 22.04 LTS as host OS and VirtualBox 7.0.

---

## 📝 Author

Vincent — DevOps & Kubernetes Explorer 🚀


# Kubernetes avec Vagrant et VirtualBox (Flannel / Cilium / WireGuard)

Ce projet vous permet de créer un cluster Kubernetes (version paramétrable) avec Vagrant, utilisant **VirtualBox en mode Bridge ou Nat**.
Il vous permet de choisir le CNI (**Flannel** ou **Cilium avec encryption WireGuard**) et gère automatiquement les IPs réelles des nœuds.

---

## 🚀 Lancer le cluster

```bash
vagrant up
```

ou :

```bash
CLUSTER_NAME=dev vagrant up
```

👉 Il est aussi possible d'utiliser une autre image Ubuntu que *ubuntu/jammy64* (ex : *boxen/ubuntu-24.04*) :

```bash
# Testée OK
UBUNTU_BOX=boxen/ubuntu-24.04 vagrant up
```
👉 Ou de personnaliser le nom du cluster (par defaut *k8s*) pour en exécuter plusieurs côte à côte :

```bash
CLUSTER_NAME=dev vagrant up
```

Ou de faire les 2 :

```
UBUNTU_BOX=boxen/ubuntu-24.04 CLUSTER_NAME=test vagrant up
```

---

## ⚙️ Paramètres personnalisables


### 🔧 Vagrantfile

- `BUILD_MODE="BRIDGE"` (ou `NAT`)  
  Mode de réseau utilisé pour les VMs. **BRIDGE est recommandé** (accès direct aux IPs).

- `NUM_WORKER_NODES=1`  
  Nombre de nœuds worker à déployer en plus du `controlplane`.

- `UBUNTU_BOX="ubuntu/jammy64"`  
  Image utilisée pour provisionner les machines (Ubuntu 22.04 par défaut). Possibilité d’utiliser `generic/ubuntu2204` ou autre image compatible Vagrant Cloud.

### 🔧 scripts/install-k8s-cluster.sh

- `K8S_VERSION="1.32"`  
  Version majeure.minor de Kubernetes à installer (stable).

- `POD_CIDR="10.244.0.0/16"`  
  CIDR utilisé pour le réseau des Pods.

- `CNI_PLUGIN="cilium"`  
  Plugin réseau à installer. Valeurs possibles :
  - `flannel`
  - `cilium` (**recommandé**, avec encryption WireGuard)

---

## ✅ Fonctionnalités actuelles

- Déploiement multi-nœuds automatisé
- Prise en charge du multi-cluster avec `CLUSTER_NAME`
- Installation de Kubernetes avec `kubeadm`
- Configuration automatique de `kubectl`
- Support **NAT** et **BRIDGE**
- Choix du **CNI** (`flannel` ou `cilium + encryption Wireguard`)
- Génération automatique de la commande `kubeadm join`

---

## 📌 Évolutions envisagées

- [ ] Support des runtimes de bas niveau (gVisor...)
- [ ] Ajout d’un Ingress Controller (NGINX)
- [ ] Ajout d’un LoadBalancer local (comme MetalLB ou LB Vagrant)
- [ ] Installation de la Dashboard Kubernetes
- [ ] Intégration de la stack Prometheus + Grafana
- [ ] Intégration de **Trivy** (scanner de vulnérabilités + CIS Benchmarks)
- [ ] Intégration de **Kyverno** (politiques de sécurité Kubernetes)
- [ ] Intégration de **ArgoCD** (GitOps et déploiement continu)

---

## 💡 Tips

- Pour détruire proprement les machines :
  ```bash
  CLUSTER_NAME=dev vagrant destroy -f
  ```
  Ou

  ```bash
  CLUSTER_NAME=dev vagrant destroy -f
  ```

- Pour se connecter en ssh :

  ```bash
  CLUSTER_NAME=dev vagrant ssh dev-controlplane
  ```
  ou

  ```bash
  CLUSTER_NAME=dev vagrant ssh dev-node01
  ```

- Pour re-provisionner une machine sans la redémarrer :
  ```bash
  vagrant provision controlplane
  ```
- Pour accéder au cluster depuis l’hôte (si en mode BRIDGE) :
  ```bash
  export KUBECONFIG=$(pwd)/.kube/config
  ```
- La commande `kubeadm join` est générée automatiquement par le `controlplane` et stockée dans `join-$CLUSTER_NAME.sh`. Elle est ensuite utilisée par les nœuds workers pour rejoindre le cluster :
  ```bash
  kubeadm join <IP>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
  ```

---

## 🛠 Dépendances minimales

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

Testé avec Ubuntu 22.04 LTS comme système hôte et invité.

---

## 📝 Auteur

Vincent — DevOps & Explorateur Kubernetes 🚀



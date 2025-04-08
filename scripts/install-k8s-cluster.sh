#!/bin/bash
set -e

# =======================
# Variables de configuration
# =======================

# Version de Kubernetes à installer
K8S_VERSION="1.32"
# Choix du CNI : "flannel" ou "cilium"
CNI_PLUGIN="cilium"
POD_CIDR="10.244.0.0/16"

# =======================
# Détection de l'interface
# =======================

# Préférence pour enp0s8 (bridged)
if ip a show enp0s8 > /dev/null 2>&1; then
  BRIDGE_IFACE="enp0s8"
else
  BRIDGE_IFACE=$(ip route | grep default | grep -v tun0 | head -n1 | awk '{print $5}')
fi

echo "[DEBUG] Interface détectée : $BRIDGE_IFACE"
echo "[DEBUG] Attente de l'IP sur $BRIDGE_IFACE (max 30s)..."

# Attente active jusqu'à ce que l'interface ait une IP ou timeout (30s max)
for i in {1..30}; do
  MASTER_IP=$(ip -o -4 addr show dev "$BRIDGE_IFACE" | awk '{print $4}' | cut -d/ -f1)
  if [[ -n "$MASTER_IP" ]]; then
    echo "[DEBUG] MASTER_IP détectée : $MASTER_IP"
    break
  fi
  sleep 1
done

# Échec si après 30s toujours rien
if [[ -z "$MASTER_IP" ]]; then
  echo "[ERREUR] Impossible de récupérer une IP sur $BRIDGE_IFACE après 30 secondes."
  echo "[DEBUG] Interfaces réseau disponibles :"
  ip a
  exit 1
fi

echo "[DEBUG] Interface détectée : $BRIDGE_IFACE"
echo "[DEBUG] IP utilisée pour kubeadm : $MASTER_IP"

export DEBIAN_FRONTEND=noninteractive

# Activation de l'IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Préparation du noyau pour Kubernetes (réseaux, ponts)
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# Mise à jour et installation des dépendances
apt-get update && apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

# Installation de containerd uniquement
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Installation de Kubernetes

curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Alias kubectl + autocompletion pour l'utilisateur vagrant
echo "[+] Ajout de l'alias 'k' et de l'autocompletion pour kubectl"

echo "alias k='kubectl'" >> /home/vagrant/.bashrc
echo "source <(kubectl completion bash)" >> /home/vagrant/.bashrc
echo "complete -o default -F __start_kubectl k" >> /home/vagrant/.bashrc

# Désactivation du swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# =======================
# Initialisation ou jointure du noeud
# =======================
if hostname | grep -q controlplane; then
  echo "[+] Initialisation du cluster Kubernetes sur le controlplane"
  kubeadm init --apiserver-advertise-address=$MASTER_IP --pod-network-cidr=$POD_CIDR --kubernetes-version=stable-${K8S_VERSION} 

  echo "KUBELET_EXTRA_ARGS=--node-ip=$MASTER_IP" > /etc/default/kubelet
  systemctl daemon-reexec
  systemctl restart kubelet

  # =======================
  # kubeconfif
  # =======================

  echo "[+] Configuration de kubectl pour l'utilisateur vagrant"
  mkdir -p /home/vagrant/.kube
  cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  chown vagrant:vagrant /home/vagrant/.kube/config

  # =======================
  # Installation du CNI
  # =======================

  echo "[+] Déploiement du CNI : $CNI_PLUGIN"
  if [[ "$CNI_PLUGIN" == "flannel" ]]; then
    echo "[+] Installation de Flannel"
    su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"

  elif [[ "$CNI_PLUGIN" == "cilium" ]]; then
    echo "[+] Déploiement du CNI Cilium avec Helm"
    # Installation de Helm si absent
    if ! command -v helm &> /dev/null; then
      echo "[+] Helm n'est pas installé. Installation en cours..."
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    # Ajout du repo Cilium et mise à jour
    su - vagrant -c "helm repo add cilium https://helm.cilium.io/"
    su - vagrant -c "helm repo update"

    # Attente que l'API Kubernetes soit prête avec un timeout et debug
    echo "[+] Attente que l'API Kubernetes soit prête (kubectl get nodes)..."
    i=0
    until su - vagrant -c "kubectl get nodes &>/dev/null"; do
      i=$((i + 1))
      sleep 2
      if [[ $i -ge 120 ]]; then
        echo "[ERREUR] L'API Kubernetes n'est pas prête après 4 minutes."
        echo "[DEBUG] Contenu de /home/vagrant/.kube/config :"
        cat /home/vagrant/.kube/config
        exit 1
      fi
    done

    # Lancement de l'installation avec encryption et autres options
    su - vagrant -c "helm install cilium cilium/cilium \
      --namespace kube-system \
      --set kubeProxyReplacement=true \
      --set kubeProxyReplacementStrict=true \
      --set encryption.enabled=true \
      --set encryption.type=wireguard \
      --set enableL7Proxy=true \
      --set k8sServiceHost=$MASTER_IP \
      --set k8sServicePort=6443 \
      --set operator.replicas=1"
  else
    echo "[!] Erreur : CNI inconnu : $CNI"
    exit 1
  fi

  # Generation du le commande join
  echo "[+] Generation de la commande de join"
  JOIN_COMMAND=$(kubeadm token create --print-join-command)

  # Extrait l'ancienne IP du join (champ 3 = ip:port)
  OLD_IP=$(echo "$JOIN_COMMAND" | awk '{print $3}' | cut -d: -f1)

  echo "[DEBUG] OLD_IP = $OLD_IP"
  echo "[DEBUG] MASTER_IP = $MASTER_IP"
  echo "[DEBUG] JOIN_COMMAND AVANT = $JOIN_COMMAND"

  # Remplace uniquement l'IP, laisse le port intact
  JOIN_COMMAND=$(echo "$JOIN_COMMAND" | sed "s/$OLD_IP/$MASTER_IP/")
  
  echo "[DEBUG] JOIN_COMMAND APRÈS = $JOIN_COMMAND"

  # Sauvegarde dans le fichier
  echo "$JOIN_COMMAND" > /vagrant/join.sh
  chown vagrant:vagrant /vagrant/join.sh
  chmod +x /vagrant/join.sh

else
  echo "[+] Attente du script de jointure..."
  while [ ! -f /vagrant/join.sh ]; do sleep 2; done
  echo "[+] Configuration de l'IP du noeud pour kubelet"
  echo "KUBELET_EXTRA_ARGS=--node-ip=$MASTER_IP" > /etc/default/kubelet
  systemctl daemon-reexec
  systemctl restart kubelet

  echo "[+] Exécution du script de jointure"
  /vagrant/join.sh
fi

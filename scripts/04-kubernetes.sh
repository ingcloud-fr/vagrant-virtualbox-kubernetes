#!/bin/bash
set -e

# ============================
# 04-kubernetes.sh
# Installation de Kubernetes (kubelet, kubeadm, kubectl)
# ============================

export DEBIAN_FRONTEND=noninteractive

# Version par défaut si non transmise en variable d'env
K8S_VERSION=${K8S_VERSION:-1.32}

# Récupération de l'IP
MY_IP=$(grep PRIMARY_IP /etc/environment | cut -d= -f2)

# --- Désactivation du swap ---
echo "🔧  Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Ubuntu 24.04 (noble) reactive le swap lors d'un redemarrage
cat <<EOF | sudo tee /etc/systemd/system/disable-swap.service
[Unit]
Description=Disable swap at boot
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/swapoff -a
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable disable-swap

echo "📦  Installing kubelet kubeadm kubectl"
# Préparation du dossier
sudo mkdir -p /etc/apt/keyrings

# Import de la clé GPG et conversion au bon format
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key |
  gpg --dearmor |
  sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null

# Déclaration du dépôt
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" |
  sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update > /dev/null
apt-get install -y kubelet kubeadm kubectl > /dev/null

# Empêche la mise à jour automatique par erreur
apt-mark hold kubelet kubeadm kubectl

# Alias + complétion bash pour l’utilisateur vagrant
su - vagrant -c "echo 'alias k=\"kubectl\"' >> ~/.bashrc"
su - vagrant -c "echo 'source <(kubectl completion bash)' >> ~/.bashrc"
su - vagrant -c "echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc"

# --- Configuration de l'adresse IP du noeud pour le kubelet et redemarrage ---
echo "ℹ️  Configuring Kubelet to listen on IP $MY_IP"
if [[ -n "$MY_IP" ]]; then
  echo "KUBELET_EXTRA_ARGS=--node-ip=$MY_IP" > /etc/default/kubelet
  systemctl daemon-reexec
  systemctl restart kubelet
else
  echo "🚨 MY_IP variable is not defined. Please set the IP address before running this script."
  exit 1
fi
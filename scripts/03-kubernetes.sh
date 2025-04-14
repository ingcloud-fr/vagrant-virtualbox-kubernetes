#!/bin/bash
set -e

# ============================
# 03-kubernetes.sh
# Installation de Kubernetes (kubelet, kubeadm, kubectl)
# ============================

# Version par défaut si non transmise en variable d'env
K8S_VERSION=${K8S_VERSION:-1.32}

# Préparation du dossier
sudo mkdir -p /etc/apt/keyrings

# Import de la clé GPG et conversion au bon format
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key |
  gpg --dearmor |
  sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null

# Déclaration du dépôt
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" |
  sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl

# Empêche la mise à jour automatique par erreur
apt-mark hold kubelet kubeadm kubectl

# Alias + complétion bash pour l’utilisateur vagrant
su - vagrant -c "echo 'alias k=\"kubectl\"' >> ~/.bashrc"
su - vagrant -c "echo 'source <(kubectl completion bash)' >> ~/.bashrc"
su - vagrant -c "echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc"
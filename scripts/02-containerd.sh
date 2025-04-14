#!/bin/bash
set -euo pipefail

# ===========================================
# 02-containerd.sh : Installation de containerd
# ===========================================

# Installation du runtime containerd uniquement
apt-get install -y containerd

# Création du répertoire de configuration si absent
mkdir -p /etc/containerd

# Génération du fichier de configuration par défaut
containerd config default | tee /etc/containerd/config.toml

# Activation du mode cgroup systemd
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Utilisation d'une image "pause" à jour (nécessaire pour éviter les erreurs kubeadm)
sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml

# Redémarrage et activation de containerd
systemctl restart containerd
systemctl enable containerd

#!/bin/bash
set -euo pipefail

# ===========================================
# 02-containerd-docker.sh : Installation de containerd et de docker depuis les dépôts Docker
# ===========================================

export DEBIAN_FRONTEND=noninteractive

# Prérequis
# apt-get update
# apt-get install -y ca-certificates curl gnupg lsb-release

# Ajout de la clé GPG Docker
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Ajout du dépôt Docker (adapté à la version d'Ubuntu)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Installation de containerd.io et de Docker (version maintenue par Docker)
apt-get update
# apt-get install -y containerd.io
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 

# Ajout de l'utilisateur vagrant au groupe docker (évite les sudo docker)
sudo usermod -aG docker vagrant

# Configuration de containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

# Activation du mode cgroup systemd
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Mise à jour de l’image pause
sed -i 's|sandbox_image = ".*"|sandbox_image = "registry.k8s.io/pause:3.10"|' /etc/containerd/config.toml

# Redémarrage et activation
systemctl restart containerd
systemctl enable containerd

# Création de /etc/crictl.yaml
tee /etc/crictl.yaml > /dev/null <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

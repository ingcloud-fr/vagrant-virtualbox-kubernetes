#!/bin/bash
set -euo pipefail

# =========================================
# Script 01-base-setup.sh
# Préparation de base commune à tous les nœuds
# =========================================

# ========================================
# Détection de l’interface réseau principale (priorité à enp0s8)
# ========================================
if ip a show enp0s8 &>/dev/null; then
  BRIDGE_IFACE="enp0s8"
else
  BRIDGE_IFACE=$(ip route | grep default | grep -vE 'docker|virbr|br-' | awk '{print $5}' | head -n1)
fi

# ========================================
# Récupération de l’adresse IP sur cette interface
# ========================================
for i in {1..30}; do
  MY_IP=$(ip -o -4 addr show dev "$BRIDGE_IFACE" | awk '{print $4}' | cut -d/ -f1)
  if [[ -n "$MY_IP" ]]; then
    echo "[DEBUG] IP détectée sur $BRIDGE_IFACE : $MY_IP"
    break
  fi
  echo "[ATTENTE] Pas d’IP encore détectée... ($i/30)"
  sleep 1
done

if [[ -z "$MY_IP" ]]; then
  echo "[ERREUR] Impossible de récupérer une IP sur l'interface $BRIDGE_IFACE"
  exit 1
fi

# ========================================
# Export dans /etc/environment
# ========================================
echo "[DEBUG] Enregistrement de l’IP dans /etc/environment"
sed -i '/^PRIMARY_IP=/d' /etc/environment
echo "PRIMARY_IP=$MY_IP" >> /etc/environment

# Point to Google's DNS server / Désactive le stub DNS local (127.0.0.53)
sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
sed -i 's/^#*DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
service systemd-resolved restart

# Export non-interactif pour éviter les prompts apt
export DEBIAN_FRONTEND=noninteractive

# Désactive unattended-upgrades si présent (optionnel mais recommandé en lab)
echo "[BASE] Désactivation de unattended-upgrades"
systemctl stop unattended-upgrades || true
systemctl disable unattended-upgrades || true

# Mise à jour des dépôts et des paquets
apt-get update -y
apt-get upgrade -y

# Installation des dépendances communes
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  linux-headers-$(uname -r) \
  linux-tools-common \
  linux-tools-$(uname -r) \
  jq \
  git

# Préparation du noyau pour Kubernetes (réseaux, ponts)
echo "[BASE] Chargement des modules noyau Kubernetes"
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# Configuration sysctl nécessaire pour Kubernetes
echo "[BASE] Configuration sysctl"
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# Activation immédiate du forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Lien symbolique pour bpftool si nécessaire
KERNEL_VERSION=$(uname -r)
ln -sf /usr/lib/linux-tools-${KERNEL_VERSION}/bpftool /usr/local/bin/bpftool || true
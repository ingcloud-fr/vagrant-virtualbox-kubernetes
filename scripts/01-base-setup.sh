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

# Forçage DHCP si en mode BRIDGE_DYN
if [[ "${BUILD_MODE:-}" == "BRIDGE_DYN" ]]; then
  echo "🔧 BUILD_MODE=BRIDGE_DYN — Forcing DHCP on the bridged interface"
  echo "↪️  Requesting a new IP address on interface enp0s8 $BRIDGE_IFACE"
  dhclient -v "$BRIDGE_IFACE" || echo "⚠️  dhclient failed, continuing anyway"
fi

# ========================================
# Récupération de l’adresse IP sur cette interface
# ========================================

for i in {1..30}; do
  MY_IP=$(ip -o -4 addr show dev "$BRIDGE_IFACE" | awk '{print $4}' | cut -d/ -f1)
  if [[ -n "$MY_IP" ]]; then
    echo "ℹ️  Detected IP on $BRIDGE_IFACE : $MY_IP"
    break
  fi
  echo "⏳ No IP detected ... ($i/30)"
  sleep 1
done

if [[ -z "$MY_IP" ]]; then
  echo "❌  Impossibe to get the IP from  $BRIDGE_IFACE"
  exit 1
fi

# ========================================
# Export dans /etc/environment
# ========================================
echo "ℹ️  Saving $MY_IP in /etc/environment"
sed -i '/^PRIMARY_IP=/d' /etc/environment
echo "PRIMARY_IP=$MY_IP" >> /etc/environment

# Point to Google's DNS server / Désactive le stub DNS local (127.0.0.53)
echo "ℹ️  Modifying /etc/systemd/resolved.conf and restarting the service"
sed -i -e 's/#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
sed -i 's/^#*DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
service systemd-resolved restart

# Export non-interactif pour éviter les prompts apt
export DEBIAN_FRONTEND=noninteractive

# Désactive unattended-upgrades si présent (optionnel mais recommandé en lab)
echo "ℹ️  Disabling the unattended-upgrades service"
systemctl stop unattended-upgrades || true
systemctl disable unattended-upgrades || true

echo "ℹ️  Installing common dependencies"
# Mise à jour des dépôts et des paquets
apt-get update -y > /dev/null
apt-get upgrade -y > /dev/null
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
  etcd-client \
  jq \
  git > /dev/null

# Préparation du noyau pour Kubernetes (réseaux, ponts)
echo "ℹ️  Preparing the kernel for Kubernetes"
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configuration sysctl nécessaire pour Kubernetes
echo "[BASE] Configuration sysctl"
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# On applique sysctl sans reboot
sysctl --system

# Activation immédiate du forwarding (A VOIR SI PAS EN DOUBLE AVEC DESSUS)
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Lien symbolique pour bpftool 
KERNEL_VERSION=$(uname -r)
ln -sf /usr/lib/linux-tools-${KERNEL_VERSION}/bpftool /usr/local/bin/bpftool || true

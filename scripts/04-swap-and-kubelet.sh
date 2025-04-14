#!/bin/bash
set -e

# =============================
# 04 - Désactivation du swap et configuration du kubelet
# =============================

# Récupération de l'IP
MY_IP=$(grep PRIMARY_IP /etc/environment | cut -d= -f2)

# --- Désactivation du swap ---
echo "[+] Désactivation du swap"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# --- Configuration de l'adresse IP du noeud pour le kubelet ---
if [[ -n "$MY_IP" ]]; then
  echo "[+] Configuration de l'adresse IP kubelet : $MY_IP"
  echo "KUBELET_EXTRA_ARGS=--node-ip=$MY_IP" > /etc/default/kubelet
  systemctl daemon-reexec
  systemctl restart kubelet
else
  echo "[!] Variable MY_IP non définie. Veuillez définir l'adresse IP avant d'exécuter ce script."
  exit 1
fi

#!/bin/bash
set -e

# ======================
# Script pour les noeuds WORKER
# ======================

CLUSTER_NAME=${CLUSTER_NAME:-k8s}
JOIN_SCRIPT="/vagrant/join-${CLUSTER_NAME}.sh"

# Récupération de l'IP locale (exporté dans 01)
MY_IP=$(grep PRIMARY_IP /etc/environment | cut -d= -f2)

echo "⚙️  Installating a worker node ..."

# Ajout de l'entrée dans le fichier partagé /vagrant/hosts
if [ -f /vagrant/hosts ]; then
  echo "$MY_IP $(hostname)" >> /vagrant/hosts
fi

# # Copie des clés ssh crées sur le controlplane
# cat /vagrant/id_rsa.vagrant.${CLUSTER_NAME}.pub >> /home/vagrant/.ssh/authorized_keys
# chmod 600 /home/vagrant/.ssh/authorized_keys
# cat /vagrant/id_rsa.root.${CLUSTER_NAME}.pub >> /root/.ssh/authorized_keys
# cat /vagrant/id_rsa.vagrant.${CLUSTER_NAME}.pub >> /root/.ssh/authorized_keys
# chmod 600 /root/.ssh/authorized_keys

# Attente que le script de jointure soit disponible
echo "[+] Attente du script de jointure ($JOIN_SCRIPT)..."
for i in {1..30}; do
  if [ -f "$JOIN_SCRIPT" ]; then
    break
  fi
  echo "[ATTENTE] Script de jointure non trouvé, tentative $i/30..."
  sleep 2
done

# Échec si le script n'existe pas
if [ ! -f "$JOIN_SCRIPT" ]; then
  echo "[ERREUR] Le script de jointure n'existe pas."
  exit 1
fi

# Copie du kubeconfig pour permettre kubectl sur les workers
mkdir -p /home/vagrant/.kube
cp /vagrant/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# Configuration de l'IP du noeud pour kubelet
MY_IP=$(ip -o -4 addr show dev enp0s8 | awk '{print $4}' | cut -d/ -f1)
echo "KUBELET_EXTRA_ARGS=--node-ip=$MY_IP" > /etc/default/kubelet
systemctl daemon-reexec
systemctl restart kubelet

# Vérifie que le controlplane est joignable
CONTROLPLANE_IP=$(awk '{print $3}' $JOIN_SCRIPT | cut -d: -f1)
if ! nc -z -w5 $CONTROLPLANE_IP 6443; then
  echo "[ERREUR] Le port 6443 sur $CONTROLPLANE_IP est injoignable."
  exit 1
fi

# Exécution du script de jointure
bash "$JOIN_SCRIPT" || exit 1

echo "🏁 WORKER node $(hostname) successfully joined the Kubernetes cluster !"

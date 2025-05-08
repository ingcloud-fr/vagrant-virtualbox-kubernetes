#!/bin/bash
set -e

# ======================
# 06-Script pour les noeuds CONTROLPLANE secondaires (multi-controlplane)
# ======================

CLUSTER_NAME=${CLUSTER_NAME:-k8s}
CONTROLPLANE_VIP="${CONTROLPLANE_VIP:-192.168.1.210}"
JOIN_SCRIPT="/vagrant/join-controlplane-${CLUSTER_NAME}.sh"

# Récupération de l'IP locale (exporté dans 01)
MY_IP=$(grep PRIMARY_IP /etc/environment | cut -d= -f2)

echo "⚙️  Installating a secondary controlplane ..."

# Ajout de l'entrée dans le fichier partagé /vagrant/hosts
if [ -f /vagrant/hosts ]; then
  echo "$MY_IP $(hostname)" >> /vagrant/hosts
fi

# Copie des clés ssh crées sur le controlplane
# cat /vagrant/id_rsa.vagrant.${CLUSTER_NAME}.pub >> /home/vagrant/.ssh/authorized_keys
# chmod 600 /home/vagrant/.ssh/authorized_keys
# cat /vagrant/id_rsa.root.${CLUSTER_NAME}.pub >> /root/.ssh/authorized_keys
# cat /vagrant/id_rsa.vagrant.${CLUSTER_NAME}.pub >> /root/.ssh/authorized_keys
# chmod 600 /root/.ssh/authorized_keys


#  echo "⏳ Vérification de l'accessibilité du VIP $CONTROLPLANE_VIP sur les ports nécessaires..."
# REQUIRED_PORTS=(6443 2379)
# TIMEOUT=60                               # ⏱️ Timeout en secondes par port
# for PORT in "${REQUIRED_PORTS[@]}"; do
#   echo -n "🔌 Test $CONTROLPLANE_VIP:$PORT ... "
#   start=$(date +%s)

#   until nc -z "$CONTROLPLANE_VIP" "$PORT" >/dev/null 2>&1; do
#     echo -n "."
#     sleep 2
#     now=$(date +%s)
#     if (( now - start > TIMEOUT )); then
#       echo ""
#       echo -e "❌ Timeout de ${TIMEOUT}s atteint pour $CONTROLPLANE_VIP:$PORT"
#       echo "⛔ Abandon du script. Vérifiez la configuration HAProxy / réseau."
#       exit 1
#     fi
#   done

#   echo "✅ OK"
# done

# echo ""
# echo "🚀 Tous les ports sont accessibles. Lancement du kubeadm join..."




# Copie du kubeconfig pour permettre kubectl sur les workers
mkdir -p /home/vagrant/.kube
cp /vagrant/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# # Configuration de l'IP du noeud pour kubelet
# MY_IP=$(ip -o -4 addr show dev enp0s8 | awk '{print $4}' | cut -d/ -f1)
# echo "KUBELET_EXTRA_ARGS=--node-ip=$MY_IP" > /etc/default/kubelet
# echo "🐞 Fichier généré /etc/default/kubelet"
# cat /etc/default/kubelet

systemctl daemon-reexec
systemctl restart kubelet

# Vérifie que le VIP est joignable
CONTROLPLANE_IP=$(awk '{print $3}' $JOIN_SCRIPT | cut -d: -f1)
if ! nc -z -w5 $CONTROLPLANE_VIP 6443; then
  echo "❌ Le port 6443 sur $CONTROLPLANE_IP est injoignable."
  exit 1
fi

# Attente que le script de jointure soit disponible
for i in {1..30}; do
  if [ -f "$JOIN_SCRIPT" ]; then
    break
  fi
  echo "⏳ Script de jointure non trouvé, tentative $i/30..."
  sleep 2
done

# Échec si le script n'existe pas
if [ ! -f "$JOIN_SCRIPT" ]; then
  echo "❌ Le script de jointure controlplane n'existe pas."
  exit 1
fi


# echo "🐞 Contenu du fichier JOIN_SCRIPT $JOIN_SCRIPT"
# cat $JOIN_SCRIPT

kubeadm config images pull

# Exécution du script de jointure

echo '🐞 Executing join script : $JOIN_SCRIPT --apiserver-advertise-address "$MY_IP"'

# bash "$JOIN_SCRIPT" --config /tmp/join-config.yaml || exit 1
bash "$JOIN_SCRIPT" --apiserver-advertise-address "$MY_IP"
#kubeadm join --config=/tmp/join-config.yaml --v=5

# Removing taint node-role.kubernetes.io/control-plane:NoSchedule
echo "🔧 Removing Taint node-role.kubernetes.io/control-plane:NoSchedule"
NODE_NAME=$(hostname)
su - vagrant -c "kubectl taint node \"$NODE_NAME\" node-role.kubernetes.io/control-plane-"

echo "🏁 Secondary CONTROLPLANE node $(hostname) successfully joined the Kubernetes cluster !"



#!/bin/bash
set -e

echo "🧹 Restoring original manifests and kubelet config..."

MANIFEST_DIR="/etc/kubernetes/manifests"
BACKUP_MANIFEST_DIR="/etc/kubernetes/backup"
KUBELET_CONFIGMAP_BACKUP="/etc/kubernetes/backup/kubelet-config-cm.yaml"
ETCD_DIR="/var/lib/etcd"

# Restore manifests
for file in etcd.yaml kube-apiserver.yaml kube-controller-manager.yaml kube-scheduler.yaml; do
  if [ -f "$BACKUP_MANIFEST_DIR/$file" ]; then
    sudo cp "$BACKUP_MANIFEST_DIR/$file" "$MANIFEST_DIR/$file"
  fi
done

echo "🔐 Restoring etcd data directory permissions..."
sudo chmod 700 $ETCD_DIR

# Attente que l'API server redémarre proprement
sleep 2
echo "⏳ Waiting for kube-apiserver to come back..."
until kubectl get nodes &> /dev/null; do
  sleep 1
done

echo "🔐 Restoring Kubelet ConfigMap..."
# Restore kubelet configmap from backup
if [ -f "$KUBELET_CONFIGMAP_BACKUP" ]; then
  # echo "🔁 Restoring kubelet configmap..."
  # echo "🧨 Deleting existing kubelet-config ConfigMap..."
  kubectl delete configmap kubelet-config -n kube-system > /dev/null
  # echo "🔁 Recreating kubelet-config ConfigMap from backup..."
  kubectl create -f $KUBELET_CONFIGMAP_BACKUP > /dev/null 2>&1
  sudo kubeadm upgrade node phase kubelet-config > /dev/null 2>&1
fi

echo "🔄 Restarting kubelet..."
sudo systemctl restart kubelet

# Delete kube-bench
sudo rm -f /usr/local/bin/kube-bench > /dev/null 2>&1
sudo -rf /etc/kube-bench > /dev/null 2>&1

# Delete backup
# rm -rf $BACKUP_MANIFEST_DIR > /dev/null 2>&1

echo "✅ Reset complete."

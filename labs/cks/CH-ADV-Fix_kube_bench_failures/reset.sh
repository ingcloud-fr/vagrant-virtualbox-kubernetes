#!/bin/bash
set -e

echo "🧹 Restoring original manifests and kubelet config..."

MANIFEST_DIR="/etc/kubernetes/manifests"
BACKUP_MANIFEST_DIR="/etc/kubernetes/backup/manifests"

KUBELET_CONFIGMAP_BACKUP="/etc/kubernetes/backup/kubelet-config-cm.yaml"

# Restore manifests
for file in etcd.yaml kube-apiserver.yaml kube-controller-manager.yaml kube-scheduler.yaml; do
  if [ -f "$BACKUP_MANIFEST_DIR/$file" ]; then
    sudo cp "$BACKUP_MANIFEST_DIR/$file" "$MANIFEST_DIR/$file"
  fi
done

# Restore kubelet configmap from backup
if [ -f "$KUBELET_CONFIGMAP_BACKUP" ]; then
  # echo "🔁 Restoring kubelet configmap..."
  # echo "🧨 Deleting existing kubelet-config ConfigMap..."
  kubectl delete configmap kubelet-config -n kube-system
  # echo "🔁 Recreating kubelet-config ConfigMap from backup..."
  kubectl create -f $KUBELET_CONFIGMAP_BACKUP
  sudo kubeadm upgrade node phase kubelet-config
fi

echo "🔄 Restarting kubelet..."
sudo systemctl restart kubelet

# Delete kube-bench
sudo rm -f /usr/local/bin/kube-bench
sudo -rf /etc/kube-bench

echo "✅ Reset complete."

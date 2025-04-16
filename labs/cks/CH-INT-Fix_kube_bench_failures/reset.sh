#!/bin/bash
set -e

echo "🧹 Restoring original manifests and kubelet config..."

MANIFEST_DIR="/etc/kubernetes/manifests"
BACKUP_MANIFEST_DIR="$MANIFEST_DIR/backup"

KUBELET_DIR="/var/lib/kubelet"
BACKUP_KUBELET_DIR="$KUBELET_DIR/backup"

for file in etcd.yaml kube-apiserver.yaml kube-controller-manager.yaml kube-scheduler.yaml; do
  if [ -f "$BACKUP_MANIFEST_DIR/$file" ]; then
    sudo cp "$BACKUP_MANIFEST_DIR/$file" "$MANIFEST_DIR/$file"
    echo "✅ Restored $file"
  else
    echo "⚠️  Backup not found for $file"
  fi
done

if [ -f "$BACKUP_KUBELET_DIR/config.yaml" ]; then
  sudo cp "$BACKUP_KUBELET_DIR/config.yaml" "$KUBELET_DIR/config.yaml"
  echo "✅ Restored kubelet config.yaml"
else
  echo "⚠️  Backup not found for kubelet config.yaml"
fi

echo "🔄 Restarting kubelet..."
sudo systemctl restart kubelet

echo "✅ Reset complete."

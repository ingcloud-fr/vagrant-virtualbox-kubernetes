#!/bin/bash
set -e

echo "🧹 Restoring original insecure manifests..."

BACKUP_DIR="/etc/kubernetes/tmp"
MANIFEST_DIR="/etc/kubernetes/manifests"

for file in etcd.yaml kube-apiserver.yaml kube-controller-manager.yaml kube-scheduler.yaml; do
  if [ -f "$BACKUP_DIR/$file" ]; then
    sudo cp "$BACKUP_DIR/$file" "$MANIFEST_DIR/$file"
  else
    echo "⚠️  Backup missing for $file — skipping"
  fi
done

echo "🧽 Cleaning up backup files..."
sudo rm -rf "$BACKUP_DIR"

echo "🧹 Removing kube-bench..."
sudo rm -f /usr/local/bin/kube-bench
sudo rm -rf /etc/kube-bench

echo "🔁 Forcing kube-apiserver to reload..."
sudo touch /etc/kubernetes/manifests/kube-apiserver.yaml

echo "✅ Reset complete. Re-run kube-bench to confirm."

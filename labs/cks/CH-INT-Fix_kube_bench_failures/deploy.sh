#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."
#echo "🔧 Backing up manifests and kubelet config..."
MANIFEST_DIR="/etc/kubernetes/manifests" 
BACKUP_MANIFEST_DIR="$MANIFEST_DIR/backup"

KUBELET_DIR="/var/lib/kubelet"
BACKUP_KUBELET_DIR="$KUBELET_DIR/backup"

sudo mkdir -p $BACKUP_MANIFEST_DIR
sudo mkdir -p $BACKUP_KUBELET_DIR

for file in etcd.yaml kube-apiserver.yaml kube-controller-manager.yaml kube-scheduler.yaml; do
    if [ ! -f "$BACKUP_MANIFEST_DIR/$file" ]; then
      sudo cp "$MANIFEST_DIR/$file" "$BACKUP_MANIFEST_DIR/$file"
    fi
done

if [ ! -f "$BACKUP_KUBELET_DIR/config.yaml" ]; then
  sudo cp "$KUBELET_DIR/config.yaml" "$BACKUP_KUBELET_DIR/"
fi

echo "🔐 Applying CIS hardening to components..."

# etcd
if [ -f "$MANIFEST_DIR/etcd.yaml" ]; then
  sudo sed -i '/- --listen-metrics-urls/a \    - --cert-file=/etc/kubernetes/pki/etcd/server.crt\n    - --key-file=/etc/kubernetes/pki/etcd/server.key\n    - --client-cert-auth=true\n    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt' "$MANIFEST_DIR/etcd.yaml"
  echo "✅ etcd.yaml patched"
fi

# kube-apiserver
if [ -f "$MANIFEST_DIR/kube-apiserver.yaml" ]; then
  sudo sed -i '/- --secure-port=6443/a \    - --authorization-mode=Node,RBAC\n    - --anonymous-auth=false\n    - --profiling=false\n    - --service-account-key-file=/etc/kubernetes/pki/sa.pub\n    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt\n    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key\n    - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt\n    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key' "$MANIFEST_DIR/kube-apiserver.yaml"
  echo "✅ kube-apiserver.yaml patched"
fi

# kube-controller-manager
if [ -f "$MANIFEST_DIR/kube-controller-manager.yaml" ]; then
  sudo sed -i '/- --root-ca-file/a \    - --use-service-account-credentials=true\n    - --root-ca-file=/etc/kubernetes/pki/ca.crt' "$MANIFEST_DIR/kube-controller-manager.yaml"
  echo "✅ kube-controller-manager.yaml patched"
fi

# kube-scheduler
if [ -f "$MANIFEST_DIR/kube-scheduler.yaml" ]; then
  sudo sed -i '/- --bind-address/a \    - --profiling=false' "$MANIFEST_DIR/kube-scheduler.yaml"
  echo "✅ kube-scheduler.yaml patched"
fi

# kubelet
if [ -f "$KUBELET_DIR/config.yaml" ]; then
  echo "🔧 Patching /var/lib/kubelet/config.yaml"
  sudo sed -i '/authentication:/a \  anonymous:\n    enabled: false\n  webhook:\n    enabled: true' "$KUBELET_DIR/config.yaml"
  sudo sed -i '/authorization:/a \  mode: "Webhook"' "$KUBELET_DIR/config.yaml"
  echo "✅ kubelet config.yaml patched"
fi

echo "🔄 Restarting kubelet to apply changes..."
sudo systemctl restart kubelet

# Installation kube-bench
tools/install-kube-bench.sh

echo
echo "************************************"
echo
cat README.txt
echo
echo "✅ Lab setup and hardening completed."

#!/bin/bash
set -e

echo "🔧 Creating lab resources ..."

MANIFEST_DIR="/etc/kubernetes/manifests"
BACKUP_DIR="$MANIFEST_DIR/backup"

sudo mkdir -p $BACKUP_DIR

for file in etcd.yaml kube-apiserver.yaml kube-controller-manager.yaml kube-scheduler.yaml; do
    if [ ! -f "$BACKUP_DIR/$file" ]; then
      sudo cp "$MANIFEST_DIR/$file" "$BACKUP_DIR/$file"
    fi
done

# -- etcd: fix 2.1 and 2.2
sudo sed -i '/--listen-peer-urls/a\    - --cert-file=/etc/kubernetes/pki/etcd/server.crt\n    - --key-file=/etc/kubernetes/pki/etcd/server.key\n    - --client-cert-auth=true' /etc/kubernetes/manifests/etcd.yaml

# -- kube-apiserver: fix 1.2.22 and 1.2.23
sudo sed -i '/--secure-port/a\    - --anonymous-auth=false\n    - --profiling=false' /etc/kubernetes/manifests/kube-apiserver.yaml

# -- kube-controller-manager: fix 1.3.2
sudo sed -i '/--controllers=/a\    - --use-service-account-credentials=true' /etc/kubernetes/manifests/kube-controller-manager.yaml

# -- kube-scheduler: fix 1.4.1
sudo sed -i '/--leader-elect/a\    - --profiling=false' /etc/kubernetes/manifests/kube-scheduler.yaml

# touch to force reload (in case kubelet doesn't detect edit)
sudo touch /etc/kubernetes/manifests/kube-apiserver.yaml

# Installation kube-bench
tools/install-kube-bench.sh

echo
echo "************************************"
echo
cat README.txt
echo

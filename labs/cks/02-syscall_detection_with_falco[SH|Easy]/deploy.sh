#!/bin/bash
set -e

echo "🔧 Creating namespaces..."
kubectl apply -f manifests/namespaces.yaml > /dev/null

echo "🚀 Deploying applications..."
kubectl apply -f manifests/apps.yaml > /dev/null

echo "🔍 Installing Falco (can take 2min)..."
bash tools/install-falco.sh > /dev/null

echo
echo "************************************"
echo
cat README.txt
echo
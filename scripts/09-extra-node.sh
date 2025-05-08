#!/bin/bash
set -e

# ======================
# 09 - Script pour extra-node (sans Kubernetes)
# ======================

echo "⚙️  Configuring the extra node without Kubernetes ..."
# Récupération de l'IP locale (exportée dans 01)
MY_IP=$(grep PRIMARY_IP /etc/environment | cut -d= -f2)
# Add in /vagrant/hosts
HOSTNAME=$(hostname)
echo "$MY_IP $HOSTNAME" >> /vagrant/hosts
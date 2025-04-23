#!/bin/bash
set -e
  
CLUSTER_NAME=${CLUSTER_NAME:-k8s}

echo "⚙️  Configuring SSH access between nodes ..."

mkdir -p /home/vagrant/.ssh
cp /vagrant/ssh-keys/id_rsa_${CLUSTER_NAME} /home/vagrant/.ssh/id_rsa
cp /vagrant/ssh-keys/id_rsa_${CLUSTER_NAME}.pub /home/vagrant/.ssh/id_rsa.pub
cat /vagrant/ssh-keys/id_rsa_${CLUSTER_NAME}.pub >> /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 644 /home/vagrant/.ssh/id_rsa.pub
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
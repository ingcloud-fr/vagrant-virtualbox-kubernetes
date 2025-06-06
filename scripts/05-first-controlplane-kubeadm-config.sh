#!/bin/bash
set -ex

# ======================================
# 05 - Nœud multi/controlplane Kubernetes 
# ======================================

# Ce script initialise le cluster Kubernetes
# Il s'exécute uniquement sur le controlplane

# Variables
K8S_VERSION="1.32"
CNI_PLUGIN=${CNI_PLUGIN:-cilium}
POD_CIDR="10.244.0.0/16"
CLUSTER_NAME=${CLUSTER_NAME:-k8s}

CONTROLPLANE_VIP="${CONTROLPLANE_VIP:-192.168.1.210}"
NUM_CONTROLPLANE="${NUM_CONTROLPLANE:-1}"

IP_START="${IP_START:-192.168.1.200}"
BASE_IP=$(echo "$IP_START" | cut -d. -f1-3)
START_OCTET=$(echo "$IP_START" | cut -d. -f4)

# Récupération de l'IP locale (exportée dans 01)
MY_IP=$(grep PRIMARY_IP /etc/environment | cut -d= -f2)

# Génération du fichier /vagrant/hosts (entête)
echo "# Hosts list generated by Vagrant" > /vagrant/hosts
echo "127.0.0.1 localhost" >> /vagrant/hosts

# Ajout de l'IP locale
echo "$MY_IP $(hostname)" >> /vagrant/hosts

# ====================
# Génération du fichier kubeadm-config.yaml
# ====================

#echo "⚙️  Génération du fichier kubeadm-config.yaml (HA mode avec VIP $CONTROLPLANE_VIP)"

# Determination de la version cmplète de Kubernetes pour kubernetesVersion dans /vagrant/kubeadm-config.yaml
# INSTALLED_K8S_VERSION=$(dpkg-query -W -f='${Version}' kubeadm | cut -d'-' -f1)

# ****************** AVEC KUBEADM-CONFIG *******************

# # Création du fichier kubeadm-config.yaml
# cat <<EOF > /vagrant/kubeadm-config.yaml
# apiVersion: kubeadm.k8s.io/v1beta4
# kind: InitConfiguration
# localAPIEndpoint:
#   advertiseAddress: "${PRIMARY_IP}"
#   bindPort: 6443
# nodeRegistration:
#   name: "$(hostname)"
#   kubeletExtraArgs:
#     node-ip: "${PRIMARY_IP}"
# ---
# apiVersion: kubeadm.k8s.io/v1beta4
# kind: ClusterConfiguration
# kubernetesVersion: "${INSTALLED_K8S_VERSION}"
# controlPlaneEndpoint: "${CONTROLPLANE_VIP}:6443"
# apiServer:
#   certSANs:
#     - 127.0.0.1
#     - localhost
#     - ${MY_IP}
#     - ${CONTROLPLANE_VIP}
#   extraArgs:
#     - name: advertise-address
#       value: ${MY_IP}
# etcd:
#   local:
#     serverCertSANs:
#       - 127.0.0.1
#       - ${MY_IP}
#     peerCertSANs:
#       - 127.0.0.1
#       - ${MY_IP}
#     extraArgs:
#       - name: listen-client-urls
#         value: "https://127.0.0.1:2379,https://${MY_IP}:2379"
#       - name: advertise-client-urls
#         value: "https://${MY_IP}:2379"
#       - name: listen-peer-urls
#         value: "https://${MY_IP}:2380"
#       - name: initial-advertise-peer-urls
#         value: "https://${MY_IP}:2380"
#       - name: initial-cluster
#         value: "k8sm-controlplane01=https://${MY_IP}:2380"
# networking:
#   podSubnet: "${POD_CIDR}"
# EOF


# echo "🐞 Fichier kubeadm-config.yaml généré :"
# cat /vagrant/kubeadm-config.yaml


# # ====================
# # Initialisation du cluster avec kubeadm-config.yaml
# # ====================

# kubeadm init \
#   --config /vagrant/kubeadm-config.yaml \
#   --upload-certs
# # NOTES
# # --upload-certs : pour que les autres controlplanes puissent rejoindre avec --control-plane

# **************************************************************


# INIT

kubeadm config images pull
kubeadm init --control-plane-endpoint $CONTROLPLANE_VIP:6443 \
  --upload-certs \
  --apiserver-advertise-address $MY_IP \
  --pod-network-cidr=$POD_CIDR


# Récupération du hash et token join
JOIN_COMMAND_CONTROLPLANE=$(kubeadm token create --print-join-command)
HASH=$(echo "$JOIN_COMMAND_CONTROLPLANE" | grep -o 'sha256:[a-f0-9]*')
TOKEN=$(echo "$JOIN_COMMAND_CONTROLPLANE" | awk '{print $5}')

# Récupération de la clé pour le join en mode control-plane
CERT_KEY=$(kubeadm init phase upload-certs --upload-certs | tail -1)

# Génération du script de join pour les autres controlplanes
JOIN_CONTROLPLANE="kubeadm join ${CONTROLPLANE_VIP}:6443 --token ${TOKEN} --discovery-token-ca-cert-hash ${HASH} --control-plane --certificate-key ${CERT_KEY}"

echo "$JOIN_CONTROLPLANE" > /vagrant/join-controlplane-${CLUSTER_NAME}.sh

cat <<EOF > /vagrant/join-controlplane-${CLUSTER_NAME}.sh
#!/bin/bash
$JOIN_CONTROLPLANE "\$@"
EOF




chmod +x /vagrant/join-controlplane-${CLUSTER_NAME}.sh
chown vagrant:vagrant /vagrant/join-controlplane-${CLUSTER_NAME}.sh

# On exporte dans un fichier partagé pour que 07-controlplane-join.sh les utilise
cat <<EOF > /vagrant/controlplane-vars.env
# info join command : ${JOIN_COMMAND_CONTROLPLANE}
TOKEN=$TOKEN
HASH=$HASH
CERT_KEY=$CERT_KEY
EOF

echo "🐞 Fichier /vagrant/controlplane-vars.env généré :"
cat /vagrant/controlplane-vars.env

# Configuration du kubelet (pour écouter sur la bonne IP)
cat <<EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=$MY_IP
EOF
systemctl daemon-reexec
systemctl restart kubelet

# Configuration de kubectl pour vagrant
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chmod 600 /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Copie du kubeconfig pour les autres nodes
cp /etc/kubernetes/admin.conf /vagrant/admin.conf
chown vagrant:vagrant /vagrant/admin.conf

# Création de clés pour SSH ET SCP entre nodes
echo "⚙️ Création de clés ssh sur le controlplane"
ssh-keygen -t rsa -b 2048 -N "" -f /root/.ssh/id_rsa
chown vagrant:vagrant /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
cp /root/.ssh/id_rsa.pub /vagrant/id_rsa.root.${CLUSTER_NAME}.pub
ssh-keygen -t rsa -b 2048 -N "" -f /home/vagrant/.ssh/id_rsa
chown vagrant:vagrant /home/vagrant/.ssh/id_rsa
chmod 600 /home/vagrant/.ssh/id_rsa
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/id_rsa.vagrant.${CLUSTER_NAME}.pub

# Attente (utile encore ??)
echo "⏳ Attente que l'API Kubernetes soit accessible via la VIP ($CONTROLPLANE_VIP:6443)..."
start=$(date +%s)
timeout=120

until curl -k https://$CONTROLPLANE_VIP:6443/version >/dev/null 2>&1; do
  echo -n "..."
  sleep 3
  now=$(date +%s)
  if (( now - start > timeout )); then
    echo ""
    echo "🚨 Timeout atteint. L'API Kubernetes n'est pas accessible via la VIP"
    exit 1
  fi
done

echo ""
echo "✅ API Kubernetes accessible via la VIP. Suite du provisioning..."


echo "⏳ Attente que l'API Kubernetes soit disponible pour installation du CNI..."
for i in {1..60}; do
  su - vagrant -c "kubectl get nodes &>/dev/null" && break
  sleep 2
done

# Installation du CNI
echo "🔧 Installation du CNI : $CNI_PLUGIN"
if [[ "$CNI_PLUGIN" == "flannel" ]]; then
  su - vagrant -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
elif [[ "$CNI_PLUGIN" == "cilium" ]]; then
  if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  fi
  su - vagrant -c "helm repo add cilium https://helm.cilium.io/"
  su - vagrant -c "helm repo update"
  su - vagrant -c "helm install cilium cilium/cilium \
    --namespace kube-system \
    --set kubeProxyReplacement=true \
    --set kubeProxyReplacementStrict=true \
    --set encryption.enabled=true \
    --set encryption.type=wireguard \
    --set enableL7Proxy=true \
    --set k8sServiceHost=$MY_IP \
    --set k8sServicePort=6443 \
    --set operator.replicas=1"
else
  echo "[ERREUR] CNI '$CNI_PLUGIN' inconnu."
  exit 1
fi


# Génération du script de jointure
JOIN_COMMAND=$(kubeadm token create --print-join-command)
OLD_IP=$(echo "$JOIN_COMMAND" | awk '{print $3}' | cut -d: -f1)
JOIN_COMMAND=$(echo "$JOIN_COMMAND" | sed "s/$OLD_IP/$MY_IP/")
echo "$JOIN_COMMAND" > /vagrant/join-${CLUSTER_NAME}.sh
chown vagrant:vagrant /vagrant/join-${CLUSTER_NAME}.sh
chmod +x /vagrant/join-${CLUSTER_NAME}.sh

# On supprime la taint node-role.kubernetes.io/control-plane:NoSchedule
# echo "[+] Removing Taint node-role.kubernetes.io/control-plane:NoSchedule"
# su - vagrant -c "kubectl taint node ${CLUSTER_NAME}-controlplane01 node-role.kubernetes.io/control-plane-"




#############  POUR DEBUG ##############
cat <<EOF > /etc/env-k8s-vars
export CONTROLPLANE_VIP=CONTROLPLANE_VIP
export MY_IP=$MY_IP
export K8S_VERSION=K8S_VERSION
export POD_CIDR=POD_CIDR
export BASE_IP=BASE_IP
export START_OCTET=START_OCTET
export NUM_CONTROLPLANE=NUM_CONTROLPLANE
export CONTAINER_RUNTIME=CONTAINER_RUNTIME
export TOKEN=$TOKEN
export HASH=$HASH
export CERT_KEY=$CERT_KEY
export JOIN_COMMAND_CONTROLPLANE=$JOIN_COMMAND_CONTROLPLANE
export JOIN_COMMAND=$JOIN_COMMAND

EOF
########################################


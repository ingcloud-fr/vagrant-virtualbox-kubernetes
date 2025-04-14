#!/bin/bash
set -e

# Install Falco CLI only
#curl -s https://falco.org/repo/falco-install.sh | bash -s -- --cli-only

# helm repo add falcosecurity https://falcosecurity.github.io/charts
# helm repo update
# helm install --replace falco --namespace falco --create-namespace --set tty=true falcosecurity/falco
# kubectl wait pods --for=condition=Ready --all -n falco --timeout=2m

cat << 'EOF' > install-falco-nodes.sh
#!/bin/bash
set -e

# Ajout de la clé GPG
curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | \
  sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg

# Ajout du dépôt
sudo bash -c 'cat << EOL > /etc/apt/sources.list.d/falcosecurity.list
deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main
EOL'

# Mise à jour et installation
sudo apt-get update -y
sudo apt-get install -y dialog
sudo FALCO_FRONTEND=noninteractive apt-get install -y falco
EOF


for i in `kubectl get nodes -oname | awk -F/ '{print $2}' | grep -v controlplane` 
do 
  sudo scp install-falco-nodes.sh root@$i:/tmp
  sudo ssh -o StrictHostKeyChecking=no root@$i "chmod +x /tmp/install-falco-nodes.sh && /tmp/install-falco-nodes.sh"
done

rm -f install-falco-nodes.sh
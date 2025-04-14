# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:

# =============================
# Configuration globale
# =============================

# Mode de déploiement :
# "BRIDGE_STATIC/bridge_static"   - Place les VMs sur ton réseau local, ce qui permet d'accéder aux NodePorts depuis un navigateur.
#                                   Il faut avoir suffisamment d'adresses IP libres sur ton LAN.
# "BRIDGE_DYN/bridge_dyn"          - Place les VMs sur ton réseau local, ce qui permet d'accéder aux NodePorts depuis un navigateur.
#                                    Avec DHCP.
# "NAT/nat                          - Place les VMs dans un réseau privé. Les NodePorts ne sont pas accessibles
#                                   sauf si tu configures un port forwarding pour chaque port souhaité.
#                                   À utiliser si le mode BRIDGE ne fonctionne pas.
BUILD_MODE = (ENV['BUILD_MODE'] || "BRIDGE_STATIC").upcase

# Image Ubuntu - $ UBUNTU_BOX=generic/ubuntu2204 vagrant up
UBUNTU_BOX = ENV['UBUNTU_BOX'] || "jammy64-updated"

# Nom du cluster utilisé pour préfixer les noms de VMs
CLUSTER_NAME = ENV['CLUSTER_NAME'] || "k8s"

# CNI : cillium ou flannel
CNI_PLUGIN = ENV['CNI_PLUGIN'] || "cilium"

# Version Kubernetes
K8S_VERSION = ENV['K8S_VERSION'] || "1.32"

# Nombre de nœuds workers à créer
NUM_WORKER_NODES = (ENV['NUM_WORKER_NODES'] || 1).to_i

# Paramètres réseau utilisés uniquement pour le mode BRIDGE_STATIC 
BRIDGE_STATIC_IP_START = "192.168.1.200" # Début des IPs statiques pour BRIDGE_STATIC

# Paramètres réseau utilisés uniquement pour le mode NAT 
IP_NW = "192.168.56"   # Le network
MASTER_IP_START = 11   # L'adresse IP du masterplane
NODE_IP_START = 20     # L'adresse de départ des workers

def static_ip(offset)
  base = BRIDGE_STATIC_IP_START.rpartition('.')[0]
  last = BRIDGE_STATIC_IP_START.rpartition('.')[2].to_i + offset
  return "#{base}.#{last}"
end

def get_bridge_adapter()
  iface = %x{ip route | grep default | awk '{print $5}' | grep -Ev 'tun0|docker0|virbr0|br-' | head -n1}.chomp
  return iface
end

Vagrant.configure("2") do |config|
  config.vm.box = UBUNTU_BOX
  config.vm.boot_timeout = 900
  config.vm.box_check_update = false

  # =============================
  # Noeud controlplane
  # =============================
  config.vm.define "#{CLUSTER_NAME}-controlplane" do |node|
    node.vm.provider "virtualbox" do |vb|
      vb.name = "#{CLUSTER_NAME}-controlplane"
      vb.memory = 2048
      vb.cpus = 2
    end
    node.vm.hostname = "#{CLUSTER_NAME}-controlplane"

    if BUILD_MODE == "BRIDGE_DYN"
      node.vm.network :public_network, bridge: get_bridge_adapter()
    elsif BUILD_MODE == "BRIDGE_STATIC"
      node.vm.network :public_network, ip: static_ip(0), bridge: get_bridge_adapter()
    else # NAT
      node.vm.network :private_network, ip: IP_NW + ".#{MASTER_IP_START}"
      node.vm.network "forwarded_port", guest: 22, host: "#{2710}"
    end

    # === Provisioning par scripts ===
    node.vm.provision "01-network", type: "shell", path: "scripts/01-base-setup.sh"
    node.vm.provision "02-containerd", type: "shell", path: "scripts/02-containerd.sh"
    node.vm.provision "03-kubernetes", type: "shell", path: "scripts/03-kubernetes.sh", env: {"K8S_VERSION" => K8S_VERSION}
    node.vm.provision "04-swap-kubelet", type: "shell", path: "scripts/04-swap-and-kubelet.sh"
    node.vm.provision "05-controlplane", type: "shell", path: "scripts/05-controlplane.sh", 
      env: { "CNI_PLUGIN" => CNI_PLUGIN,
      "K8S_VERSION" => K8S_VERSION,
      "CLUSTER_NAME" => CLUSTER_NAME}
    #node.vm.provision "07-sync-hosts", type: "shell", path: "scripts/07-sync-hosts.sh"
  end

  # =============================
  # Noeuds workers
  # =============================
  (1..NUM_WORKER_NODES).each do |i|
    config.vm.define "#{CLUSTER_NAME}-node0#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "#{CLUSTER_NAME}-node0#{i}"
        vb.memory = 1024
        vb.cpus = 1
      end
      node.vm.hostname = "#{CLUSTER_NAME}-node0#{i}"

      if BUILD_MODE == "BRIDGE_DYN"
        node.vm.network :public_network, bridge: get_bridge_adapter()
      elsif BUILD_MODE == "BRIDGE_STATIC"
        node.vm.network :public_network, ip: static_ip(i), bridge: get_bridge_adapter()
      else
        node.vm.network :private_network, ip: IP_NW + ".#{NODE_IP_START + i}"
        node.vm.network "forwarded_port", guest: 22, host: "#{2720 + i}"
      end

      # === Provisioning par scripts ===
      node.vm.provision "01-network", type: "shell", path: "scripts/01-base-setup.sh"
      node.vm.provision "02-containerd", type: "shell", path: "scripts/02-containerd.sh"
      node.vm.provision "03-kubernetes", type: "shell", path: "scripts/03-kubernetes.sh", env: {"K8S_VERSION" => K8S_VERSION}
      node.vm.provision "04-swap-kubelet", type: "shell", path: "scripts/04-swap-and-kubelet.sh"
      node.vm.provision "06-worker", type: "shell", path: "scripts/06-worker.sh", env: {"CLUSTER_NAME" => CLUSTER_NAME}
    end
  end
  
  # =============================
  # Synchronisation du fichier /etc/hosts à la fin
  # =============================
  if ARGV[0] == "up" || ARGV[0] == "provision"
    at_exit do
      puts "[SYNC] Synchronisation du fichier /etc/hosts dans toutes les VMs..."
      nodes = ["#{CLUSTER_NAME}-controlplane"] +
              (1..NUM_WORKER_NODES).map { |j| "#{CLUSTER_NAME}-node0#{j}" }

      nodes.each do |vm|
        puts "→ Upload du fichier hosts vers #{vm}"
        system("vagrant upload hosts /tmp/hosts.tmp #{vm}")
        system("vagrant ssh #{vm} -c 'sudo cp /tmp/hosts.tmp /etc/hosts && echo [OK] /etc/hosts mis à jour' -- -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null")
      end
    end
  end
end

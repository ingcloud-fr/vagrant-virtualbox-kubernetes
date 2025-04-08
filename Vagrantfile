# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:

# Mode de déploiement :
# "BRIDGE" - Place les VMs sur ton réseau local, ce qui permet d'accéder aux NodePorts depuis un navigateur.
#            Il faut avoir suffisamment d'adresses IP libres sur ton LAN.
# "NAT"    - Place les VMs dans un réseau privé. Les NodePorts ne sont pas accessibles
#            sauf si tu configures un port forwarding pour chaque port souhaité.
#            À utiliser si le mode BRIDGE ne fonctionne pas.
BUILD_MODE = "NAT"

# Image Ubuntu - $ UBUNTU_BOX=generic/ubuntu2204 vagrant up
UBUNTU_BOX = ENV['UBUNTU_BOX'] || "ubuntu/jammy64"

# Nombre de nœuds workers à créer
NUM_WORKER_NODES = 1

# Paramètres réseau utilisés uniquement pour le mode NAT (non testé avec Kubernetes ici)
IP_NW = "192.168.56"
MASTER_IP_START = 11
NODE_IP_START = 20

# Détermine l’interface réseau à utiliser pour le mode BRIDGE
# (utile pour connecter les VMs au LAN local)
def get_bridge_adapter()
  # Ignore les interfaces VPN ou virtuelles
  iface = %x{ip route | grep default | awk '{print $5}' | grep -Ev 'tun0|docker0|virbr0|br-' | head -n1}.chomp
  return iface
end

# Récupère l'ID VirtualBox d’une VM (si elle existe déjà)
def get_machine_id(vm_name)
  machine_id_filepath = ".vagrant/machines/#{vm_name}/virtualbox/id"
  if not File.exist? machine_id_filepath
    return nil
  else
    return File.read(machine_id_filepath)
  end
end

# Vérifie si toutes les VMs (controlplane + workers) sont créées
def all_nodes_up()
  if get_machine_id("controlplane").nil?
    return false
  end

  (1..NUM_WORKER_NODES).each do |i|
    if get_machine_id("node0#{i}").nil?
      return false
    end
  end
  return true
end

# Provisionne le fichier /etc/hosts et le DNS dans les VMs
def setup_dns(node)
  # Provisionne /etc/hosts
  node.vm.provision "setup-hosts", :type => "shell", :path => "scripts/setup-hosts.sh" do |s|
    s.args = [IP_NW, BUILD_MODE, NUM_WORKER_NODES, MASTER_IP_START, NODE_IP_START]
  end
  # Provisionne la résolution DNS
  node.vm.provision "setup-dns", type: "shell", :path => "scripts/update-dns.sh"
end

# Exécute les étapes de provision communes à toutes les VMs Kubernetes
def provision_kubernetes_node(node)
  setup_dns node
  node.vm.provision "setup-ssh", :type => "shell", :path => "scripts/ssh.sh"
end

# Début de la configuration principale Vagrant
Vagrant.configure("2") do |config|
  # Box de base utilisée pour toutes les VMs
  config.vm.box = UBUNTU_BOX
  config.vm.boot_timeout = 900
  config.vm.box_check_update = false

  # Définition du noeud master (controlplane)
  config.vm.define "controlplane" do |node|
    node.vm.provider "virtualbox" do |vb|
      vb.name = "controlplane"
      vb.memory = 2048
      vb.cpus = 2
    end
    node.vm.hostname = "controlplane"

    if BUILD_MODE == "BRIDGE"
      adapter = ""
      node.vm.network :public_network, bridge: get_bridge_adapter()
    else
      node.vm.network :private_network, ip: IP_NW + ".#{MASTER_IP_START}"
      node.vm.network "forwarded_port", guest: 22, host: "#{2710}"
    end
    provision_kubernetes_node node

    # Provision du cluster Kubernetes (initialisation)
    node.vm.provision "shell", path: "scripts/install-k8s-cluster.sh"

    # Copie des fichiers de confs personnalisés utiles
    node.vm.provision "file", source: "./scripts/vimrc", destination: "$HOME/.vimrc"
  end

  # Définition des noeuds workers
  (1..NUM_WORKER_NODES).each do |i|
    config.vm.define "node0#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "node0#{i}"
        vb.memory = 1024
        vb.cpus = 1
      end
      node.vm.hostname = "node0#{i}"

      if BUILD_MODE == "BRIDGE"
        node.vm.network :public_network, bridge: get_bridge_adapter()
      else
        node.vm.network :private_network, ip: IP_NW + ".#{NODE_IP_START + i}"
        node.vm.network "forwarded_port", guest: 22, host: "#{2720 + i}"
      end
      provision_kubernetes_node node

      # Provision du worker (le script détecte s’il doit joindre le cluster)
      node.vm.provision "shell", path: "scripts/install-k8s-cluster.sh"
    end
  end

  # Ajoute automatiquement les IPs dans /etc/hosts une fois les VMs démarrées
  if BUILD_MODE == "BRIDGE"
    config.trigger.after :up do |trigger|
      trigger.name = "Post provisioner"
      trigger.ignore = [:destroy, :halt]
      trigger.ruby do |env, machine|
        if all_nodes_up()
          puts "    Récupération des adresses IP des nœuds..."
          nodes = ["controlplane"]
          ips = []
          (1..NUM_WORKER_NODES).each do |i|
            nodes.push("node0#{i}")
          end
          nodes.each do |n|
            # ATTENTION : la commande 'public-ip' doit exister dans la VM pour que cette ligne fonctionne.
            # Sinon, ips[i] sera vide et l'URL affichée à la fin sera invalide : "http://:port_number"
            # A VERIFIER
            ips.push(%x{vagrant ssh #{n} -c 'public-ip'}.chomp)
          end
          hosts = ""
          ips.each_with_index do |ip, i|
            hosts << ip << "  " << nodes[i] << "\n"
          end
          puts "    Mise à jour de /etc/hosts dans chaque VM..."
          File.open("hosts.tmp", "w") { |file| file.write(hosts) }
          nodes.each do |node|
            system("vagrant upload hosts.tmp /tmp/hosts.tmp #{node}")
            system("vagrant ssh #{node} -c 'cat /tmp/hosts.tmp | sudo tee -a /etc/hosts'")
          end
          File.delete("hosts.tmp")
          puts <<~EOF

                 Construction des VMs terminée !

                 Tu peux accéder à tes services NodePort via l'IP des nœuds,
                 en remplaçant "port_number" par le bon port :

                 ⚠️ Si l'IP n'apparaît pas ci-dessous, vérifie que la commande 'public-ip' est bien disponible dans la VM.

               EOF
          (1..NUM_WORKER_NODES).each do |i|
            puts "  http://#{ips[i]}:port_number"
          end
          puts ""
        else
          puts "    Rien à faire ici"
        end
      end
    end
  end
end


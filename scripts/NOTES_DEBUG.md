# NOTES POUR DEBUG

# Pour tester la connection ETCD directe et avec VIP depuis un controleplane

```
$ for ip in 192.168.1.240 192.168.1.230 192.168.1.231; do
  echo "🔍 Test etcd sur $ip:2379"
  sudo ETCDCTL_API=3 etcdctl --endpoints=https://$ip:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
    --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
    endpoint health --write-out=table
done
```
Test client SSL vers etcd

$ openssl s_client -connect 192.168.1.240:2379

----

- NOTE le HA-PROXY sur la VIP  192.168.1.240:6443 avec les 2 controlplanes doit être ok

Sur 1ier controlplane01:

On attache kubelet sur la bonne interface :

$ echo "KUBELET_EXTRA_ARGS=--node-ip=192.168.1.230" > /etc/default/kubelet

On relance kubelet :

systemctl daemon-reexec
systemctl restart kubelet


$ sudo kubeadm reset -f

Norlalement stop le kubelet et efface les fichiers, sinon :
sudo rm -rf /var/lib/etcd /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml /etc/kubernetes/manifests/kube-scheduler.yaml /etc/kubernetes/manifests/etcd.yaml

----------------------------
$ sudo kubeadm init --control-plane-endpoint 192.168.1.240:6443 \
  --upload-certs \
  --apiserver-advertise-address 192.168.1.230 \
  --pod-network-cidr=10.244.0.0/16
...
You can now join any number of control-plane nodes running the following command on each as root:

  kubeadm join 192.168.1.240:6443 \
    --token xbtcem.rc4intnuv80o7otw \
	--discovery-token-ca-cert-hash sha256:181ea3313e3542f5c1791eec3e9b564435946203845b5eac793279df5779eea1 \
	--control-plane \
	--certificate-key 31da1221d1ed5a68f583fa79657389470489bb11cce86a8721e99c7c3c3e9612
...
Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.1.240:6443 \
    --token xbtcem.rc4intnuv80o7otw \
	--discovery-token-ca-cert-hash sha256:181ea3313e3542f5c1791eec3e9b564435946203845b5eac793279df5779eea1

-------------------

$ sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config


$ kubectl get pod -n kube-system -l component=kube-apiserver -o json | jq '.items[].metadata.annotations'
{
  "kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint": "192.168.1.230:6443",
  "kubernetes.io/config.hash": "fc1ab79053c39491499a846dcbafa12a",
  "kubernetes.io/config.mirror": "fc1ab79053c39491499a846dcbafa12a",
  "kubernetes.io/config.seen": "2025-04-20T03:23:26.497056380Z",
  "kubernetes.io/config.source": "file"
}

$ kubectl get pod -n kube-system -l component=etcd -o json | jq '.items[].metadata.annotations'
{
  "kubeadm.kubernetes.io/etcd.advertise-client-urls": "https://192.168.1.230:2379",
  "kubernetes.io/config.hash": "48aad3771145e20c991c1f6a9cc572f4",
  "kubernetes.io/config.mirror": "48aad3771145e20c991c1f6a9cc572f4",
  "kubernetes.io/config.seen": "2025-04-20T03:23:26.497055322Z",
  "kubernetes.io/config.source": "file"
}


=> Ok c'est la bonne ip pour api et etcd


On peut le voir ici :



Avec

$ sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml 
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 192.168.1.230:6443
  creationTimestamp: null
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=192.168.1.230
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction
    - --enable-bootstrap-token-auth=true
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
    - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
    - --requestheader-allowed-names=front-proxy-client
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
    - --requestheader-extra-headers-prefix=X-Remote-Extra-
    - --requestheader-group-headers=X-Remote-Group
    - --requestheader-username-headers=X-Remote-User
    - --secure-port=6443
    - --service-account-issuer=https://kubernetes.default.svc.cluster.local
    - --service-account-key-file=/etc/kubernetes/pki/sa.pub
    - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
    - --service-cluster-ip-range=10.96.0.0/12
    - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key

=> adresse ip ok !


$ sudo cat /etc/kubernetes/manifests/etcd.yaml 
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/etcd.advertise-client-urls: https://192.168.1.230:2379
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://192.168.1.230:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --experimental-initial-corrupt-check=true
    - --experimental-watch-progress-notify-interval=5s
    - --initial-advertise-peer-urls=https://192.168.1.230:2380
    - --initial-cluster=k8sm-controlplane01=https://192.168.1.230:2380
    - --key-file=/etc/kubernetes/pki/etcd/server.key
    - --listen-client-urls=https://127.0.0.1:2379,https://192.168.1.230:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.1.230:2380
    - --name=k8sm-controlplane01
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt



------------------------

Sur le controlplane02:

On attache kubelet sur la bonne interface :

$ echo "KUBELET_EXTRA_ARGS=--node-ip=192.168.1.231" > /etc/default/kubelet

On relance kubelet :

systemctl daemon-reexec
systemctl restart kubelet

$ sudo kubeadm reset -f


$ sudo kubeadm join 192.168.1.240:6443 --token xbtcem.rc4intnuv80o7otw \
	--discovery-token-ca-cert-hash sha256:181ea3313e3542f5c1791eec3e9b564435946203845b5eac793279df5779eea1 \
	--control-plane --certificate-key 31da1221d1ed5a68f583fa79657389470489bb11cce86a8721e99c7c3c3e9612 \
	--apiserver-advertise-address "192.168.1.231"
	
[preflight] Running pre-flight checks
[preflight] Reading configuration from the "kubeadm-config" ConfigMap in namespace "kube-system"...
[preflight] Use 'kubeadm init phase upload-config --config your-config.yaml' to re-upload it.
[preflight] Running pre-flight checks before initializing the new control plane instance
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action beforehand using 'kubeadm config images pull'
[download-certs] Downloading the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
[download-certs] Saving the certificates to the folder: "/etc/kubernetes/pki"
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8sm-controlplane02 localhost] and IPs [192.168.1.231 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8sm-controlplane02 localhost] and IPs [192.168.1.231 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8sm-controlplane02 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.1.231 192.168.1.240]
[certs] Valid certificates and keys now exist in "/etc/kubernetes/pki"
[certs] Using the existing "sa" key
[kubeconfig] Generating kubeconfig files
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[check-etcd] Checking that the etcd cluster is healthy
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-check] Waiting for a healthy kubelet at http://127.0.0.1:10248/healthz. This can take up to 4m0s
[kubelet-check] The kubelet is healthy after 501.163447ms
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap
[etcd] Announced new etcd member joining to the existing etcd cluster
[etcd] Creating static Pod manifest for "etcd"
{"level":"warn","ts":"2025-04-20T03:29:45.153695Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000320000/192.168.1.230:2379","attempt":0,"error":"rpc error: code = FailedPrecondition desc = etcdserver: can only promote a learner member which is in sync with leader"}
{"level":"warn","ts":"2025-04-20T03:29:45.668009Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000320000/192.168.1.230:2379","attempt":0,"error":"rpc error: code = FailedPrecondition desc = etcdserver: can only promote a learner member which is in sync with leader"}
{"level":"warn","ts":"2025-04-20T03:29:46.159904Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000320000/192.168.1.230:2379","attempt":0,"error":"rpc error: code = FailedPrecondition desc = etcdserver: can only promote a learner member which is in sync with leader"}
{"level":"warn","ts":"2025-04-20T03:29:46.654416Z","logger":"etcd-client","caller":"v3@v3.5.16/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000320000/192.168.1.230:2379","attempt":0,"error":"rpc error: code = Unavailable desc = etcdserver: rpc not supported for learner"}
[etcd] Waiting for the new etcd member to join the cluster. This can take up to 40s
[mark-control-plane] Marking the node k8sm-controlplane02 as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node k8sm-controlplane02 as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]

This node has joined the cluster and a new control plane instance was created:

* Certificate signing request was sent to apiserver and approval was received.
* The Kubelet was informed of the new secure connection details.
* Control plane label and taint were applied to the new node.
* The Kubernetes control plane instances scaled up.
* A new etcd member was added to the local/stacked etcd cluster.

To start administering your cluster from this node, you need to run the following as a regular user:

	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config

Run 'kubectl get nodes' to see this node join the cluster.
---------------------------


$ sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config


$ kubectl get pod -n kube-system -l component=kube-apiserver -o json | jq '.items[].metadata.annotations'
{
  "kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint": "192.168.1.230:6443",
  "kubernetes.io/config.hash": "fc1ab79053c39491499a846dcbafa12a",
  "kubernetes.io/config.mirror": "fc1ab79053c39491499a846dcbafa12a",
  "kubernetes.io/config.seen": "2025-04-20T03:23:26.497056380Z",
  "kubernetes.io/config.source": "file"
}


$ kubectl get pod -n kube-system -l component=etcd -o json | jq '.items[].metadata.annotations'
{
  "kubeadm.kubernetes.io/etcd.advertise-client-urls": "https://192.168.1.230:2379",
  "kubernetes.io/config.hash": "48aad3771145e20c991c1f6a9cc572f4",
  "kubernetes.io/config.mirror": "48aad3771145e20c991c1f6a9cc572f4",
  "kubernetes.io/config.seen": "2025-04-20T03:23:26.497055322Z",
  "kubernetes.io/config.source": "file"
}

=> IP Ok !



Avec :

$ sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml 
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 192.168.1.231:6443
  creationTimestamp: null
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=192.168.1.231
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction
    - --enable-bootstrap-token-auth=true
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
    - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
    - --requestheader-allowed-names=front-proxy-client
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
    - --requestheader-extra-headers-prefix=X-Remote-Extra-
    - --requestheader-group-headers=X-Remote-Group
    - --requestheader-username-headers=X-Remote-User
    - --secure-port=6443
    - --service-account-issuer=https://kubernetes.default.svc.cluster.local
    - --service-account-key-file=/etc/kubernetes/pki/sa.pub
    - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
    - --service-cluster-ip-range=10.96.0.0/12
    - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key


$ sudo cat /etc/kubernetes/manifests/etcd.yaml 
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/etcd.advertise-client-urls: https://192.168.1.231:2379
  creationTimestamp: null
  labels:
    component: etcd
    tier: control-plane
  name: etcd
  namespace: kube-system
spec:
  containers:
  - command:
    - etcd
    - --advertise-client-urls=https://192.168.1.231:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --experimental-initial-corrupt-check=true
    - --experimental-watch-progress-notify-interval=5s
    - --initial-advertise-peer-urls=https://192.168.1.231:2380
    - --initial-cluster=k8sm-controlplane02=https://192.168.1.231:2380,k8sm-controlplane01=https://192.168.1.230:2380
    - --initial-cluster-state=existing
    - --key-file=/etc/kubernetes/pki/etcd/server.key
    - --listen-client-urls=https://127.0.0.1:2379,https://192.168.1.231:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.1.231:2380
    - --name=k8sm-controlplane02
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt


On refait les même vérif sur le control-plane01

$ kubectl get pod -n kube-system -l component=kube-apiserver -o json | jq '.items[].metadata.annotations'
{
  "kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint": "192.168.1.230:6443",
  "kubernetes.io/config.hash": "fc1ab79053c39491499a846dcbafa12a",
  "kubernetes.io/config.mirror": "fc1ab79053c39491499a846dcbafa12a",
  "kubernetes.io/config.seen": "2025-04-20T03:23:26.497056380Z",
  "kubernetes.io/config.source": "file"
}
{
  "kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint": "192.168.1.231:6443",
  "kubernetes.io/config.hash": "5437aa36329bdd67249828fcd34b3f15",
  "kubernetes.io/config.mirror": "5437aa36329bdd67249828fcd34b3f15",
  "kubernetes.io/config.seen": "2025-04-20T03:29:44.549919835Z",
  "kubernetes.io/config.source": "file"
}
vagrant@k8sm-controlplane01:~$ kubectl get pod -n kube-system -l component=etcd -o json | jq '.items[].metadata.annotations'
{
  "kubeadm.kubernetes.io/etcd.advertise-client-urls": "https://192.168.1.230:2379",
  "kubernetes.io/config.hash": "48aad3771145e20c991c1f6a9cc572f4",
  "kubernetes.io/config.mirror": "48aad3771145e20c991c1f6a9cc572f4",
  "kubernetes.io/config.seen": "2025-04-20T03:23:26.497055322Z",
  "kubernetes.io/config.source": "file"
}
{
  "kubeadm.kubernetes.io/etcd.advertise-client-urls": "https://192.168.1.231:2379",
  "kubernetes.io/config.hash": "d0b670036a56dae08c2b85c57340515a",
  "kubernetes.io/config.mirror": "d0b670036a56dae08c2b85c57340515a",
  "kubernetes.io/config.seen": "2025-04-20T03:29:45.135140044Z",
  "kubernetes.io/config.source": "file"
}

Vérification sur les 2 controlplanes :
Tu peux vérifier que les deux nœuds etcd sont bien membres et en bon état avec :

$ sudo ETCDCTL_API=3 etcdctl   --cacert=/etc/kubernetes/pki/etcd/ca.crt   --cert=/etc/kubernetes/pki/etcd/server.crt   --key=/etc/kubernetes/pki/etcd/server.key   --endpoints=https://127.0.0.1:2379 member list
41d2a383fac0a009, started, k8sm-controlplane02, https://192.168.1.231:2380, https://192.168.1.231:2379
445a7d567d5cea7f, started, k8sm-controlplane01, https://192.168.1.230:2380, https://192.168.1.230:2379

$ sudo ETCDCTL_API=3 etcdctl   --cacert=/etc/kubernetes/pki/etcd/ca.crt   --cert=/etc/kubernetes/pki/etcd/server.crt   --key=/etc/kubernetes/pki/etcd/server.key   --endpoints=https://127.0.0.1:2379 endpoint health
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 5.08191ms


Au bout de 1min :

$ k get nodes
NAME                  STATUS   ROLES           AGE     VERSION
k8sm-controlplane01   Ready    control-plane   3m38s   v1.32.3
k8sm-controlplane02   Ready    control-plane   62s     v1.32.3


------------------------------------------------------------------------------------------

Sur le worker :

On attache kubelet sur la bonne interface :

$ echo "KUBELET_EXTRA_ARGS=--node-ip=192.168.1.232" > /etc/default/kubelet

On relance kubelet :

systemctl daemon-reexec
systemctl restart kubelet


$ sudo kubeadm join 192.168.1.240:6443 --token 3le986.tfp0g21204sijkh3 \
  --discovery-token-ca-cert-hash sha256:6aa96c98e458a138d0b3885d5a15f91c89cffb8c503ff12f6aa7743c991be733



--------------------------------------------------------------------------------------------

Ensuite vérifications à faire sur le controplane

Comme le certificats ont été refait :
$ sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config

Adresse écoute ETCD => doit être en 192.168.1.xx ($MY_IP)

$ kubectl get pod -n kube-system -l component=etcd -o json | jq '.items[].metadata.annotations'
ou dans /etc/kubernetes/manifests/etcd.yaml => --advertise-client-url, --initial-advertise-peer-urls, --initial-cluster, --listen-client-urls, --listen-peer-urls
ou avec ps aux | grep etcd

Adresse écoute KUBE-APISERVER => doit être en 192.168.1.xx ($MY_IP)
$ kubectl get pod -n kube-system -l component=kube-apiserver -o json | jq '.items[].metadata.annotations'
ou dans /etc/kubernetes/manifests/kube-apiserver.yaml => --advertise-address=
ou avec ps aux | grep kube-api


Tu peux vérifier que les deux nœuds etcd sont bien membres et en bon état avec :

$ sudo ETCDCTL_API=3 etcdctl   --cacert=/etc/kubernetes/pki/etcd/ca.crt   --cert=/etc/kubernetes/pki/etcd/server.crt   --key=/etc/kubernetes/pki/etcd/server.key   --endpoints=https://127.0.0.1:2379 member list
445a7d567d5cea7f, started, k8sm-controlplane01, https://192.168.1.230:2380, https://192.168.1.230:2379
a9163f8f7fa09515, started, k8sm-controlplane02, https://192.168.1.231:2380, https://192.168.1.231:2379

$ sudo ETCDCTL_API=3 etcdctl   --cacert=/etc/kubernetes/pki/etcd/ca.crt   --cert=/etc/kubernetes/pki/etcd/server.crt   --key=/etc/kubernetes/pki/etcd/server.key   --endpoints=https://127.0.0.1:2379 endpoint health
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 6.008999ms

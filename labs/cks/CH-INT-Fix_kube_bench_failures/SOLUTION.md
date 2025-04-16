We can read at install :

✅ kube-bench installed successfully in /usr/local/bin and config in /etc/kube-bench/cfg 

If we do :

```
$ kube-bench help
...
      --config string                     config file (default is ./cfg/config.yaml)
  -D, --config-dir string                 config directory (default "/etc/kube-bench/cfg")
...
```

So no need to use `--config-dir`, the `cfg` is already install in `/etc/kube-bench`

We can run with vagrant account :

```
$ kube-bench run

error looking for file /var/lib/etcd/default.etcd: stat /var/lib/etcd/default.etcd: permission denied
```

=> we cannot run as vagrant user, let's try with `sudo` !

```
$ sudo kube-bench run
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
Warning: Kubernetes version was not auto-detected because kubectl could not connect to the Kubernetes server. This may be because the kubeconfig information is missing or has credentials that do not match the server. Assuming default version 1.18
[INFO] 1 Master Node Security Configuration
[INFO] 1.1 Master Node Configuration Files

```

We have a warning that indicates that kube-ben cannot auto-detect the kubernetes version (it uses kubectl and kubectl need a kubeconfig file, but root hgas no kubeconfig file). SO we pass it thought env variable

```
$ sudo KUBECONFIG=/home/vagrant/.kube/config kube-bench run
[INFO] 1 Control Plane Security Configuration
...
[FAIL] 1.1.12 Ensure that the etcd data directory ownership is set to etcd:etcd (Automated)
...
[INFO] 1.2 API Server
...
[FAIL] 1.2.5 Ensure that the --kubelet-certificate-authority argument is set as appropriate (Automated)
...
[FAIL] 1.2.18 Ensure that the --audit-log-maxbackup argument is set to 10 or as appropriate (Automated)
[FAIL] 1.2.19 Ensure that the --audit-log-maxsize argument is set to 100 or as appropriate (Automated)
...
[INFO] 1.3 Controller Manager
...
[FAIL] 1.3.2 Ensure that the --profiling argument is set to false (Automated)
...
[INFO] 2 Etcd Node Configuration
[INFO] 2 Etcd Node Configuration
[PASS] 2.1 Ensure that the --cert-file and --key-file arguments are set as appropriate (Automated)
[PASS] 2.2 Ensure that the --client-cert-auth argument is set to true (Automated)
...

[INFO] 3 Control Plane Configuration
[INFO] 3.1 Authentication and Authorization
[WARN] 3.1.1 Client certificate authentication should not be used for users (Manual)
[WARN] 3.1.2 Service account token authentication should not be used for users (Manual)
[WARN] 3.1.3 Bootstrap token authentication should not be used for users (Manual)
[INFO] 3.2 Logging
[PASS] 3.2.1 Ensure that a minimal audit policy is created (Manual)
[WARN] 3.2.2 Ensure that the audit policy covers key security concerns (Manual)

== Remediations controlplane ==
3.1.1 Alternative mechanisms provided by Kubernetes such as the use of OIDC should be
implemented in place of client certificates.

3.1.2 Alternative mechanisms provided by Kubernetes such as the use of OIDC should be implemented
in place of service account tokens.

3.1.3 Alternative mechanisms provided by Kubernetes such as the use of OIDC should be implemented
in place of bootstrap tokens.

3.2.2 Review the audit policy provided for the cluster and ensure that it covers
at least the following areas,
- Access to Secrets managed by the cluster. Care should be taken to only
  log Metadata for requests to Secrets, ConfigMaps, and TokenReviews, in
  order to avoid risk of logging sensitive data.
- Modification of Pod and Deployment objects.
- Use of `pods/exec`, `pods/portforward`, `pods/proxy` and `services/proxy`.
For most requests, minimally logging at the Metadata level is recommended
(the most basic level of logging).


== Summary controlplane ==
1 checks PASS
0 checks FAIL
4 checks WARN
0 checks INFO

[INFO] 4 Worker Node Security Configuration
[INFO] 4.1 Worker Node Configuration Files
[FAIL] 4.1.1 Ensure that the kubelet service file permissions are set to 600 or more restrictive (Automated)
[PASS] 4.1.2 Ensure that the kubelet service file ownership is set to root:root (Automated)
[WARN] 4.1.3 If proxy kubeconfig file exists ensure permissions are set to 600 or more restrictive (Manual)
[WARN] 4.1.4 If proxy kubeconfig file exists ensure ownership is set to root:root (Manual)
[PASS] 4.1.5 Ensure that the --kubeconfig kubelet.conf file permissions are set to 600 or more restrictive (Automated)
[PASS] 4.1.6 Ensure that the --kubeconfig kubelet.conf file ownership is set to root:root (Automated)
[WARN] 4.1.7 Ensure that the certificate authorities file permissions are set to 600 or more restrictive (Manual)
[PASS] 4.1.8 Ensure that the client certificate authorities file ownership is set to root:root (Manual)
[FAIL] 4.1.9 If the kubelet config.yaml configuration file is being used validate permissions set to 600 or more restrictive (Automated)
[PASS] 4.1.10 If the kubelet config.yaml configuration file is being used validate file ownership is set to root:root (Automated)
[INFO] 4.2 Kubelet
[PASS] 4.2.1 Ensure that the --anonymous-auth argument is set to false (Automated)
[PASS] 4.2.2 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
[PASS] 4.2.3 Ensure that the --client-ca-file argument is set as appropriate (Automated)
[PASS] 4.2.4 Verify that the --read-only-port argument is set to 0 (Manual)
[PASS] 4.2.5 Ensure that the --streaming-connection-idle-timeout argument is not set to 0 (Manual)
[PASS] 4.2.6 Ensure that the --make-iptables-util-chains argument is set to true (Automated)
[PASS] 4.2.7 Ensure that the --hostname-override argument is not set (Manual)
[PASS] 4.2.8 Ensure that the eventRecordQPS argument is set to a level which ensures appropriate event capture (Manual)
[WARN] 4.2.9 Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Manual)
[PASS] 4.2.10 Ensure that the --rotate-certificates argument is not set to false (Automated)
[PASS] 4.2.11 Verify that the RotateKubeletServerCertificate argument is set to true (Manual)
[WARN] 4.2.12 Ensure that the Kubelet only makes use of Strong Cryptographic Ciphers (Manual)
[WARN] 4.2.13 Ensure that a limit is set on pod PIDs (Manual)
[INFO] 4.3 kube-proxy
[PASS] 4.3.1 Ensure that the kube-proxy metrics service is bound to localhost (Automated)

== Remediations node ==
4.1.1 Run the below command (based on the file location on your system) on the each worker node.
For example, chmod 600 /lib/systemd/system/kubelet.service

4.1.3 Run the below command (based on the file location on your system) on the each worker node.
For example,
chmod 600 /etc/kubernetes/proxy.conf

4.1.4 Run the below command (based on the file location on your system) on the each worker node.
For example, chown root:root /etc/kubernetes/proxy.conf

4.1.7 Run the following command to modify the file permissions of the
--client-ca-file chmod 600 <filename>

4.1.9 Run the following command (using the config file location identified in the Audit step)
chmod 600 /var/lib/kubelet/config.yaml

4.2.9 If using a Kubelet config file, edit the file to set `tlsCertFile` to the location
of the certificate file to use to identify this Kubelet, and `tlsPrivateKeyFile`
to the location of the corresponding private key file.
If using command line arguments, edit the kubelet service file
/lib/systemd/system/kubelet.service on each worker node and
set the below parameters in KUBELET_CERTIFICATE_ARGS variable.
--tls-cert-file=<path/to/tls-certificate-file>
--tls-private-key-file=<path/to/tls-key-file>
Based on your system, restart the kubelet service. For example,
systemctl daemon-reload
systemctl restart kubelet.service

4.2.12 If using a Kubelet config file, edit the file to set `tlsCipherSuites` to
TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256
or to a subset of these values.
If using executable arguments, edit the kubelet service file
/lib/systemd/system/kubelet.service on each worker node and
set the --tls-cipher-suites parameter as follows, or to a subset of these values.
--tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256
Based on your system, restart the kubelet service. For example:
systemctl daemon-reload
systemctl restart kubelet.service

4.2.13 Decide on an appropriate level for this parameter and set it,
either via the --pod-max-pids command line parameter or the PodPidsLimit configuration file setting.


== Summary node ==
16 checks PASS
2 checks FAIL
6 checks WARN
0 checks INFO

[INFO] 5 Kubernetes Policies
[INFO] 5.1 RBAC and Service Accounts
[FAIL] 5.1.1 Ensure that the cluster-admin role is only used where required (Automated)
[PASS] 5.1.2 Minimize access to secrets (Automated)
[FAIL] 5.1.3 Minimize wildcard use in Roles and ClusterRoles (Automated)
[PASS] 5.1.4 Minimize access to create pods (Automated)
[FAIL] 5.1.5 Ensure that default service accounts are not actively used (Automated)
[FAIL] 5.1.6 Ensure that Service Account Tokens are only mounted where necessary (Automated)
[WARN] 5.1.7 Avoid use of system:masters group (Manual)
[WARN] 5.1.8 Limit use of the Bind, Impersonate and Escalate permissions in the Kubernetes cluster (Manual)
[WARN] 5.1.9 Minimize access to create persistent volumes (Manual)
[WARN] 5.1.10 Minimize access to the proxy sub-resource of nodes (Manual)
[WARN] 5.1.11 Minimize access to the approval sub-resource of certificatesigningrequests objects (Manual)
[WARN] 5.1.12 Minimize access to webhook configuration objects (Manual)
[WARN] 5.1.13 Minimize access to the service account token creation (Manual)
[INFO] 5.2 Pod Security Standards
[WARN] 5.2.1 Ensure that the cluster has at least one active policy control mechanism in place (Manual)
[WARN] 5.2.2 Minimize the admission of privileged containers (Manual)
[PASS] 5.2.3 Minimize the admission of containers wishing to share the host process ID namespace (Manual)
[PASS] 5.2.4 Minimize the admission of containers wishing to share the host IPC namespace (Manual)
[WARN] 5.2.5 Minimize the admission of containers wishing to share the host network namespace (Manual)
[WARN] 5.2.6 Minimize the admission of containers with allowPrivilegeEscalation (Manual)
[WARN] 5.2.7 Minimize the admission of root containers (Manual)
[WARN] 5.2.8 Minimize the admission of containers with the NET_RAW capability (Manual)
[WARN] 5.2.9 Minimize the admission of containers with added capabilities (Manual)
[WARN] 5.2.10 Minimize the admission of containers with capabilities assigned (Manual)
[WARN] 5.2.11 Minimize the admission of Windows HostProcess containers (Manual)
[WARN] 5.2.12 Minimize the admission of HostPath volumes (Manual)
[WARN] 5.2.13 Minimize the admission of containers which use HostPorts (Manual)
[INFO] 5.3 Network Policies and CNI
[WARN] 5.3.1 Ensure that the CNI in use supports NetworkPolicies (Manual)
[WARN] 5.3.2 Ensure that all Namespaces have NetworkPolicies defined (Manual)
[INFO] 5.4 Secrets Management
[WARN] 5.4.1 Prefer using Secrets as files over Secrets as environment variables (Manual)
[WARN] 5.4.2 Consider external secret storage (Manual)
[INFO] 5.5 Extensible Admission Control
[WARN] 5.5.1 Configure Image Provenance using ImagePolicyWebhook admission controller (Manual)
[INFO] 5.7 General Policies
[WARN] 5.7.1 Create administrative boundaries between resources using namespaces (Manual)
[WARN] 5.7.2 Ensure that the seccomp profile is set to docker/default in your Pod definitions (Manual)
[WARN] 5.7.3 Apply SecurityContext to your Pods and Containers (Manual)
[WARN] 5.7.4 The default namespace should not be used (Manual)

== Remediations policies ==
5.1.1 Identify all clusterrolebindings to the cluster-admin role. Check if they are used and
if they need this role or if they could use a role with fewer privileges.
Where possible, first bind users to a lower privileged role and then remove the
clusterrolebinding to the cluster-admin role : kubectl delete clusterrolebinding [name]
Condition: is_compliant is false if rolename is not cluster-admin and rolebinding is cluster-admin.

5.1.3 Where possible replace any use of wildcards ["*"] in roles and clusterroles with specific
objects or actions.
Condition: role_is_compliant is false if ["*"] is found in rules.
Condition: clusterrole_is_compliant is false if ["*"] is found in rules.

5.1.5 Create explicit service accounts wherever a Kubernetes workload requires specific access
to the Kubernetes API server.
Modify the configuration of each default service account to include this value
`automountServiceAccountToken: false`.

5.1.6 Modify the definition of ServiceAccounts and Pods which do not need to mount service
account tokens to disable it, with `automountServiceAccountToken: false`.
If both the ServiceAccount and the Pod's .spec specify a value for automountServiceAccountToken, the Pod spec takes precedence.
Condition: Pod is_compliant to true when
  - ServiceAccount is automountServiceAccountToken: false and Pod is automountServiceAccountToken: false or notset
  - ServiceAccount is automountServiceAccountToken: true notset and Pod is automountServiceAccountToken: false

5.1.7 Remove the system:masters group from all users in the cluster.

5.1.8 Where possible, remove the impersonate, bind and escalate rights from subjects.

5.1.9 Where possible, remove create access to PersistentVolume objects in the cluster.

5.1.10 Where possible, remove access to the proxy sub-resource of node objects.

5.1.11 Where possible, remove access to the approval sub-resource of certificatesigningrequests objects.

5.1.12 Where possible, remove access to the validatingwebhookconfigurations or mutatingwebhookconfigurations objects

5.1.13 Where possible, remove access to the token sub-resource of serviceaccount objects.

5.2.1 Ensure that either Pod Security Admission or an external policy control system is in place
for every namespace which contains user workloads.

5.2.2 Add policies to each namespace in the cluster which has user workloads to restrict the
admission of privileged containers.
Audit: the audit list all pods' containers to retrieve their .securityContext.privileged value.
Condition: is_compliant is false if container's `.securityContext.privileged` is set to `true`.
Default: by default, there are no restrictions on the creation of privileged containers.

5.2.5 Add policies to each namespace in the cluster which has user workloads to restrict the
admission of `hostNetwork` containers.
Audit: the audit retrieves each Pod' spec.hostNetwork.
Condition: is_compliant is false if Pod's spec.hostNetwork is set to `true`.
Default: by default, there are no restrictions on the creation of hostNetwork containers.

5.2.6 Add policies to each namespace in the cluster which has user workloads to restrict the
admission of containers with `.securityContext.allowPrivilegeEscalation` set to `true`.
Audit: the audit retrieves each Pod's container(s) `.securityContext.allowPrivilegeEscalation`.
Condition: is_compliant is false if container's `.securityContext.allowPrivilegeEscalation` is set to `true`.
Default: If notset, privilege escalation is allowed (default to true). However if PSP/PSA is used with a `restricted` profile,
privilege escalation is explicitly disallowed unless configured otherwise.

5.2.7 Create a policy for each namespace in the cluster, ensuring that either `MustRunAsNonRoot`
or `MustRunAs` with the range of UIDs not including 0, is set.

5.2.8 Add policies to each namespace in the cluster which has user workloads to restrict the
admission of containers with the `NET_RAW` capability.

5.2.9 Ensure that `allowedCapabilities` is not present in policies for the cluster unless
it is set to an empty array.
Audit: the audit retrieves each Pod's container(s) added capabilities.
Condition: is_compliant is false if added capabilities are added for a given container.
Default: Containers run with a default set of capabilities as assigned by the Container Runtime.

5.2.10 Review the use of capabilites in applications running on your cluster. Where a namespace
contains applications which do not require any Linux capabities to operate consider adding
a PSP which forbids the admission of containers which do not drop all capabilities.

5.2.11 Add policies to each namespace in the cluster which has user workloads to restrict the
admission of containers that have `.securityContext.windowsOptions.hostProcess` set to `true`.

5.2.12 Add policies to each namespace in the cluster which has user workloads to restrict the
admission of containers with `hostPath` volumes.

5.2.13 Add policies to each namespace in the cluster which has user workloads to restrict the
admission of containers which use `hostPort` sections.

5.3.1 If the CNI plugin in use does not support network policies, consideration should be given to
making use of a different plugin, or finding an alternate mechanism for restricting traffic
in the Kubernetes cluster.

5.3.2 Follow the documentation and create NetworkPolicy objects as you need them.

5.4.1 If possible, rewrite application code to read Secrets from mounted secret files, rather than
from environment variables.

5.4.2 Refer to the Secrets management options offered by your cloud provider or a third-party
secrets management solution.

5.5.1 Follow the Kubernetes documentation and setup image provenance.

5.7.1 Follow the documentation and create namespaces for objects in your deployment as you need
them.

5.7.2 Use `securityContext` to enable the docker/default seccomp profile in your pod definitions.
An example is as below:
  securityContext:
    seccompProfile:
      type: RuntimeDefault

5.7.3 Follow the Kubernetes documentation and apply SecurityContexts to your Pods. For a
suggested list of SecurityContexts, you may refer to the CIS Security Benchmark for Docker
Containers.

5.7.4 Ensure that namespaces are created to allow for appropriate segregation of Kubernetes
resources and that all new resources are created in a specific namespace.


== Summary policies ==
4 checks PASS
4 checks FAIL
27 checks WARN
0 checks INFO

== Summary total ==
71 checks PASS
11 checks FAIL
48 checks WARN
0 checks INFO
```
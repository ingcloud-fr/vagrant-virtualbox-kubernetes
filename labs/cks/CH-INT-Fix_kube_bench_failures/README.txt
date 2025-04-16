🛡️ Lab: Fix kube-bench Failures Across Control Plane and Kubelet

🧠 Difficulty: Intermediate  
⏱️ Estimated Time: 40–50 minutes

🎯 Goal:  
Use `kube-bench` to detect and remediate CIS benchmark violations in Kubernetes core components — including the kubelet.

📌 Your mission:
1. Run `kube-bench` on the control plane node using the installed tool.
2. Focus on fixing **selected violations** in each component:
   - ✅ etcd:
     - 2.1: `--cert-file` and `--key-file` must be set
     - 2.2: `--client-cert-auth=true`
     - 2.3: `--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt`
   - ✅ kube-apiserver:
     - 1.2.7 / 1.2.8: `--authorization-mode=Node,RBAC`
     - 1.2.9: Ensure `AlwaysAllow` is not used
     - 1.2.22: `--anonymous-auth=false`
     - 1.2.23: `--etcd-certfile` and `--etcd-keyfile`
     - 1.2.25 / 1.2.26: `--tls-cert-file` and `--tls-private-key-file`
   - ✅ kube-controller-manager:
     - 1.3.2: `--use-service-account-credentials=true`
     - 1.3.3: `--root-ca-file=/etc/kubernetes/pki/ca.crt`
   - ✅ kube-scheduler:
     - 1.4.1: `--profiling=false`
   - ✅ kubelet:
     - 4.2.1: `--authentication-token-webhook=true`
     - 4.2.2: `--authorization-mode=Webhook`

3. Use the provided `deploy.sh` to apply secure settings.
4. After modifications, re-run `kube-bench` and confirm all checks are passing.
5. Use `reset.sh` to revert everything to the insecure baseline.

🧰 Context:
- Control plane manifests: `/etc/kubernetes/manifests/`
- Kubelet config file: `/var/lib/kubelet/config.yaml`
- kube-bench config: `/opt/kube-bench/cfg`
- Backup: `/etc/kubernetes/manifests/backup/`

📦 Tip to extract failed checks only:
```bash
kube-bench --json | jq -r '.[] | .tests[] | .results[] | select(.status=="FAIL") | "\(.test_number): \(.test_desc)"'


✅ Expected Result:
- After applying your fixes, the 6 targeted checks should no longer appear as FAIL in the kube-bench output.

🧹 A `reset.sh` script is available to clean the cluster between attempts.
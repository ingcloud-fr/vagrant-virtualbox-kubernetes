# 🛡️ Certified Kubernetes Security Specialist (CKS) - Official Exam Topics

## 1. CS : Cluster Setup (10%)
- Use of secure container runtimes (e.g., containerd, CRI-O)
- Kubelet configuration (certificates, secure flags)
- Disable unused ports and services
- Secure CNI configuration and network boundaries

## 2. CH : Cluster Hardening (15%)
- Disable insecure ports on API Server and Kubelet
- Restrict Kubelet access and functionality
- Protect sensitive files and secrets (kubeconfig, etcd, etc.)
- Limit container capabilities (Linux capabilities, seccomp, etc.)

## 3. SH : System Hardening (15%)
- Harden host OS:
  - Firewall configuration (UFW, iptables)
  - AppArmor/SELinux setup
  - Kernel module restrictions
- Review and restrict file permissions
- Audit Docker or containerd configuration
- Remove unnecessary services and tools

## 4. MMV : Minimize Microservice Vulnerabilities (20%)
- Container image scanning (e.g., Trivy, Clair)
- Use of signed or trusted base images
- Enforce securityContext (readOnlyRootFilesystem, drop capabilities, etc.)
- Manage and protect Kubernetes Secrets securely

## 5. SCS : Supply Chain Security (20%)
- Image signing and verification (e.g., Cosign, Notary)
- Enforce policies using OPA Gatekeeper
- Use Admission Controllers (e.g., PodSecurity, ImagePolicyWebhook)
- Validate Kubernetes manifests for security compliance

## 6. MLR : Monitoring, Logging & Runtime Security (20%)
- Setup and configure tools like Falco, Auditd, Tracee
- Integrate with observability stack (Prometheus, Grafana, Loki)
- Detect suspicious activity (exec, privilege escalation, file writes, etc.)
- Analyze and audit cluster logs for security events

---

> This document outlines the official CKS exam curriculum maintained by the CNCF. Candidates should be familiar with both theoretical knowledge and hands-on application of these topics.
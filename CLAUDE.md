# GitHub Actions Runners Repository

## Purpose

This repository manages self-hosted GitHub Action runners deployed on the home lab MicroK8s cluster using Actions Runner Controller (ARC).

## Architecture

- **Deployment Method:** Ansible playbooks + Helm charts
- **Target Cluster:** MicroK8s (5-node Dell server cluster)
- **Runner Scaling:** 0-20 runners (auto-scaling based on workflow demand)
- **Container Mode:** Docker-in-Docker (DinD) for Docker builds

## Repository Structure

```
github-actions-runners/
├── ansible/                 # Deployment automation
│   ├── inventory/           # Ansible inventory
│   ├── playbooks/           # Deploy and reset playbooks
│   ├── roles/               # arc-controller, arc-runner-set
│   └── group_vars/          # Variables and vault
├── helm-values/             # Helm chart values
├── images/runner/           # Custom runner Dockerfile
├── kubernetes/              # K8s manifests (namespaces, storage)
├── scripts/                 # Setup documentation
└── .github/workflows/       # CI for building runner image
```

## Operations

### Deploy ARC and Runners

```bash
cd ansible
ansible-playbook playbooks/deploy-arc.yml
```

### Update Runner Image

After modifying `images/runner/Dockerfile`:
1. Push changes - GitHub Actions will build and push to GHCR
2. Redeploy runner set:
   ```bash
   ansible-playbook playbooks/deploy-arc.yml --tags runner-set
   ```

### Reset/Teardown

```bash
ansible-playbook playbooks/reset-arc.yml
```

### View Runner Status

```bash
kubectl get pods -n arc-runners
kubectl get hra -n arc-runners  # Horizontal Runner Autoscaler
```

## GitHub App Credentials

**NEVER commit credentials to this repository.**

Credentials are stored in:
- `ansible/group_vars/all/vault.yml` (Ansible Vault encrypted)

Required values:
- `github_app_id`: GitHub App ID
- `github_app_installation_id`: Installation ID
- `github_app_private_key`: Private key content (PEM format)

## Adding New Tools to Runners

1. Edit `images/runner/Dockerfile`
2. Add installation commands for new packages
3. Commit and push
4. Wait for GitHub Actions to rebuild image
5. Run: `ansible-playbook playbooks/deploy-arc.yml --tags runner-set`

## Troubleshooting

### Runners not appearing in GitHub

1. Check controller logs: `kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set-controller`
2. Verify GitHub App secret: `kubectl get secret github-app-secret -n arc-runners`
3. Check runner set status: `kubectl describe runnerscaleset -n arc-runners`

### Runner pods failing

1. Check pod logs: `kubectl logs -n arc-runners <pod-name>`
2. Describe pod: `kubectl describe pod -n arc-runners <pod-name>`
3. Check resource usage: `kubectl top pods -n arc-runners`

### Docker builds failing in runners

Verify DinD is working:
1. Check dind sidecar logs: `kubectl logs -n arc-runners <pod-name> -c dind`
2. Ensure privileged mode is enabled in values

## Key Configuration Files

| File | Purpose |
|------|---------|
| `helm-values/arc-runner-set.yaml` | Runner scaling, resources, DinD config |
| `ansible/group_vars/all/vars.yml` | Shared variables |
| `ansible/group_vars/all/vault.yml` | Encrypted credentials |
| `images/runner/Dockerfile` | Custom runner image definition |

## Security Notes

- GitHub App credentials are Ansible Vault encrypted
- DinD runs in privileged mode (isolated container)
- Runners scale to 0 when idle (no persistent attack surface)
- Namespaces separated: `arc-systems` (controller), `arc-runners` (workloads)

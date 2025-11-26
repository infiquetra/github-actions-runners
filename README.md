# GitHub Actions Self-Hosted Runners

Self-hosted GitHub Action runners deployed on MicroK8s using [Actions Runner Controller (ARC)](https://github.com/actions/actions-runner-controller).

## Features

- **Auto-scaling:** 0-20 runners scale based on workflow demand
- **Custom Image:** Pre-installed Python, Dart, Flutter, AWS CLI, and more
- **Docker Builds:** Docker-in-Docker support for container workflows
- **GitOps Ready:** Ansible + Helm deployment for reproducibility

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    MicroK8s Cluster                         │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │  arc-systems    │    │         arc-runners             │ │
│  │  ┌───────────┐  │    │  ┌───────┐ ┌───────┐ ┌───────┐  │ │
│  │  │Controller │  │───▶│  │Runner │ │Runner │ │Runner │  │ │
│  │  │ (HA x2)   │  │    │  │  Pod  │ │  Pod  │ │  Pod  │  │ │
│  │  └───────────┘  │    │  └───────┘ └───────┘ └───────┘  │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   github.com    │
                    │   infiquetra    │
                    │   organization  │
                    └─────────────────┘
```

## Prerequisites

- MicroK8s cluster with Helm addon enabled
- `kubectl` configured to access the cluster
- Ansible installed locally
- GitHub App created in the infiquetra organization

## Quick Start

### 1. Create GitHub App

Follow the instructions in [scripts/setup-github-app.md](scripts/setup-github-app.md).

### 2. Configure Credentials

```bash
# Create vault password file
echo "your-vault-password" > ~/.vault_pass

# Create encrypted vault file
ansible-vault create ansible/group_vars/all/vault.yml
```

Add the following to the vault:
```yaml
github_app_id: "123456"
github_app_installation_id: "12345678"
github_app_private_key: |
  -----BEGIN RSA PRIVATE KEY-----
  ...your private key...
  -----END RSA PRIVATE KEY-----
```

### 3. Deploy

```bash
cd ansible
ansible-playbook playbooks/deploy-arc.yml --vault-password-file ~/.vault_pass
```

### 4. Verify

```bash
kubectl get pods -n arc-systems   # Controller should be running
kubectl get pods -n arc-runners   # Runners appear when workflows run
```

## Using the Runners

In your GitHub Actions workflow, specify the runner:

```yaml
jobs:
  build:
    runs-on: infiquetra-arc-runner
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: echo "Running on self-hosted runner!"
```

## Pre-installed Tools

| Tool | Version | Notes |
|------|---------|-------|
| Python | 3.12+ | With uv package manager |
| Dart | Latest stable | |
| Flutter | Latest stable | |
| AWS CLI | v2 | |
| Node.js | 20.x | |
| Docker | Latest | Via Docker-in-Docker |

## Operations

| Command | Description |
|---------|-------------|
| `ansible-playbook playbooks/deploy-arc.yml` | Deploy or update ARC |
| `ansible-playbook playbooks/deploy-arc.yml --tags runner-set` | Update runners only |
| `ansible-playbook playbooks/reset-arc.yml` | Remove ARC completely |

## Adding Tools

1. Edit `images/runner/Dockerfile`
2. Push changes (GitHub Actions builds automatically)
3. Redeploy: `ansible-playbook playbooks/deploy-arc.yml --tags runner-set`

## Repository Structure

```
.
├── ansible/
│   ├── inventory/hosts.yml         # Ansible inventory
│   ├── playbooks/
│   │   ├── deploy-arc.yml          # Main deployment
│   │   └── reset-arc.yml           # Teardown
│   ├── roles/
│   │   ├── arc-controller/         # ARC controller deployment
│   │   └── arc-runner-set/         # Runner scale set deployment
│   └── group_vars/all/
│       ├── vars.yml                # Shared variables
│       └── vault.yml               # Encrypted credentials
├── helm-values/
│   ├── arc-controller.yaml         # Controller Helm values
│   └── arc-runner-set.yaml         # Runner Helm values
├── images/runner/
│   └── Dockerfile                  # Custom runner image
├── kubernetes/
│   ├── namespaces/                 # Namespace definitions
│   └── storage/                    # PVC for caches
└── scripts/
    └── setup-github-app.md         # GitHub App setup guide
```

## Troubleshooting

See [CLAUDE.md](CLAUDE.md) for detailed troubleshooting steps.

## License

MIT

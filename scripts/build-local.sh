#!/usr/bin/env bash
# Build and push runner image locally for faster iteration
# Usage: ./scripts/build-local.sh [tag]
#   tag: Image tag (default: latest)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REGISTRY="ghcr.io"
IMAGE_NAME="infiquetra/arc-runner"
TAG="${1:-latest}"

FULL_IMAGE="$REGISTRY/$IMAGE_NAME:$TAG"

echo "Building $FULL_IMAGE..."
docker build -t "$FULL_IMAGE" "$REPO_ROOT/images/runner/"

echo "Authenticating with GHCR..."
echo "$(gh auth token)" | docker login ghcr.io -u "$(gh api user -q .login)" --password-stdin

echo "Pushing $FULL_IMAGE..."
docker push "$FULL_IMAGE"

echo ""
echo "Done! Image pushed to $FULL_IMAGE"
echo "To deploy: ansible-playbook ansible/playbooks/deploy-arc.yml --tags runner-set"

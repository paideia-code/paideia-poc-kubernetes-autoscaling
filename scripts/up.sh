#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

cluster_name="paideia-poc-kubernetes-autoscaling"
context="kind-${cluster_name}"

docker info >/dev/null

clusters="$(kind get clusters)"

if ! grep -Fxq "$cluster_name" <<< "$clusters"; then
  kind create cluster \
    --config cluster/kind.yaml \
    --wait 180s
fi

kubectl --context "$context" wait \
  --for=condition=Ready nodes --all \
  --timeout=180s

helm repo add argo https://argoproj.github.io/argo-helm \
  --force-update

helm repo update argo

helm upgrade --install argocd argo/argo-cd \
  --version 10.17.0 \
  --kube-context "$context" \
  --namespace argocd \
  --create-namespace \
  -f argocd/install/values.yaml \
  --wait \
  --timeout 10m
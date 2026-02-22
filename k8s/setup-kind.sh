#!/bin/bash
# Script to set up kind cluster and deploy Alloy for syncing CRDs to Grafana Cloud
# Usage: ./k8s/setup-kind.sh

set -e

CLUSTER_NAME="mimir-test"
NAMESPACE="monitoring"
ALLOY_NAMESPACE="alloy"

# Get token from .envrc if exists
if [ -f .envrc ]; then
	source .envrc
fi

if [ -z "$MIMIR_ACCESS_TOKEN" ]; then
	echo "Error: MIMIR_ACCESS_TOKEN not found in environment or .envrc"
	exit 1
fi

echo "=== Creating kind cluster ==="
kind create cluster --name "$CLUSTER_NAME"

echo "=== Installing prometheus-operator CRDs ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus-operator prometheus-community/kube-prometheus-stack \
	--namespace "$NAMESPACE" \
	--create-namespace \
	--set prometheusOperator.enabled=true \
	--set prometheus.enabled=false \
	--set alertmanager.enabled=false \
	--set grafana.enabled=false \
	--set kubeStateMetrics.enabled=false \
	--set nodeExporter.enabled=false

echo "=== Waiting for CRDs to be ready ==="
kubectl wait --for=condition=established crd/prometheusrules.monitoring.coreos.com --timeout=60s || true
kubectl wait --for=condition=established crd/alertmanagerconfigs.monitoring.coreos.com --timeout=60s || true

echo "=== Applying AlertmanagerConfig CRDs ==="
kubectl apply -f k8s/alertmanagerconfigs/

echo "=== Applying PrometheusRule CRDs ==="
kubectl apply -f k8s/prometheusrules/

echo "=== Creating secret for Mimir token in alloy namespace ==="
kubectl create namespace "$ALLOY_NAMESPACE" || true
sed "s/<YOUR-MIMIR-ACCESS-TOKEN>/$MIMIR_ACCESS_TOKEN/" k8s/secret-template.yaml | kubectl apply -f -

echo "=== Installing Grafana Alloy ==="
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install alloy grafana/alloy \
	--namespace "$ALLOY_NAMESPACE" \
	--values k8s/helm-values.yaml

echo "=== Checking Alloy status ==="
kubectl get pods -n "$ALLOY_NAMESPACE"
kubectl logs -n "$ALLOY_NAMESPACE" deployment/alloy --tail=30

echo ""
echo "=== Done! ==="
echo "To check CRDs: kubectl get prometheusrules,alertmanagerconfigs -n $NAMESPACE"
echo "To check Alloy: kubectl logs -n $ALLOY_NAMESPACE deployment/alloy -f"

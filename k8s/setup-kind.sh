#!/bin/bash
# Script to set up kind cluster and deploy Alloy for syncing CRDs to Grafana Cloud
# Usage: ./k8s/setup-kind.sh

set -e

CLUSTER_NAME="mimir-test"
NAMESPACE="monitoring"

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

echo "=== Creating secret for Mimir token ==="
kubectl create namespace alloy || true
sed "s/<YOUR-MIMIR-ACCESS-TOKEN>/$MIMIR_ACCESS_TOKEN/" k8s/secret-template.yaml | kubectl apply -f -

echo "=== Installing Grafana Alloy ==="
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install alloy grafana/alloy \
	--namespace alloy \
	--values k8s/helm-values.yaml

echo "=== Checking Alloy status ==="
kubectl get pods -n alloy
kubectl logs -n alloy deployment/alloy --tail=30

echo ""
echo "=== Done! ==="
echo "To check CRDs: kubectl get prometheusrules,alertmanagerconfigs -n $NAMESPACE"
echo "To check Alloy: kubectl logs -n alloy deployment/alloy -f"

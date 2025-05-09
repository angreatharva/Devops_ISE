#!/bin/bash

# Add Prometheus community repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace if it doesn't exist
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Install kube-prometheus-stack (includes Prometheus, Grafana, Alertmanager)
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.enabled=true \
  --set prometheus.enabled=true \
  --set alertmanager.enabled=true \
  --set kubelet.enabled=true \
  --set kubeControllerManager.enabled=true \
  --set coreDns.enabled=true \
  --set kubeEtcd.enabled=false \
  --set kubeScheduler.enabled=true \
  --set kubeProxy.enabled=true

# Wait for deployment to complete
echo "Waiting for Grafana deployment to be ready..."
kubectl -n monitoring wait --for=condition=available deployment/monitoring-grafana --timeout=300s

# Get the default admin password for Grafana
echo "Grafana admin password:"
kubectl -n monitoring get secret monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo

# Port-forward instructions
echo ""
echo "To access Grafana UI, run:"
echo "kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
echo "Then open your browser at http://localhost:3000"
echo ""
echo "To access Prometheus UI, run:"
echo "kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090"
echo "Then open your browser at http://localhost:9090" 
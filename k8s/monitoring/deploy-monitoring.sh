#!/bin/bash

# First install the monitoring stack if not already done
if ! kubectl get namespace monitoring &>/dev/null; then
  echo "Installing Prometheus and Grafana stack..."
  ./setup-monitoring.sh
else
  echo "Monitoring namespace already exists, skipping stack installation."
fi

# Apply custom resources
echo "Applying custom monitoring resources..."

# Apply ServiceMonitor for React app
kubectl apply -f react-app-servicemonitor.yaml

# Apply Grafana dashboards
kubectl apply -f react-grafana-dashboard-configmap.yaml

# Apply alert rules
kubectl apply -f alert-rules.yaml

# Wait for resources to apply
echo "Waiting for resources to be ready..."
sleep 5

# Get access information
echo ""
echo "Monitoring setup completed!"
echo ""
echo "To access Grafana UI:"
echo "kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
echo "Then open your browser at http://localhost:3000"
echo "Default credentials: admin / $(kubectl -n monitoring get secret monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"
echo ""
echo "To access Prometheus UI:"
echo "kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090"
echo "Then open your browser at http://localhost:9090" 
#!/bin/bash
# Script to apply Prometheus alerts for Abstergo application

echo "=== Applying Prometheus Alerts ==="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. Please install kubectl."
    exit 1
fi

# Check if Kubernetes is accessible
echo "Checking Kubernetes connection..."
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster."
    echo "Please check your kubeconfig file or cluster status."
    exit 1
fi

# Check if monitoring namespace exists
if ! kubectl get namespace monitoring &> /dev/null; then
    echo "ERROR: Monitoring namespace not found. Has monitoring been deployed?"
    echo "Run scripts/install_minimal_monitoring.sh to install monitoring"
    exit 1
fi

# Apply the alerts
echo "Applying Prometheus alerts for Abstergo application..."
kubectl apply -f ../monitoring/alerts.yaml

# Check if alerts were applied successfully
if [ $? -eq 0 ]; then
    echo "Alerts applied successfully!"
    
    # Check if Prometheus is running
    if kubectl get pods -n monitoring -l app=prometheus -o jsonpath="{.items[*].status.phase}" | grep -q "Running"; then
        echo "Prometheus is running. Alerts will be evaluated shortly."
    else
        echo "WARNING: Prometheus pod is not running. Alerts will not be evaluated until Prometheus is running."
    fi
else
    echo "ERROR: Failed to apply alerts."
    exit 1
fi

echo ""
echo "To view alerts in Grafana:"
echo "1. Run ./access_monitoring.sh"
echo "2. Navigate to Alerting -> Alert Rules in Grafana"
echo "" 
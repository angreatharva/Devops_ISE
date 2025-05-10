#!/bin/bash
# Access script for monitoring dashboards
# This script creates port forwards to access Prometheus and Grafana

echo "=== Setting up access to monitoring dashboards ==="

# First check if minikube is running
if ! minikube status &>/dev/null; then
    echo "ERROR: Minikube is not running. Please start it with: minikube start"
    echo ""
    echo "IMPORTANT: Starting Minikube requires significant resources."
    echo "Consider closing other applications before starting Minikube."
    echo "Minimum recommended: 2GB RAM and 2 CPU cores available."
    echo ""
    echo "If you prefer not to start Minikube now, you can:"
    echo "1. Run: scripts/check_monitoring_status.sh - to check your monitoring configuration"
    echo "2. Start Minikube when you have adequate resources available"
    exit 1
fi

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

# Check if Grafana pod is ready
echo "Checking if Grafana is ready..."
ATTEMPTS=0
MAX_ATTEMPTS=30

while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    READY_COUNT=$(kubectl get pods -n monitoring -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].status.containerStatuses[?(@.ready==true)].ready}" | wc -w)
    TOTAL_CONTAINERS=$(kubectl get pods -n monitoring -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].spec.containers[*].name}" | wc -w)
    
    if [ "$READY_COUNT" -eq "$TOTAL_CONTAINERS" ]; then
        echo "Grafana is ready!"
        break
    else
        echo "Waiting for Grafana to be ready... ($READY_COUNT/$TOTAL_CONTAINERS containers ready)"
        ATTEMPTS=$((ATTEMPTS+1))
        sleep 5
    fi
    
    if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        echo "WARNING: Grafana is not fully ready, but we'll try to proceed anyway."
    fi
done

# Function to check if a port is already in use
is_port_in_use() {
    lsof -i:"$1" &> /dev/null
}

# Find available ports
GRAF_PORT=3100

while is_port_in_use $GRAF_PORT; do
    GRAF_PORT=$((GRAF_PORT + 1))
done

# Get Grafana credentials
GRAFANA_USER="admin"
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "=== Grafana Access Information ==="
echo "URL: http://localhost:$GRAF_PORT"
echo "Username: $GRAFANA_USER"
echo "Password: $GRAFANA_PASSWORD"

# Get application access
APP_NODE_PORT=$(kubectl get svc abstergo-service -o jsonpath="{.spec.ports[0].nodePort}")
MINIKUBE_IP=$(minikube ip)
echo ""
echo "=== Application Access Information ==="
echo "Application URL: http://$MINIKUBE_IP:$APP_NODE_PORT"

# Start port-forwarding for Grafana
echo ""
echo "Starting port-forwarding for Grafana..."
echo "Press Ctrl+C to stop port-forwarding when done."
echo ""
echo "To test application metrics, run this in another terminal:"
echo "scripts/generate_test_data.sh"
echo ""

# Use the correct service name based on your Helm release
kubectl port-forward -n monitoring svc/prometheus-grafana $GRAF_PORT:80 

# Trap to clean up background processes on exit
cleanup() {
    echo "Stopping port forwarding..."
    exit 0
}

trap cleanup INT 
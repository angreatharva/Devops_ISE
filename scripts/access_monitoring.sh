#!/bin/bash
# Access script for monitoring dashboards
# This script creates port forwards to access Prometheus and Grafana

echo "=== Setting up access to monitoring dashboards ==="

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

# Function to check if a port is already in use
is_port_in_use() {
    lsof -i:"$1" &> /dev/null
}

# Find available ports
PROM_PORT=9090
GRAF_PORT=3000

while is_port_in_use $PROM_PORT; do
    PROM_PORT=$((PROM_PORT + 1))
done

while is_port_in_use $GRAF_PORT; do
    GRAF_PORT=$((GRAF_PORT + 1))
done

# Start port forwarding in the background
echo "Starting port forwarding..."

# Get the prometheus and grafana pod names
PROM_POD=$(kubectl get pods -n monitoring -l app=prometheus -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
GRAF_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)

if [ -z "$PROM_POD" ]; then
    echo "Warning: Prometheus pod not found. Skipping Prometheus port forwarding."
else
    kubectl port-forward -n monitoring $PROM_POD $PROM_PORT:9090 &
    PROM_PID=$!
    echo "Prometheus dashboard available at: http://localhost:$PROM_PORT"
fi

if [ -z "$GRAF_POD" ]; then
    echo "Warning: Grafana pod not found. Skipping Grafana port forwarding."
else
    kubectl port-forward -n monitoring $GRAF_POD $GRAF_PORT:3000 &
    GRAF_PID=$!
    echo "Grafana dashboard available at: http://localhost:$GRAF_PORT"
    echo "Default credentials - Username: admin, Password: prom-operator"
fi

echo ""
echo "Press Ctrl+C to stop port forwarding"
echo ""

# Trap to clean up background processes
cleanup() {
    echo "Stopping port forwarding..."
    [ ! -z "$PROM_PID" ] && kill $PROM_PID &>/dev/null
    [ ! -z "$GRAF_PID" ] && kill $GRAF_PID &>/dev/null
    exit 0
}

trap cleanup INT

# Wait for user to press Ctrl+C
wait 
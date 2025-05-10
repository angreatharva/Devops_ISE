#!/bin/bash
# Monitoring Status Checker - Designed for low-resource environments
# This script checks the status of monitoring without starting Minikube

echo "=== Abstergo Monitoring Status Checker ==="

# First check if minikube is running without attempting to start it
MINIKUBE_STATUS=$(minikube status -f '{{.Host}}' 2>/dev/null)
if [ "$MINIKUBE_STATUS" != "Running" ]; then
    echo "NOTICE: Minikube is not running."
    echo "Your monitoring stack is installed but currently inactive because Minikube is stopped."
    echo ""
    echo "If you want to access monitoring, you would need to:"
    echo "1. Start Minikube: minikube start"
    echo "2. Wait for all pods to become ready (this may take a few minutes)"
    echo "3. Run: ./scripts/access_monitoring.sh"
    echo ""
    echo "IMPORTANT: Starting Minikube requires significant resources."
    echo "Consider closing other applications before starting Minikube."
    echo "Minimum recommended: 2GB RAM and 2 CPU cores available."
    echo ""
    echo "Your application metrics will be preserved and visible in Grafana"
    echo "once you start Minikube again."
    exit 0
fi

# If Minikube is running, check monitoring status
echo "Minikube is running. Checking monitoring status..."

# Check if monitoring namespace exists
if ! kubectl get namespace monitoring &>/dev/null; then
    echo "Monitoring namespace not found. Monitoring stack not installed."
    echo "To install, run: ./scripts/install_minimal_monitoring.sh"
    exit 1
fi

# Check Prometheus and Grafana pods
PROM_PODS=$(kubectl get pods -n monitoring -l app=prometheus -o name 2>/dev/null)
GRAF_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o name 2>/dev/null)

if [ -z "$PROM_PODS" ] || [ -z "$GRAF_PODS" ]; then
    echo "WARNING: Some monitoring components are missing."
    echo "To reinstall, run: ./scripts/install_minimal_monitoring.sh"
else
    # Check pod status
    READY_COUNT=$(kubectl get pods -n monitoring -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
    TOTAL_PODS=$(kubectl get pods -n monitoring -o name | wc -w)
    
    echo "Monitoring pods: $READY_COUNT/$TOTAL_PODS running"
    
    if [ "$READY_COUNT" -lt "$TOTAL_PODS" ]; then
        echo "WARNING: Not all monitoring pods are running."
        echo "This may affect monitoring functionality."
    else
        echo "All monitoring pods are running."
        echo "To access the dashboards, run: ./scripts/access_monitoring.sh"
    fi
fi

# Get Grafana credentials if available
if kubectl get secret -n monitoring prometheus-grafana &>/dev/null; then
    GRAFANA_USER="admin"
    GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
    
    echo ""
    echo "=== Grafana Access Information ==="
    echo "URL (when port-forwarded): http://localhost:3000"
    echo "Username: $GRAFANA_USER"
    echo "Password: $GRAFANA_PASSWORD"
fi

echo ""
echo "Note: The monitoring stack is designed to use minimal resources."
echo "However, if your system is still resource-constrained, you can"
echo "temporarily disable monitoring by stopping Minikube." 
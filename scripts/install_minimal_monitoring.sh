#!/bin/bash
# Script to install minimal resource monitoring for Abstergo application

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install it first."
    exit 1
fi

# Check if minikube is running
if ! minikube status | grep -q "Running"; then
    echo "Minikube is not running. Would you like to start it with minimal resources? (y/n)"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Starting Minikube with minimal resources..."
        minikube start --memory 1500 --cpus 2
    else
        echo "Please start Minikube manually and try again."
        exit 1
    fi
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Helm is not installed. Installing it now..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
fi

echo "=== Installing Minimal Monitoring for Abstergo Application ==="

# Add Prometheus Helm repository
echo "Adding Prometheus Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace if it doesn't exist
if ! kubectl get namespace monitoring &>/dev/null; then
    echo "Creating monitoring namespace..."
    kubectl create namespace monitoring
fi

# Install Prometheus Operator with minimal resources
echo "Installing Prometheus and Grafana with minimal resources..."
helm install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values monitoring/minimal-monitoring-values.yaml \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Create ServiceMonitor for Abstergo app
echo "Creating ServiceMonitor for Abstergo app..."
kubectl apply -f monitoring/servicemonitor.yaml

# Create dashboard ConfigMap
echo "Creating Grafana dashboard for Abstergo app..."
kubectl apply -f monitoring/dashboard.yaml

echo "=== Monitoring Installation Complete ==="
echo "To access monitoring dashboards, run: ./scripts/monitoring.sh access" 
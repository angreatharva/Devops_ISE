#!/bin/bash
# Minimal monitoring installation script for low-resource environments
# This script installs Prometheus and Grafana with minimal resource settings

echo "=== Installing Minimal Monitoring Stack ==="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. Please install kubectl."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "Error: helm not found. Please install helm."
    exit 1
fi

# Check if Kubernetes is accessible
echo "Checking Kubernetes connection..."
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster."
    echo "Please check your kubeconfig file or cluster status."
    exit 1
fi

# Check if Minikube is running with enough resources
if command -v minikube &> /dev/null; then
    MINIKUBE_STATUS=$(minikube status -f '{{.Host}}' 2>/dev/null)
    if [ "$MINIKUBE_STATUS" == "Running" ]; then
        echo "Minikube is running. Checking resources..."
        MINIKUBE_MEM=$(minikube config view | grep memory | awk '{print $3}')
        if [ ! -z "$MINIKUBE_MEM" ] && [ "$MINIKUBE_MEM" -lt 1900 ]; then
            echo "Warning: Minikube is running with less than 1900MB memory."
            echo "Monitoring stack may not function properly."
            echo "Consider stopping minikube and restarting with: minikube start --memory=1900m"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            echo "Minikube resources look good."
        fi
    fi
fi

# Create monitoring namespace if not exists
if ! kubectl get namespace monitoring &> /dev/null; then
    echo "Creating monitoring namespace..."
    kubectl create namespace monitoring
else
    echo "Monitoring namespace already exists."
fi

# Add Helm repository for Prometheus
echo "Adding Prometheus Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo update

# Check if monitoring stack is already installed
if helm list -n monitoring | grep prometheus &> /dev/null; then
    echo "Prometheus is already installed. Upgrading with minimal resources..."
    HELM_CMD="upgrade"
else
    echo "Installing Prometheus with minimal resources..."
    HELM_CMD="install"
fi

# Install/upgrade Prometheus stack with minimal resources
helm $HELM_CMD prometheus prometheus-community/kube-prometheus-stack \
    -n monitoring \
    -f ../monitoring/minimal-monitoring-values.yaml \
    --set grafana.service.type=ClusterIP \
    --set prometheus.service.type=ClusterIP

# Wait for pods to start
echo "Waiting for monitoring pods to start..."
kubectl wait --for=condition=ready pods -l app=grafana -n monitoring --timeout=300s || true
kubectl wait --for=condition=ready pods -l app=prometheus -n monitoring --timeout=300s || true

# Apply ServiceMonitor for Abstergo
echo "Applying ServiceMonitor for Abstergo application..."
kubectl apply -f ../k8s/servicemonitor.yaml

# Apply Grafana dashboard
echo "Applying Grafana dashboard for Abstergo application..."
kubectl apply -f ../k8s/grafana-dashboard.yaml

echo ""
echo "=== Monitoring Installation Complete ==="
echo ""
echo "To access the monitoring dashboards, run: ./access_monitoring.sh"
echo "To generate test data, run: ./generate_test_data.sh"
echo ""
echo "Note: If you're running on a low-memory system, you may need to close"
echo "other applications to ensure everything runs smoothly." 
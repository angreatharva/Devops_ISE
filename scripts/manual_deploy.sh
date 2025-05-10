#!/bin/bash
# Manual deployment script for Abstergo application

echo "=== Abstergo Manual Deployment Tool ==="

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "Error: minikube not found. Please install minikube first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if minikube is running
if ! minikube status | grep -q "Running"; then
    echo "Starting minikube..."
    minikube start --memory=2048 --cpus=2
fi

# Create monitoring namespace if it doesn't exist
if ! kubectl get namespace monitoring &>/dev/null; then
    echo "Creating monitoring namespace..."
    kubectl create namespace monitoring
fi

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: helm not found. Please install helm first."
    exit 1
fi

# Add Prometheus repository if it doesn't exist
if ! helm repo list | grep -q "prometheus-community"; then
    echo "Adding Prometheus helm repository..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
fi

# Check if prometheus is already installed
if ! helm list -n monitoring | grep -q "prometheus"; then
    echo "Installing Prometheus with minimal resources..."
    helm install prometheus prometheus-community/kube-prometheus-stack \
        -n monitoring \
        -f monitoring/minimal-monitoring-values.yaml \
        --set grafana.service.type=ClusterIP \
        --set prometheus.service.type=ClusterIP
else
    echo "Prometheus already installed, upgrading with latest values..."
    helm upgrade prometheus prometheus-community/kube-prometheus-stack \
        -n monitoring \
        -f monitoring/minimal-monitoring-values.yaml \
        --set grafana.service.type=ClusterIP \
        --set prometheus.service.type=ClusterIP
fi

echo "Applying Kubernetes configurations..."
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/servicemonitor.yaml

echo "Waiting for the deployment to be ready..."
kubectl rollout status deployment/abstergo-app --timeout=180s

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "To access the application, run:"
echo "  minikube service abstergo-service --url"
echo ""
echo "To access the Grafana dashboard, run:"
echo "  scripts/access_monitoring.sh"
echo ""
echo "To generate test traffic, run:"
echo "  scripts/generate_test_data.sh"
echo ""
echo "When done testing, you can clean up Docker images with:"
echo "  scripts/cleanup_docker_images.sh" 
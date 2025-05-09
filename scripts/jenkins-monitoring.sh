#!/bin/bash
# Jenkins-specific monitoring script for Abstergo application
# This script provides a CI/CD friendly version of the monitoring setup

# Default command
COMMAND="help"
if [ $# -gt 0 ]; then
  COMMAND=$1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install it first."
    exit 1
fi

# Check kubernetes connection without requiring minikube
check_kubernetes() {
  if ! kubectl get nodes &> /dev/null; then
    echo "Cannot connect to Kubernetes. Make sure the cluster is accessible."
    exit 1
  fi
  echo "Kubernetes is accessible."
}

# Install monitoring stack
install_monitoring() {
    echo "=== Installing Monitoring for Abstergo Application ==="
    
    # Check kubectl connection
    check_kubernetes
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        echo "Helm is not installed. Installing it now..."
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh
        rm get_helm.sh
    fi
    
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
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --timeout 5m \
        --wait || echo "Helm installation timed out, but may still complete in background"
    
    # Create ServiceMonitor for Abstergo app
    echo "Creating ServiceMonitor for Abstergo app..."
    kubectl apply -f monitoring/servicemonitor.yaml
    
    # Create dashboard ConfigMap
    echo "Creating Grafana dashboard for Abstergo app..."
    kubectl apply -f monitoring/dashboard.yaml
    
    echo "=== Monitoring Installation Complete ==="
}

# Display help
show_help() {
    echo "Abstergo Application Monitoring Tool for Jenkins"
    echo ""
    echo "Usage: ./scripts/jenkins-monitoring.sh [command]"
    echo ""
    echo "Commands:"
    echo "  install    - Install monitoring stack"
    echo "  help       - Show this help message"
}

# Main command dispatcher
case "$COMMAND" in
    install)
        install_monitoring
        ;;
    help|*)
        show_help
        ;;
esac 
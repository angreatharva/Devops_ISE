#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print error messages
error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Function to print success messages
success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

# Function to print warning messages
warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Function to check system resources
check_resources() {
    echo "Checking system resources..."
    
    # Get total memory in MB
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    FREE_MEM=$(free -m | awk '/^Mem:/{print $4}')
    
    # Get CPU load
    CPU_LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1)
    
    echo "Available Memory: ${FREE_MEM}MB out of ${TOTAL_MEM}MB"
    echo "Current CPU Load: ${CPU_LOAD}"
    
    # Check if we have enough resources
    if [ ${FREE_MEM} -lt 500 ]; then
        warning "Low memory available. Monitoring stack may not function properly."
        warning "Consider freeing up at least 500MB of memory."
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check dependencies
check_dependencies() {
    echo "Checking dependencies..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        error "kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        error "helm not found. Please install helm first."
        exit 1
    fi
    
    success "All required dependencies are installed."
}

# Function to setup monitoring namespace
setup_namespace() {
    echo "Setting up monitoring namespace..."
    
    if ! kubectl get namespace monitoring &> /dev/null; then
        kubectl create namespace monitoring
        if [ $? -eq 0 ]; then
            success "Created monitoring namespace."
        else
            error "Failed to create monitoring namespace."
            exit 1
        fi
    else
        warning "Monitoring namespace already exists."
    fi
}

# Function to setup Prometheus and Grafana
setup_monitoring_stack() {
    echo "Setting up Prometheus and Grafana..."
    
    # Add Helm repo
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
    helm repo update
    
    # Check if monitoring is already installed
    if helm list -n monitoring | grep -q "prometheus"; then
        warning "Prometheus stack is already installed. Upgrading..."
        helm upgrade prometheus prometheus-community/kube-prometheus-stack \
            -n monitoring \
            -f monitoring/minimal-monitoring-values.yaml \
            --set grafana.service.type=ClusterIP \
            --set prometheus.service.type=ClusterIP \
            --timeout 10m
    else
        echo "Installing Prometheus stack..."
        helm install prometheus prometheus-community/kube-prometheus-stack \
            -n monitoring \
            -f monitoring/minimal-monitoring-values.yaml \
            --set grafana.service.type=ClusterIP \
            --set prometheus.service.type=ClusterIP \
            --timeout 10m
    fi
    
    if [ $? -eq 0 ]; then
        success "Monitoring stack installed/upgraded successfully."
    else
        error "Failed to install/upgrade monitoring stack."
        exit 1
    fi
}

# Function to apply custom configurations
apply_custom_configs() {
    echo "Applying custom configurations..."
    
    # Apply ServiceMonitor
    kubectl apply -f monitoring/servicemonitor.yaml
    if [ $? -ne 0 ]; then
        warning "Failed to apply ServiceMonitor. This may be expected if the CRD is not yet ready."
    fi
    
    # Apply dashboard
    kubectl apply -f monitoring/dashboard.yaml
    if [ $? -ne 0 ]; then
        warning "Failed to apply dashboard. This may be expected if Grafana is not yet ready."
    fi
}

# Function to wait for pods
wait_for_pods() {
    echo "Waiting for monitoring pods to be ready..."
    
    # Wait for up to 5 minutes
    kubectl wait --for=condition=ready pods -l "app.kubernetes.io/name=grafana" -n monitoring --timeout=300s
    if [ $? -eq 0 ]; then
        success "Grafana is ready."
    else
        warning "Grafana pods are not ready yet. You may need to wait longer."
    fi
    
    kubectl wait --for=condition=ready pods -l "app=prometheus" -n monitoring --timeout=300s
    if [ $? -eq 0 ]; then
        success "Prometheus is ready."
    else
        warning "Prometheus pods are not ready yet. You may need to wait longer."
    fi
}

# Main execution
echo "=== Abstergo Monitoring Setup ==="
echo "This script will set up monitoring with minimal resource usage."
echo

# Run all steps
check_resources
check_dependencies
setup_namespace
setup_monitoring_stack
apply_custom_configs
wait_for_pods

echo
success "Monitoring setup completed!"
echo
echo "To access the monitoring dashboards, run: ./scripts/access_monitoring.sh"
echo "To check monitoring status, run: ./scripts/check_monitoring_status.sh"
echo "To generate test data, run: ./scripts/generate_test_data.sh" 
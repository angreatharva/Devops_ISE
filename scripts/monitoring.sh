#!/bin/bash
# Unified monitoring script for Abstergo application
# This script handles installation, access, and test data generation

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

# Check if minikube is running
check_minikube() {
  if ! minikube status | grep -q "Running"; then
    echo "Minikube is not running. Start it with: minikube start --memory 1900 --cpus 2"
    exit 1
  fi
}

# Function to check if a port is in use
is_port_in_use() {
    lsof -i :"$1" &>/dev/null
    return $?
}

# Function to wait for pod readiness
wait_for_pod() {
    local namespace=$1
    local label=$2
    local timeout=120  # 2 minutes timeout
    local start_time=$(date +%s)
    
    echo "Waiting for $label pod in $namespace namespace to be ready..."
    
    while true; do
        # Check if pod exists and is running
        if kubectl get pods -n $namespace -l $label --no-headers 2>/dev/null | grep -q "Running"; then
            echo "Pod with label $label is running."
            return 0
        fi
        
        # Check timeout
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        if [ $elapsed -gt $timeout ]; then
            echo "Timeout waiting for $label pod."
            return 1
        fi
        
        echo -n "."
        sleep 2
    done
}

# Generate test traffic
generate_test_data() {
    check_minikube
    
    # Get the service address
    SERVICE_PORT=$(kubectl get svc abstergo-service -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}')
    MINIKUBE_IP=$(minikube ip)
    SERVICE_URL="http://$MINIKUBE_IP:$SERVICE_PORT"
    
    # Make a request to the application
    make_request() {
        local path=$1
        local status=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL$path")
        echo "Request to $path returned status $status"
    }
    
    # Generate test traffic
    echo "Generating test traffic to $SERVICE_URL"
    echo "Press Ctrl+C to stop."
    
    count=0
    # Loop until interrupted
    while true; do
        # Make requests to different endpoints
        make_request "/"
        make_request "/products"
        make_request "/about"
        
        # Occasionally make a bad request to generate an error
        if (( count % 5 == 0 )); then
            make_request "/nonexistent-page"
        fi
        
        count=$((count+1))
        echo "Completed $count sets of requests"
        sleep 2
    done
}

# Install monitoring stack
install_monitoring() {
    check_minikube
    
    echo "=== Installing Monitoring for Abstergo Application ==="
    
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
        --values monitoring/values.yaml \
        --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
    
    # Wait for pods to be ready
    echo "Waiting for monitoring pods to start (this may take a few minutes)..."
    kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=300s
    
    # Create ServiceMonitor for Abstergo app
    echo "Creating ServiceMonitor for Abstergo app..."
    kubectl apply -f monitoring/servicemonitor.yaml
    
    # Create dashboard ConfigMap
    echo "Creating Grafana dashboard for Abstergo app..."
    kubectl apply -f monitoring/dashboard.yaml
    
    echo "=== Monitoring Installation Complete ==="
    echo "To access monitoring dashboards, run: ./scripts/monitoring.sh access"
}

# Access monitoring dashboards via port-forwarding
access_monitoring() {
    check_minikube
    
    echo "=== Abstergo Application Monitoring Access ==="
    
    # Find available ports if default ones are in use
    GRAFANA_PORT=3000
    if is_port_in_use $GRAFANA_PORT; then
        GRAFANA_PORT=3001
        echo "Port 3000 is already in use. Using port 3001 for Grafana."
    fi
    
    PROMETHEUS_PORT=9090
    if is_port_in_use $PROMETHEUS_PORT; then
        PROMETHEUS_PORT=9091
        echo "Port 9090 is already in use. Using port 9091 for Prometheus."
    fi
    
    APP_PORT=8080
    if is_port_in_use $APP_PORT; then
        APP_PORT=8081
        echo "Port 8080 is already in use. Using port 8081 for the application."
    fi
    
    # Ensure pods are ready before attempting port-forwarding
    wait_for_pod "monitoring" "app.kubernetes.io/name=grafana"
    wait_for_pod "monitoring" "app=prometheus"
    wait_for_pod "default" "app=abstergo-app"
    
    # Start port forwarding
    echo "Starting port forwarding. Press Ctrl+C to stop."
    
    # Start port forwarding in the background
    echo "Starting Grafana on port $GRAFANA_PORT..."
    kubectl port-forward svc/monitoring-grafana $GRAFANA_PORT:80 -n monitoring &
    GRAFANA_PID=$!
    
    echo "Starting Prometheus on port $PROMETHEUS_PORT..."
    kubectl port-forward svc/monitoring-kube-prometheus-prometheus $PROMETHEUS_PORT:9090 -n monitoring &
    PROMETHEUS_PID=$!
    
    echo "Starting Abstergo application on port $APP_PORT..."
    kubectl port-forward svc/abstergo-service $APP_PORT:80 &
    APP_PID=$!
    
    echo
    echo "=== Access Information ==="
    echo "Grafana:     http://localhost:$GRAFANA_PORT"
    echo "Username: admin"
    echo "Password: prom-operator"
    echo
    echo "Prometheus:  http://localhost:$PROMETHEUS_PORT"
    echo
    echo "Application: http://localhost:$APP_PORT"
    echo
    echo "Press Enter to stop all port forwards and exit."
    read
    
    # Kill all background processes
    kill $GRAFANA_PID $PROMETHEUS_PID $APP_PID 2>/dev/null
    echo "All port forwarding stopped."
}

# Clean up monitoring resources
cleanup_monitoring() {
    check_minikube
    
    echo "=== Cleaning up Monitoring Resources ==="
    
    # Ask for confirmation
    read -p "This will delete all monitoring resources. Are you sure? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleanup cancelled."
        exit 0
    fi
    
    # Delete monitoring helm release
    echo "Deleting monitoring helm release..."
    helm delete monitoring -n monitoring
    
    # Delete monitoring namespace
    echo "Deleting monitoring namespace..."
    kubectl delete namespace monitoring
    
    echo "Monitoring resources cleaned up successfully!"
}

# Display help
show_help() {
    echo "Abstergo Application Monitoring Tool"
    echo ""
    echo "Usage: ./scripts/monitoring.sh [command]"
    echo ""
    echo "Commands:"
    echo "  install    - Install monitoring stack"
    echo "  access     - Access monitoring dashboards"
    echo "  generate   - Generate test data for monitoring"
    echo "  cleanup    - Remove monitoring resources"
    echo "  help       - Show this help message"
}

# Main command dispatcher
case "$COMMAND" in
    install)
        install_monitoring
        ;;
    access)
        access_monitoring
        ;;
    generate)
        generate_test_data
        ;;
    cleanup)
        cleanup_monitoring
        ;;
    help|*)
        show_help
        ;;
esac 
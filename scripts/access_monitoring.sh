#!/bin/bash
# Access script for monitoring dashboards
# This script creates port forwards to access Prometheus and Grafana

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

# Function to check if a port is in use
is_port_in_use() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        return 0
    else
        return 1
    fi
}

# Function to find an available port starting from a base port
find_available_port() {
    local base_port=$1
    local port=$base_port
    while is_port_in_use $port; do
        port=$((port + 1))
    done
    echo $port
}

# Function to check monitoring namespace and pods
check_monitoring() {
    # Check if monitoring namespace exists
    if ! kubectl get namespace monitoring &> /dev/null; then
        error "Monitoring namespace not found. Please run ./scripts/setup_monitoring.sh first."
        exit 1
    fi

    # Check if Grafana pod exists
    if ! kubectl get pods -n monitoring -l "app.kubernetes.io/name=grafana" &> /dev/null; then
        error "Grafana pod not found. Please run ./scripts/setup_monitoring.sh first."
        exit 1
    fi
}

# Function to wait for Grafana to be ready
wait_for_grafana() {
    echo "Checking if Grafana is ready..."
    local attempts=0
    local max_attempts=30

    while [ $attempts -lt $max_attempts ]; do
        local ready_count=$(kubectl get pods -n monitoring -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].status.containerStatuses[?(@.ready==true)].ready}" | wc -w)
        local total_containers=$(kubectl get pods -n monitoring -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].spec.containers[*].name}" | wc -w)
        
        if [ "$ready_count" -eq "$total_containers" ]; then
            success "Grafana is ready!"
            return 0
        else
            echo "Waiting for Grafana to be ready... ($ready_count/$total_containers containers ready)"
            attempts=$((attempts+1))
            sleep 5
        fi
    done

    warning "Grafana is not fully ready after waiting. Will try to proceed anyway."
    return 1
}

# Main execution
echo "=== Setting up access to monitoring dashboards ==="

# Check monitoring setup
check_monitoring

# Wait for Grafana to be ready
wait_for_grafana

# Find available ports
GRAFANA_PORT=$(find_available_port 3000)
if [ $GRAFANA_PORT -ne 3000 ]; then
    warning "Port 3000 is in use. Using port $GRAFANA_PORT for Grafana."
fi

# Get Grafana credentials
GRAFANA_USER="admin"
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

if [ -z "$GRAFANA_PASSWORD" ]; then
    error "Could not retrieve Grafana password. Please check if the secret exists."
    exit 1
fi

# Print access information
echo
echo "=== Access Information ==="
echo "Grafana:"
echo "  URL: http://localhost:$GRAFANA_PORT"
echo "  Username: $GRAFANA_USER"
echo "  Password: $GRAFANA_PASSWORD"
echo

# Get application access information if available
if kubectl get svc abstergo-service &> /dev/null; then
    APP_NODE_PORT=$(kubectl get svc abstergo-service -o jsonpath="{.spec.ports[0].nodePort}")
    if [ ! -z "$APP_NODE_PORT" ]; then
        echo "Application:"
        echo "  URL: http://localhost:$APP_NODE_PORT"
        echo
    fi
fi

echo "Starting port-forwarding for Grafana..."
echo "Press Ctrl+C to stop port-forwarding when done."
echo
echo "To test application metrics, run this in another terminal:"
echo "  ./scripts/generate_test_data.sh"
echo

# Start port-forwarding
exec kubectl port-forward -n monitoring svc/prometheus-grafana $GRAFANA_PORT:80 
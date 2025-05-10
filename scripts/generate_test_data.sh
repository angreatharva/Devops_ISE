#!/bin/bash
# Test data generator for Abstergo application
# This script sends requests to the application to generate metrics for monitoring

echo "=== Generating test data for Abstergo application ==="

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

# Get the service URL for the Abstergo application
SERVICE_NAME="abstergo-service"
SERVICE_PORT=$(kubectl get svc $SERVICE_NAME -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
SERVICE_TYPE=$(kubectl get svc $SERVICE_NAME -o jsonpath='{.spec.type}' 2>/dev/null)

if [ -z "$SERVICE_PORT" ]; then
    echo "Error: Could not find service $SERVICE_NAME"
    exit 1
fi

# Determine the URL to use based on service type
if [ "$SERVICE_TYPE" == "LoadBalancer" ]; then
    # For LoadBalancer services, use the external IP
    SERVICE_IP=$(kubectl get svc $SERVICE_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -z "$SERVICE_IP" ]; then
        # Fallback if external IP is not available yet
        echo "External IP not yet assigned, using port forwarding instead..."
        PORT_FWD=true
    else
        APP_URL="http://$SERVICE_IP:$SERVICE_PORT"
    fi
elif [ "$SERVICE_TYPE" == "NodePort" ]; then
    # For NodePort services, use the node IP and node port
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}' 2>/dev/null)
    NODE_PORT=$(kubectl get svc $SERVICE_NAME -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    APP_URL="http://$NODE_IP:$NODE_PORT"
else
    # For ClusterIP services, use port forwarding
    PORT_FWD=true
fi

# Use port forwarding if required
if [ "$PORT_FWD" == "true" ]; then
    LOCAL_PORT=8080
    echo "Setting up port forwarding to $SERVICE_NAME on port $LOCAL_PORT..."
    kubectl port-forward svc/$SERVICE_NAME $LOCAL_PORT:$SERVICE_PORT &
    PF_PID=$!
    # Wait for port-forward to establish
    sleep 2
    APP_URL="http://localhost:$LOCAL_PORT"
    
    # Cleanup function to kill port-forward on exit
    cleanup() {
        echo "Stopping port forwarding..."
        kill $PF_PID &>/dev/null
        exit 0
    }
    trap cleanup INT
fi

# Function to make requests with random paths and methods
generate_request() {
    local paths=("/api/items" "/api/users" "/api/products" "/api/orders" "/api/search")
    local methods=("GET" "POST" "PUT" "DELETE")
    
    # Select random path and method
    local rand_path=${paths[$RANDOM % ${#paths[@]}]}
    local rand_method=${methods[$RANDOM % ${#methods[@]}]}
    
    # Make the request
    echo "Making $rand_method request to $APP_URL$rand_path"
    curl -s -X $rand_method "$APP_URL$rand_path" -H "Content-Type: application/json" -d '{"test":"data"}' > /dev/null
}

echo "Starting test data generation to $APP_URL"
echo "Press Ctrl+C to stop"

# Generate requests until stopped
counter=0
while true; do
    generate_request
    counter=$((counter + 1))
    echo "Sent $counter requests..."
    sleep 0.5
done 
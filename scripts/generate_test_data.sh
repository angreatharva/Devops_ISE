#!/bin/bash
# Script to generate test data for Abstergo monitoring

echo "=== Abstergo Test Data Generator ==="

# Check if minikube is running
if ! minikube status &>/dev/null; then
    echo "ERROR: Minikube is not running. Please start it with: minikube start"
    exit 1
fi

# Check if the application is deployed
if ! kubectl get deployment abstergo-app &>/dev/null; then
    echo "ERROR: Abstergo application not deployed. Please deploy it first."
    exit 1
fi

# Get app URL
APP_NODE_PORT=$(kubectl get svc abstergo-service -o jsonpath="{.spec.ports[0].nodePort}")
MINIKUBE_IP=$(minikube ip)
APP_URL="http://$MINIKUBE_IP:$APP_NODE_PORT"

echo "Generating test traffic to $APP_URL"
echo "Press Ctrl+C to stop at any time"
echo ""

# Create counter
count=0

# Generate traffic with different patterns
echo "Starting traffic generation..."
while true; do
    count=$((count+1))
    
    # Every 10th request, use a different endpoint to create variation
    if [ $((count % 10)) -eq 0 ]; then
        ENDPOINT="/products"
    elif [ $((count % 7)) -eq 0 ]; then
        ENDPOINT="/about"
    else
        ENDPOINT="/"
    fi
    
    # Make the request and capture status code
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" $APP_URL$ENDPOINT)
    
    echo "Request #$count to $ENDPOINT: HTTP $STATUS"
    
    # Random sleep between 0.2 and 1 second
    SLEEP_TIME=$(awk -v min=0.2 -v max=1 'BEGIN{srand(); print min+rand()*(max-min)}')
    sleep $SLEEP_TIME
done 
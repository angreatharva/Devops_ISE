#!/bin/bash
# Script to generate test data for Abstergo monitoring

echo "=== Abstergo Test Data Generator ==="

# Check if minikube is running
MINIKUBE_RUNNING=true
if ! minikube status &>/dev/null; then
    MINIKUBE_RUNNING=false
    echo "WARNING: Minikube is not running."
    echo "Would you like to:"
    echo "1. Use the last known URL (might not work if cluster is down)"
    echo "2. Exit and start Minikube first"
    read -p "Enter choice [1/2]: " choice
    
    if [ "$choice" == "2" ]; then
        echo "Exiting. Start Minikube with: minikube start"
        exit 1
    fi
    
    # Try to use cached URL from previous run if available
    if [ -f ~/.abstergo_last_url ]; then
        APP_URL=$(cat ~/.abstergo_last_url)
        echo "Using cached URL: $APP_URL"
    else
        echo "No cached URL found. Please provide the application URL:"
        read -p "URL (e.g., http://192.168.49.2:30122): " APP_URL
    fi
else
    # Check if the application is deployed
    if ! kubectl get deployment abstergo-app &>/dev/null; then
        echo "ERROR: Abstergo application not deployed. Please deploy it first."
        exit 1
    fi

    # Get app URL
    APP_NODE_PORT=$(kubectl get svc abstergo-service -o jsonpath="{.spec.ports[0].nodePort}")
    MINIKUBE_IP=$(minikube ip)
    APP_URL="http://$MINIKUBE_IP:$APP_NODE_PORT"
    
    # Save URL for future use
    echo $APP_URL > ~/.abstergo_last_url
fi

echo "Generating test traffic to $APP_URL"
echo "Press Ctrl+C to stop at any time"
echo ""

# Create counter
count=0

# Trap to handle Ctrl+C gracefully
trap 'echo -e "\nTest data generation stopped."; exit 0' INT

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
    
    # Make the request with a timeout and capture status code
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 $APP_URL$ENDPOINT 2>/dev/null || echo "Failed")
    
    if [ "$STATUS" == "Failed" ]; then
        echo "Request #$count to $ENDPOINT: Failed to connect"
        
        # If we've failed 3 times in a row, ask if user wants to continue
        if [ $count -gt 3 ] && [ $((count % 3)) -eq 0 ]; then
            echo "Multiple connection failures. Continue trying? (y/n)"
            read -t 10 -n 1 answer || answer="y"
            echo ""
            if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
                echo "Stopping test data generation."
                exit 1
            fi
        fi
    else
        echo "Request #$count to $ENDPOINT: HTTP $STATUS"
    fi
    
    # Random sleep between 0.2 and 1 second
    SLEEP_TIME=$(awk -v min=0.2 -v max=1 'BEGIN{srand(); print min+rand()*(max-min)}')
    sleep $SLEEP_TIME
done 
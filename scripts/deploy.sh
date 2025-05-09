#!/bin/bash
# Unified deployment script for Abstergo application
# This script handles Kubernetes deployment tasks

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

# Build docker image
build_image() {
  echo "=== Building Abstergo Application Docker Image ==="
  
  # Get current image tag from deployment.yaml
  IMAGE_NAME="angreatharva/abstergo"
  CURRENT_TAG=$(grep -oP "image: ${IMAGE_NAME}:\K[0-9]+" k8s/deployment.yaml || echo "1")
  
  # Increment tag for new build
  NEW_TAG=$((CURRENT_TAG + 1))
  
  # Build the docker image
  echo "Building Docker image $IMAGE_NAME:$NEW_TAG..."
  docker build -t $IMAGE_NAME:$NEW_TAG .
  
  # Update the tag in deployment.yaml
  sed -i "s|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${NEW_TAG}|g" k8s/deployment.yaml
  
  echo "Docker image built and deployment.yaml updated with new tag: $NEW_TAG"
}

# Deploy to Kubernetes
deploy_app() {
  check_minikube
  
  echo "=== Deploying Abstergo Application to Kubernetes ==="
  
  # Apply Kubernetes configurations
  echo "Applying Kubernetes configurations..."
  kubectl apply -f k8s/configmap.yaml
  kubectl apply -f k8s/deployment.yaml
  kubectl apply -f k8s/service.yaml
  
  # Wait for deployment to be ready
  echo "Waiting for deployment to be ready..."
  kubectl rollout status deployment/abstergo-app --timeout=300s
  
  # Get service URL
  NODE_PORT=$(kubectl get svc abstergo-service -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}')
  MINIKUBE_IP=$(minikube ip)
  
  echo "=== Deployment Complete ==="
  echo "Application URL: http://$MINIKUBE_IP:$NODE_PORT"
}

# Verify the deployment is running correctly
verify_deployment() {
  check_minikube
  
  echo "=== Verifying Abstergo Application Deployment ==="
  
  # Check pods
  echo "Checking pods..."
  kubectl get pods -l app=abstergo-app
  
  # Check services
  echo "Checking services..."
  kubectl get svc abstergo-service
  
  # Get app URL
  NODE_PORT=$(kubectl get svc abstergo-service -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}')
  MINIKUBE_IP=$(minikube ip)
  SERVICE_URL="http://$MINIKUBE_IP:$NODE_PORT"
  
  # Test app connection
  echo "Testing application endpoint..."
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $SERVICE_URL)
  
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "✓ Application is responding properly (HTTP 200)"
    echo "Access the application at: $SERVICE_URL"
  else
    echo "⚠️ Application is not responding properly (HTTP $HTTP_STATUS)"
    echo "Check pod logs for errors:"
    kubectl logs -l app=abstergo-app
  fi
  
  # Check metrics endpoint
  echo "Testing metrics endpoint..."
  METRICS_PORT=$(kubectl get svc abstergo-service -o jsonpath='{.spec.ports[?(@.name=="metrics")].nodePort}')
  METRICS_URL="http://$MINIKUBE_IP:$METRICS_PORT/metrics"
  
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $METRICS_URL)
  
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "✓ Metrics endpoint is responding properly (HTTP 200)"
    echo "Metrics URL: $METRICS_URL"
  else
    echo "⚠️ Metrics endpoint is not responding properly (HTTP $HTTP_STATUS)"
  fi
}

# Delete the application from Kubernetes
delete_app() {
  check_minikube
  
  echo "=== Deleting Abstergo Application from Kubernetes ==="
  
  # Ask for confirmation
  read -p "This will delete the application from Kubernetes. Are you sure? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deletion cancelled."
    exit 0
  fi
  
  # Delete kubernetes resources
  echo "Deleting Kubernetes resources..."
  kubectl delete -f k8s/service.yaml
  kubectl delete -f k8s/deployment.yaml
  kubectl delete -f k8s/configmap.yaml
  
  echo "Application deleted successfully from Kubernetes!"
}

# Start Minikube with appropriate resources
start_minikube() {
  echo "=== Starting Minikube for Abstergo Application ==="
  
  # Check if minikube is already running
  if minikube status | grep -q "Running"; then
    echo "Minikube is already running."
    return 0
  fi
  
  echo "Starting Minikube with 1900MB memory and 2 CPUs..."
  minikube start --memory 1900 --cpus 2
  
  # Wait for minikube to be ready
  echo "Waiting for Minikube to be ready..."
  sleep 5
  
  # Verify minikube status
  minikube status
  
  echo "Minikube started successfully!"
}

# Display help
show_help() {
    echo "Abstergo Application Deployment Tool"
    echo ""
    echo "Usage: ./scripts/deploy.sh [command]"
    echo ""
    echo "Commands:"
    echo "  build      - Build Docker image"
    echo "  deploy     - Deploy application to Kubernetes"
    echo "  verify     - Verify deployment is working"
    echo "  delete     - Delete application from Kubernetes"
    echo "  start      - Start Minikube with appropriate resources"
    echo "  help       - Show this help message"
}

# Main command dispatcher
case "$COMMAND" in
    build)
        build_image
        ;;
    deploy)
        deploy_app
        ;;
    verify)
        verify_deployment
        ;;
    delete)
        delete_app
        ;;
    start)
        start_minikube
        ;;
    help|*)
        show_help
        ;;
esac 
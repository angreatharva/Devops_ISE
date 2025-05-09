#!/bin/bash
# Simple verification script for Abstergo application

echo "=== Verifying Abstergo Application Setup ==="

# Check for required commands
echo "Checking for required commands..."
commands=("docker" "kubectl" "helm" "minikube")
for cmd in "${commands[@]}"; do
  if command -v $cmd &> /dev/null; then
    echo "✓ $cmd is installed"
  else
    echo "⚠️ $cmd is not installed"
  fi
done

# Check for required files
echo
echo "Checking project structure..."
required_directories=("k8s" "monitoring" "scripts" "src")
for dir in "${required_directories[@]}"; do
  if [ -d "$dir" ]; then
    echo "✓ $dir/ directory exists"
  else
    echo "⚠️ $dir/ directory is missing!"
  fi
done

# Check for crucial files
echo
echo "Checking crucial files..."
crucial_files=("Dockerfile" "Dockerfile.metrics" "nginx.conf" "k8s/deployment.yaml" "k8s/service.yaml")
for file in "${crucial_files[@]}"; do
  if [ -f "$file" ]; then
    echo "✓ $file exists"
  else
    echo "⚠️ $file is missing!"
  fi
done

# Check for metrics implementation
echo
echo "Checking metrics implementation..."
if [ -f "src/metrics.js" ] && [ -f "src/metrics-server.js" ]; then
  echo "✓ Metrics files exist"
else
  echo "⚠️ Metrics files are missing!"
fi

# Check Kubernetes configuration
echo
echo "Checking Kubernetes configuration..."
if [ -f "k8s/service.yaml" ] && grep -q "port: 9113" k8s/service.yaml; then
  echo "✓ Metrics port configured in service.yaml"
else
  echo "⚠️ Metrics port configuration is missing!"
fi

# Check for sidecar metrics container
echo
echo "Checking deployment configuration..."
if [ -f "k8s/deployment.yaml" ] && grep -q "metrics-server" k8s/deployment.yaml; then
  echo "✓ Metrics sidecar container configured in deployment.yaml"
else
  echo "⚠️ Metrics sidecar container is missing in deployment.yaml!"
fi

echo
echo "=== Verification Complete ==="
echo
echo "To deploy the application, run the following commands:"
echo "1. ./scripts/deploy.sh start          # Start Minikube"
echo "2. ./scripts/build-images.sh --push   # Build and push Docker images"
echo "3. ./scripts/deploy.sh deploy         # Deploy to Kubernetes"
echo "4. ./scripts/monitoring.sh install    # Install monitoring"
echo "5. ./scripts/monitoring.sh access     # Access dashboards" 
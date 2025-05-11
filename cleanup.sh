#!/bin/bash

echo "Starting system cleanup..."

# Remove build artifacts and temporary files
echo "Cleaning build artifacts..."
rm -rf dist/
rm -rf build/
rm -rf .cache/
rm -rf coverage/

# Clean npm cache and remove node_modules (optional - uncomment if needed)
# echo "Cleaning npm cache..."
# npm cache clean --force
# rm -rf node_modules/

# Clean Docker resources
echo "Cleaning Docker resources..."
# Remove unused Docker images
docker image prune -f
# Remove unused containers
docker container prune -f
# Remove unused volumes
docker volume prune -f
# Remove unused networks
docker network prune -f

# Clean Kubernetes resources (if needed)
echo "Cleaning Kubernetes resources..."
kubectl delete pods --field-selector status.phase=Failed --all-namespaces
kubectl delete pods --field-selector status.phase=Succeeded --all-namespaces

# Remove any log files
echo "Cleaning log files..."
find . -name "*.log" -type f -delete
find . -name "*.log.*" -type f -delete

# Remove any temporary files
echo "Cleaning temporary files..."
find . -name "*.tmp" -type f -delete
find . -name "*.temp" -type f -delete
find . -name ".DS_Store" -type f -delete

# Clean up any remaining test files
echo "Cleaning test files..."
find . -name "test-*.xml" -type f -delete
find . -name "junit-*.xml" -type f -delete

echo "Cleanup completed!" 
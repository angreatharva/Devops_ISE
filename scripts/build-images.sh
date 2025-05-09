#!/bin/bash
# Script to build both Docker images for Abstergo Application

# Exit on error
set -e

# Default values
IMAGE_PREFIX="angreatharva"
APP_NAME="abstergo"
METRICS_NAME="abstergo-metrics"
INCREMENT_TAG=true
PUSH_IMAGES=false

# Print banner
echo "==============================================="
echo "  Abstergo Application - Docker Build Script   "
echo "==============================================="
echo

# Function to show help
show_help() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -p, --prefix PREFIX    Docker image prefix (default: angreatharva)"
  echo "  -t, --tag TAG          Use specific tag instead of incrementing"
  echo "  --push                 Push images to Docker registry after building"
  echo "  -h, --help             Show this help message"
  echo
  echo "Examples:"
  echo "  $0                     # Build with default settings"
  echo "  $0 --push              # Build and push images"
  echo "  $0 -t 42               # Build with specific tag 42"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -p|--prefix)
      IMAGE_PREFIX="$2"
      shift 2
      ;;
    -t|--tag)
      TAG="$2"
      INCREMENT_TAG=false
      shift 2
      ;;
    --push)
      PUSH_IMAGES=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Set the tags
if [ "$INCREMENT_TAG" = true ]; then
  # Get current tag from deployment.yaml
  CURRENT_TAG=$(grep -oP "image: ${IMAGE_PREFIX}/${APP_NAME}:\K[0-9]+" k8s/deployment.yaml || echo "1")
  
  # Increment tag for new build
  TAG=$((CURRENT_TAG + 1))
  echo "Incrementing tag to: $TAG"
else
  echo "Using specified tag: $TAG"
fi

APP_IMAGE="${IMAGE_PREFIX}/${APP_NAME}:${TAG}"
METRICS_IMAGE="${IMAGE_PREFIX}/${METRICS_NAME}:${TAG}"
APP_LATEST="${IMAGE_PREFIX}/${APP_NAME}:latest"
METRICS_LATEST="${IMAGE_PREFIX}/${METRICS_NAME}:latest"

# Build application image
echo "Building application image: $APP_IMAGE"
docker build -t "$APP_IMAGE" -f Dockerfile .
docker tag "$APP_IMAGE" "$APP_LATEST"

# Build metrics image
echo "Building metrics image: $METRICS_IMAGE"
docker build -t "$METRICS_IMAGE" -f Dockerfile.metrics .
docker tag "$METRICS_IMAGE" "$METRICS_LATEST"

# Update deployment.yaml with new tags
echo "Updating deployment.yaml with new tags"
sed -i "s|image: ${IMAGE_PREFIX}/${APP_NAME}:.*|image: ${IMAGE_PREFIX}/${APP_NAME}:${TAG}|g" k8s/deployment.yaml
sed -i "s|image: ${IMAGE_PREFIX}/${METRICS_NAME}:.*|image: ${IMAGE_PREFIX}/${METRICS_NAME}:${TAG}|g" k8s/deployment.yaml

# Push images if requested
if [ "$PUSH_IMAGES" = true ]; then
  echo "Pushing images to Docker registry"
  docker push "$APP_IMAGE"
  docker push "$APP_LATEST"
  docker push "$METRICS_IMAGE"
  docker push "$METRICS_LATEST"
fi

echo
echo "==============================================="
echo "  Build completed successfully!"
echo "  Application image: $APP_IMAGE"
echo "  Metrics image: $METRICS_IMAGE"
echo "===============================================" 
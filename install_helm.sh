#!/bin/bash
# Script to install Helm in Jenkins environment

echo "=== Installing Helm for Kubernetes package management ==="

# Get the latest Helm version
HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | cut -d '"' -f 4)
echo "Installing Helm version ${HELM_VERSION}"

# Download and install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Verify installation
helm version

echo "=== Helm installation complete ==="
echo "You can now run the Jenkins pipeline again to deploy monitoring" 
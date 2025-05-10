#!/bin/bash
# Cleanup script for Abstergo DevOps project
# This script removes legacy files and sets up proper Jenkins configuration

echo "=== Abstergo DevOps Project Cleanup ==="

# Remove legacy CI/CD files that are no longer needed as we're using Jenkins
echo "- Removing legacy CI/CD files"
if [ -f ".gitlab-ci.yml" ]; then
  rm -f .gitlab-ci.yml
  echo "  Removed .gitlab-ci.yml"
fi

# Clean up Docker cache if needed
echo "- Cleaning Docker cache"
docker system prune -f

# Create credentials in Jenkins if they don't exist
echo "- Jenkins credentials setup instructions:"
echo "  1. In Jenkins, navigate to Dashboard > Manage Jenkins > Credentials"
echo "  2. Create a credential with ID 'Docker' of type 'Username with password'"
echo "  3. Use your Docker Hub username and password/token for authentication"

# Setup Kubernetes connection if needed
echo "- Kubernetes connection setup:"
echo "  1. Ensure that Jenkins has access to your Kubernetes cluster configuration"
echo "  2. Default location for kubeconfig is at /var/lib/jenkins/.kube/config"
echo "  3. Run: 'sudo mkdir -p /var/lib/jenkins/.kube && sudo cp ~/.kube/config /var/lib/jenkins/.kube/'"
echo "  4. Run: 'sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube'"

echo ""
echo "=== Cleanup Complete ==="
echo "You can now run the Jenkins pipeline which should complete successfully" 
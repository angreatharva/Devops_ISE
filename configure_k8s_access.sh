#!/bin/bash
set -e

# This script configures Kubernetes access for Jenkins
# Run it from the Jenkins controller node as root

# Define directories
JENKINS_HOME="/var/lib/jenkins"
MINIKUBE_SOURCE="/home/atharva/.minikube"  # Source of Minikube certificates
JENKINS_MINIKUBE="${JENKINS_HOME}/.minikube"
JENKINS_KUBE="${JENKINS_HOME}/.kube"

# Create required directories
mkdir -p ${JENKINS_MINIKUBE}/profiles/minikube
mkdir -p ${JENKINS_KUBE}

# Copy Minikube certificates
echo "Copying Minikube certificates..."
if [ -d ${MINIKUBE_SOURCE} ]; then
    cp -f ${MINIKUBE_SOURCE}/ca.crt ${JENKINS_MINIKUBE}/ || echo "Warning: Cannot copy ca.crt"
    cp -f ${MINIKUBE_SOURCE}/profiles/minikube/client.* ${JENKINS_MINIKUBE}/profiles/minikube/ || echo "Warning: Cannot copy client certificates"
    
    # Set proper permissions
    chmod -R 644 ${JENKINS_MINIKUBE}/ca.crt
    chmod -R 644 ${JENKINS_MINIKUBE}/profiles/minikube/client.crt
    chmod -R 600 ${JENKINS_MINIKUBE}/profiles/minikube/client.key
    
    # Create kubeconfig for Jenkins
    echo "Creating kubeconfig file for Jenkins..."
    if [ -f ${MINIKUBE_SOURCE}/../.kube/config ]; then
        cp -f ${MINIKUBE_SOURCE}/../.kube/config ${JENKINS_KUBE}/config
    else
        # Try to generate a kubeconfig
        echo "No existing kubeconfig found, attempting to create one..."
        MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "")
        
        if [ -n "${MINIKUBE_IP}" ]; then
            cat > ${JENKINS_KUBE}/config << EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority: ${JENKINS_MINIKUBE}/ca.crt
    server: https://${MINIKUBE_IP}:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: ${JENKINS_MINIKUBE}/profiles/minikube/client.crt
    client-key: ${JENKINS_MINIKUBE}/profiles/minikube/client.key
EOF
        else
            echo "ERROR: Cannot determine Minikube IP. Is Minikube running?"
            exit 1
        fi
    fi
    
    # Set proper permissions for kubeconfig
    chmod 600 ${JENKINS_KUBE}/config
    
    # Set ownership
    chown -R jenkins:jenkins ${JENKINS_MINIKUBE}
    chown -R jenkins:jenkins ${JENKINS_KUBE}
    
    echo "Kubernetes configuration for Jenkins completed successfully!"
    echo "To validate, run as the jenkins user: kubectl cluster-info"
else
    echo "ERROR: Minikube configuration not found at ${MINIKUBE_SOURCE}"
    echo "Is Minikube installed and configured properly?"
    exit 1
fi
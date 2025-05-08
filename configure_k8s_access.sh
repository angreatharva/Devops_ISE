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
mkdir -p ${JENKINS_MINIKUBE}/machines/minikube
mkdir -p ${JENKINS_KUBE}

# Check which driver minikube is using
MINIKUBE_DRIVER=$(minikube profile list -o json 2>/dev/null | grep -o '"Driver":"[^"]*"' | head -1 | cut -d '"' -f 4 || echo "unknown")
echo "Detected Minikube driver: ${MINIKUBE_DRIVER}"

# Copy Minikube certificates and configuration files
echo "Copying Minikube certificates and configuration..."
if [ -d ${MINIKUBE_SOURCE} ]; then
    # Copy certificates regardless of driver
    cp -f ${MINIKUBE_SOURCE}/ca.crt ${JENKINS_MINIKUBE}/ 2>/dev/null || echo "Warning: Cannot copy ca.crt"
    cp -f ${MINIKUBE_SOURCE}/profiles/minikube/client.* ${JENKINS_MINIKUBE}/profiles/minikube/ 2>/dev/null || echo "Warning: Cannot copy client certificates"
    
    # Copy SSH keys if they exist (for older Minikube versions or non-Docker drivers)
    if [ -f ${MINIKUBE_SOURCE}/machines/minikube/id_rsa ]; then
        cp -f ${MINIKUBE_SOURCE}/machines/minikube/id_rsa* ${JENKINS_MINIKUBE}/machines/minikube/ 2>/dev/null || echo "Warning: Cannot copy SSH keys"
        chmod 600 ${JENKINS_MINIKUBE}/machines/minikube/id_rsa
        chmod 644 ${JENKINS_MINIKUBE}/machines/minikube/id_rsa.pub 2>/dev/null || true
    else
        echo "No SSH keys found, this is normal for Docker driver"
        
        # For Docker driver, create an empty file to prevent errors
        if [ "${MINIKUBE_DRIVER}" = "docker" ]; then
            touch ${JENKINS_MINIKUBE}/machines/minikube/id_rsa
            chmod 600 ${JENKINS_MINIKUBE}/machines/minikube/id_rsa
        fi
    fi
    
    # Set proper permissions
    chmod -R 644 ${JENKINS_MINIKUBE}/ca.crt 2>/dev/null || true
    chmod -R 644 ${JENKINS_MINIKUBE}/profiles/minikube/client.crt 2>/dev/null || true
    chmod -R 600 ${JENKINS_MINIKUBE}/profiles/minikube/client.key 2>/dev/null || true
    
    # Create kubeconfig for Jenkins
    echo "Creating kubeconfig file for Jenkins..."
    
    # If using Docker driver, we can use a simpler approach
    if [ "${MINIKUBE_DRIVER}" = "docker" ]; then
        # For Docker driver, we can just copy the config directly
        if [ -f "${MINIKUBE_SOURCE}/../.kube/config" ]; then
            cp -f "${MINIKUBE_SOURCE}/../.kube/config" "${JENKINS_KUBE}/config"
            # Modify the copied config to use absolute paths
            sed -i "s|${MINIKUBE_SOURCE}|${JENKINS_MINIKUBE}|g" "${JENKINS_KUBE}/config"
        else
            echo "ERROR: No kubeconfig found at ${MINIKUBE_SOURCE}/../.kube/config"
            echo "Please run 'minikube start' to ensure Minikube is configured"
            exit 1
        fi
    else
        # For other drivers, generate a config or copy existing one
        if [ -f ${MINIKUBE_SOURCE}/../.kube/config ]; then
            cp -f ${MINIKUBE_SOURCE}/../.kube/config ${JENKINS_KUBE}/config
            # Update paths in the config to point to Jenkins home
            sed -i "s|${MINIKUBE_SOURCE}|${JENKINS_MINIKUBE}|g" "${JENKINS_KUBE}/config"
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
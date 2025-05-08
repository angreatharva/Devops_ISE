#!/bin/bash
# fix_minikube_access.sh
#
# This script resolves permission issues with Minikube for Jenkins
# Run as root or with sudo

set -e

echo "======== Minikube Permissions Fix for Jenkins ========"
echo "This script will fix the permissions issue with Minikube and Jenkins."

# Define paths
JENKINS_USER="jenkins"
JENKINS_HOME="/var/lib/jenkins"
MINIKUBE_HOME="/home/atharva/.minikube"
USER_HOME="/home/atharva"
JENKINS_MINIKUBE="${JENKINS_HOME}/.minikube"
JENKINS_KUBE="${JENKINS_HOME}/.kube"

# Create necessary directories for Jenkins
mkdir -p ${JENKINS_MINIKUBE}/machines/minikube
mkdir -p ${JENKINS_MINIKUBE}/profiles/minikube
mkdir -p ${JENKINS_KUBE}

# 1. Check if Minikube is running
echo "Checking Minikube status..."
if ! su - atharva -c "minikube status" &>/dev/null; then
    echo "NOTE: Minikube is not running. Starting it..."
    su - atharva -c "minikube start"
fi

# 2. Get current Minikube driver
DRIVER=$(su - atharva -c "minikube profile list -o json" | grep -o '"Driver":"[^"]*"' | head -1 | cut -d '"' -f 4)
echo "Detected Minikube driver: ${DRIVER}"

# 3. Fix for Docker driver (which doesn't use SSH keys)
if [ "$DRIVER" = "docker" ]; then
    echo "Using Docker driver - creating configuration..."
    
    # Create dummy id_rsa file to prevent errors
    touch ${JENKINS_MINIKUBE}/machines/minikube/id_rsa
    chmod 600 ${JENKINS_MINIKUBE}/machines/minikube/id_rsa
    
    # Copy certificates and config
    cp -f ${MINIKUBE_HOME}/ca.crt ${JENKINS_MINIKUBE}/ 2>/dev/null || true
    cp -f ${MINIKUBE_HOME}/profiles/minikube/client.* ${JENKINS_MINIKUBE}/profiles/minikube/ 2>/dev/null || true
    
    # Copy and modify kubeconfig
    cp -f ${USER_HOME}/.kube/config ${JENKINS_KUBE}/config 2>/dev/null || true
    sed -i "s|${MINIKUBE_HOME}|${JENKINS_MINIKUBE}|g" ${JENKINS_KUBE}/config 2>/dev/null || true
else
    # For other drivers that use SSH
    echo "Using ${DRIVER} driver - copying required files..."
    
    # Copy SSH keys if they exist
    if [ -f ${MINIKUBE_HOME}/machines/minikube/id_rsa ]; then
        cp -f ${MINIKUBE_HOME}/machines/minikube/id_rsa* ${JENKINS_MINIKUBE}/machines/minikube/ 2>/dev/null || true
    else
        echo "WARNING: SSH key not found at ${MINIKUBE_HOME}/machines/minikube/id_rsa"
        echo "This may cause connection issues"
    fi
    
    # Copy certificates and config
    cp -f ${MINIKUBE_HOME}/ca.crt ${JENKINS_MINIKUBE}/ 2>/dev/null || true
    cp -f ${MINIKUBE_HOME}/profiles/minikube/client.* ${JENKINS_MINIKUBE}/profiles/minikube/ 2>/dev/null || true
    
    # Copy and adjust kubeconfig
    cp -f ${USER_HOME}/.kube/config ${JENKINS_KUBE}/config 2>/dev/null || true
    sed -i "s|${MINIKUBE_HOME}|${JENKINS_MINIKUBE}|g" ${JENKINS_KUBE}/config 2>/dev/null || true
fi

# 4. Fix permissions
echo "Setting correct permissions..."
chmod -R 644 ${JENKINS_MINIKUBE}/ca.crt 2>/dev/null || true
chmod -R 644 ${JENKINS_MINIKUBE}/profiles/minikube/client.crt 2>/dev/null || true
chmod -R 600 ${JENKINS_MINIKUBE}/profiles/minikube/client.key 2>/dev/null || true
chmod -R 600 ${JENKINS_MINIKUBE}/machines/minikube/id_rsa 2>/dev/null || true
chmod -R 644 ${JENKINS_MINIKUBE}/machines/minikube/id_rsa.pub 2>/dev/null || true
chmod 600 ${JENKINS_KUBE}/config 2>/dev/null || true

# 5. Set ownership to Jenkins
echo "Setting ownership to Jenkins user..."
chown -R ${JENKINS_USER}:${JENKINS_USER} ${JENKINS_MINIKUBE}
chown -R ${JENKINS_USER}:${JENKINS_USER} ${JENKINS_KUBE}

# 6. Test if Jenkins can access Minikube
echo "Testing if Jenkins can access Minikube..."
if su - ${JENKINS_USER} -c "kubectl get nodes" &>/dev/null; then
    echo "SUCCESS: Jenkins can now access Minikube!"
else
    echo "WARNING: Jenkins still cannot access Minikube. Manual configuration may be needed."
    echo "Try running: sudo -u jenkins kubectl get nodes"
    echo "to see specific errors."
fi

echo ""
echo "=== IMPORTANT: Add Jenkins to the Docker group ==="
echo "If you're using Docker driver, make sure Jenkins user is in the docker group:"
echo "    sudo usermod -aG docker jenkins"
echo "    sudo systemctl restart jenkins"
echo ""

echo "Script completed!" 
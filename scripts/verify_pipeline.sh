#!/bin/bash
# Pipeline verification script

echo "=== Verifying Abstergo Pipeline Setup ==="

# Verify Kubernetes deployment files
echo "1. Checking deployment files..."
if [ ! -f "k8s/deployment.yaml" ]; then
    echo "ERROR: k8s/deployment.yaml not found!"
    exit 1
fi

if [ ! -f "k8s/service.yaml" ]; then
    echo "ERROR: k8s/service.yaml not found!"
    exit 1
fi

# Basic YAML validation (syntax only)
echo "2. Validating YAML syntax..."
if command -v yamllint &> /dev/null; then
    echo "Using yamllint for validation..."
    if ! yamllint -d relaxed k8s/deployment.yaml 2>/dev/null; then
        echo "ERROR: Invalid syntax in deployment.yaml"
        yamllint -d relaxed k8s/deployment.yaml
        exit 1
    fi

    if ! yamllint -d relaxed k8s/service.yaml 2>/dev/null; then
        echo "ERROR: Invalid syntax in service.yaml"
        yamllint -d relaxed k8s/service.yaml
        exit 1
    fi
else
    echo "yamllint not found, skipping YAML validation"
    echo "TIP: Install yamllint for better validation (sudo apt install yamllint)"
    
    # Simple check for YAML formatting errors
    echo "Performing basic syntax check..."
    if ! grep -q "apiVersion:" k8s/deployment.yaml || ! grep -q "kind:" k8s/deployment.yaml; then
        echo "ERROR: deployment.yaml appears to be missing required fields"
        exit 1
    fi
    
    if ! grep -q "apiVersion:" k8s/service.yaml || ! grep -q "kind:" k8s/service.yaml; then
        echo "ERROR: service.yaml appears to be missing required fields"
        exit 1
    fi
fi

# Check for monitoring configuration
echo "3. Checking monitoring configuration..."
if [ ! -f "k8s/servicemonitor.yaml" ]; then
    echo "ERROR: k8s/servicemonitor.yaml not found!"
    exit 1
fi

if [ ! -f "k8s/grafana-dashboard.yaml" ]; then
    echo "ERROR: k8s/grafana-dashboard.yaml not found!"
    exit 1
fi

if [ ! -f "monitoring/minimal-monitoring-values.yaml" ]; then
    echo "ERROR: monitoring/minimal-monitoring-values.yaml not found!"
    exit 1
fi

# Check for Docker images
echo "4. Checking for Docker configuration..."
if [ ! -f "Dockerfile" ]; then
    echo "ERROR: Dockerfile not found!"
    exit 1
fi

if [ ! -f "Dockerfile.metrics" ]; then
    echo "ERROR: Dockerfile.metrics not found!"
    exit 1
fi

# Verify directories and files
echo "5. Checking project structure..."
required_dirs=("k8s" "monitoring" "scripts" "src")
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "ERROR: Required directory '$dir' not found!"
        exit 1
    fi
done

required_files=("Dockerfile" "Dockerfile.metrics" "Jenkinsfile")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Required file '$file' not found!"
        exit 1
    fi
done

# Verify metrics configuration
echo "6. Checking metrics configuration..."
if ! grep -q "containerPort: 9113" k8s/deployment.yaml; then
    echo "ERROR: Metrics port not properly configured in deployment.yaml"
    exit 1
fi

if ! grep -q "port: metrics" k8s/servicemonitor.yaml; then
    echo "ERROR: Service monitor not correctly configured"
    exit 1
fi

echo "7. Checking if service port configurations match..."
if ! grep -A3 "port: 9113" k8s/service.yaml | grep -q "name: metrics"; then
    echo "ERROR: Service does not have proper metrics port configuration"
    echo "Port 9113 should have name: metrics"
    exit 1
fi

# Check Jenkinsfile for required stages
echo "8. Checking Jenkinsfile configuration..."
if ! grep -q "stage('Setup Monitoring')" Jenkinsfile; then
    echo "ERROR: Jenkinsfile missing 'Setup Monitoring' stage"
    exit 1
fi

if ! grep -q "minimal-monitoring-values.yaml" Jenkinsfile; then
    echo "WARNING: Jenkinsfile may not be referencing monitoring values file correctly"
fi

echo "=== Verification complete! All required components are in place ==="
echo "Your pipeline should now run successfully."
echo ""
echo "You can run this script before submitting to Jenkins to avoid pipeline failures." 
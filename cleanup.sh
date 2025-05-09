#!/bin/bash
# Cleanup script to remove unnecessary files from the codebase

# Print information
echo "=== Cleaning up unnecessary files from the codebase ==="

# Old build system files
echo "Removing old build system files..."
rm -f build.xml
rm -f build.properties
rm -f pom.xml

# Legacy/unused files
echo "Removing legacy/unused files..."
rm -f addressbook_screenshot.png
rm -f metrics-exporter.js

# Temporary files
echo "Removing temporary files..."
rm -rf tmp/

# Check and confirm 
echo "=== Cleanup completed ==="
echo "The following files were kept:"
echo " - Dockerfile (needed for building the container)"
echo " - Jenkinsfile (needed for CI/CD pipeline)"
echo " - fix_minikube_access.sh (needed for Kubernetes access)"
echo " - Jenkins configuration files"
echo " - Kubernetes manifests"
echo " - Application source code"

echo "You can safely remove this script after running it with:"
echo "rm cleanup.sh" 
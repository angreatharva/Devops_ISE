# Abstergo DevOps Scripts

This directory contains scripts for managing and monitoring the Abstergo application.

## System Resource Management

Before running scripts that interact with Kubernetes, check your system resources. Minikube requires significant memory and CPU, and running it in a resource-constrained environment can cause issues.

Current minimum requirements:
- 2GB RAM
- 2 CPU cores

## Available Scripts

### Status and Information

- **`system_status.sh`** - Comprehensive system status checker
  - Shows status of Minikube, Kubernetes, application, and monitoring
  - Displays system resource usage
  - Lists available scripts

- **`check_monitoring_status.sh`** - Check status of monitoring components
  - Works even when Minikube is not running
  - Provides instructions for accessing monitoring

### Access and Testing

- **`access_monitoring.sh`** - Access Prometheus and Grafana dashboards
  - Creates port-forwarding to monitoring services
  - Provides login credentials for Grafana
  - *Requires Minikube to be running*

- **`generate_test_data.sh`** - Generate test traffic for application
  - Can work with cached URL even when Minikube is stopped
  - Sends requests to various endpoints to generate metrics
  - Gracefully handles connection failures

### Installation

- **`install_minimal_monitoring.sh`** - Install monitoring with minimal resources
  - Uses resource-optimized configurations
  - Installs Prometheus and Grafana in monitoring namespace
  - Sets up ServiceMonitor for Abstergo application

## Tips for Low-Resource Environments

1. When not actively using the application, keep Minikube stopped
2. Before starting Minikube, close other resource-intensive applications
3. Use the minimal monitoring configuration to reduce resource usage
4. Consider increasing your system's swap space if available memory is limited

## Error Handling

Most scripts include error handling that will:
1. Check prerequisites before executing actions
2. Provide clear error messages and suggested solutions
3. Offer alternatives for resource-constrained environments

## Documentation

For more detailed information about the application and monitoring setup, refer to the main project README file. 
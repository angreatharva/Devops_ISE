# Abstergo Monitoring Quickstart Guide

This guide provides quick steps for getting monitoring up and running for the Abstergo application.

## System Requirements

Minimum requirements for running monitoring:
- 2GB RAM
- 2 CPU cores

These are in addition to the resources needed for the application itself. If your system is resource-constrained, use the minimal configuration provided.

## Installation

### Standard Installation

```bash
# From the project root
./scripts/install_minimal_monitoring.sh
```

This script:
1. Adds the Prometheus Helm repository
2. Installs Prometheus and Grafana with minimal resource settings
3. Applies ServiceMonitor for the Abstergo application
4. Configures Grafana dashboards

The installation uses the `minimal-monitoring-values.yaml` configuration which is optimized for resource-constrained environments.

## Accessing Dashboards

To access the Prometheus and Grafana dashboards:

```bash
# From the project root
./scripts/access_monitoring.sh
```

### Grafana Access

- URL: http://localhost:3000 (or another port if 3000 is in use)
- Username: admin
- Password: prom-operator

## Generating Test Data

To generate test data for the dashboards:

```bash
# From the project root
./scripts/generate_test_data.sh
```

This will send requests to various endpoints to generate metrics data that will appear in the dashboards.

## Troubleshooting

### Port Forwarding Issues

If you see "address already in use" errors:
1. Check for existing port-forwarding: `ps aux | grep port-forward`
2. Kill any existing port-forwarding processes: `kill <PID>`
3. Try using a different port: `kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80`

### Pod Status Issues

To check the status of the monitoring pods:

```bash
kubectl get pods -n monitoring
```

If pods are not starting due to resource constraints:
1. Stop other applications to free up resources
2. Restart Minikube with more resources: `minikube stop && minikube start --memory=2048m --cpus=2`

### Connection Refused

If you see "Connection refused" errors:
1. Make sure all pods are running: `kubectl get pods -n monitoring`
2. Check pod logs: `kubectl logs -n monitoring <pod-name>`
3. Restart problematic pods: `kubectl delete pod -n monitoring <pod-name>`

## Resource Management

If you're experiencing resource constraints:

1. When not using the application, stop Minikube: `minikube stop`
2. To see the current system status, run: `./scripts/system_status.sh`
3. Use the minimal monitoring configuration to reduce resource usage

## Further Information

For detailed information about the monitoring configuration, examine:
- `monitoring/minimal-monitoring-values.yaml` - Resource-optimized configuration
- `k8s/servicemonitor.yaml` - Prometheus ServiceMonitor for app metrics
- `k8s/grafana-dashboard.yaml` - Custom Grafana dashboard configuration 
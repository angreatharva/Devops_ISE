# Monitoring Setup for React Application

This directory contains the necessary files to set up monitoring for the React application using Prometheus and Grafana.

## Prerequisites

- Kubernetes cluster running
- Helm installed
- kubectl configured to communicate with your cluster

## Components

1. **Prometheus**: Collects and stores metrics
2. **Grafana**: Visualizes metrics and creates dashboards
3. **AlertManager**: Manages alerts based on metrics
4. **ServiceMonitor**: Custom resource to monitor the React application
5. **PrometheusRule**: Defines alert rules for the application

## Files

- `setup-monitoring.sh`: Installs Prometheus and Grafana stack using Helm
- `deploy-monitoring.sh`: Deploys custom monitoring resources
- `react-app-servicemonitor.yaml`: ServiceMonitor configuration for the React app
- `react-grafana-dashboard-configmap.yaml`: Grafana dashboard configurations
- `alert-rules.yaml`: Prometheus alert rules

## Setup Instructions

1. Make the scripts executable:

   ```bash
   chmod +x setup-monitoring.sh deploy-monitoring.sh
   ```

2. Run the deployment script:

   ```bash
   ./deploy-monitoring.sh
   ```

   This will:
   - Install Prometheus and Grafana stack if not already installed
   - Apply the custom ServiceMonitor for the React app
   - Apply Grafana dashboards
   - Apply alert rules

3. Access the dashboards:

   For Grafana:
   ```bash
   kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
   ```
   Then open http://localhost:3000 in your browser.

   For Prometheus:
   ```bash
   kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
   ```
   Then open http://localhost:9090 in your browser.

## Metrics Available

The React application exposes the following metrics:

- `http_requests_total`: Total number of HTTP requests
- `http_request_duration_seconds`: Duration of HTTP requests
- `frontend_errors_total`: Total number of frontend errors
- `api_errors_total`: Total number of API errors
- `page_views_total`: Total number of page views
- `user_interactions_total`: Total number of user interactions

## Alert Rules

The following alert rules are configured:

- **HighErrorRate**: Alerts when error rate is above 10% for 5 minutes
- **SlowResponseTime**: Alerts when response time is above 2 seconds for 5 minutes
- **HighMemoryUsage**: Alerts when memory usage is above 80% for 15 minutes
- **PodRestarting**: Alerts when pod restarts more than 2 times in 15 minutes
- **FrontendJSErrors**: Alerts when frontend JS errors occur

## Troubleshooting

If the ServiceMonitor is not picking up metrics:

1. Check that the labels match between the ServiceMonitor and your application service
2. Verify that the endpoints are correct in the ServiceMonitor
3. Check that the metrics port is exposed in your application
4. Use `kubectl logs` to check for errors in Prometheus 
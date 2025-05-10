# Abstergo Application Monitoring Guide

This document provides a comprehensive guide to the monitoring setup for the Abstergo application.

## Overview

The Abstergo application monitoring stack consists of:

1. **Prometheus** - For metrics collection and storage
2. **Grafana** - For metrics visualization and dashboards
3. **ServiceMonitor** - For automatic discovery of metrics endpoints
4. **PrometheusRules** - For alerting on critical metrics

## Metrics Collected

The Abstergo application exposes the following metrics:

- `http_requests_total` - Total number of HTTP requests (labeled by method, path, status_code)
- `http_request_duration_seconds` - Duration of HTTP requests (labeled by method, path, status_code)
- `frontend_errors_total` - Total number of frontend errors (labeled by type)
- `api_errors_total` - Total number of API errors (labeled by endpoint, status_code)
- `page_views_total` - Total number of page views (labeled by page)
- `user_interactions_total` - Total number of user interactions (labeled by component, action)

## Monitoring Setup

### Prerequisites

- Kubernetes cluster (Minikube recommended for local development)
- kubectl
- Helm

### Installation

For standard installation:
```bash
./scripts/monitoring.sh
```

For minimal resource installation (recommended for resource-constrained environments):
```bash
./scripts/install_minimal_monitoring.sh
```

### Accessing Dashboards

To access the Grafana and Prometheus dashboards:
```bash
./scripts/access_monitoring.sh
```

This will provide you with:
- Grafana URL
- Login credentials
- Application URL

### Generating Test Data

To generate test traffic for monitoring:
```bash
./scripts/generate_test_data.sh
```

### Applying Alerts

To apply the predefined alerts:
```bash
./scripts/apply_alerts.sh
```

## Alerts

The following alerts are configured:

1. **AbstergoHighErrorRate** - Triggers when the error rate exceeds 5% for more than 2 minutes
2. **AbstergoHighResponseTime** - Triggers when the 95th percentile of response time exceeds 3 seconds for more than 5 minutes
3. **AbstergoContainerRestarting** - Triggers when containers restart within a 15-minute window
4. **AbstergoHighMemoryUsage** - Triggers when memory usage exceeds 85% of the limit for more than 5 minutes

## Resource Optimization

The monitoring stack is configured with minimal resource requirements to run on resource-constrained environments:

- Prometheus: 100Mi memory, 50m CPU
- Grafana: 50Mi memory, 50m CPU
- Prometheus Operator: 50Mi memory, 25m CPU
- Node Exporter: 15Mi memory, 25m CPU
- Kube State Metrics: 25Mi memory, 25m CPU

## Troubleshooting

### Common Issues

1. **Monitoring pods not starting**
   - Check if you have enough resources: `kubectl describe pods -n monitoring`
   - Consider increasing Minikube resources: `minikube start --memory=2048m --cpus=2`

2. **Metrics not showing in Grafana**
   - Verify the ServiceMonitor is correctly configured: `kubectl get servicemonitor -n monitoring`
   - Check if the metrics endpoint is accessible: `kubectl port-forward svc/abstergo-service 9113:9113` and then `curl localhost:9113/metrics`

3. **Alerts not triggering**
   - Verify the PrometheusRule is correctly configured: `kubectl get prometheusrules -n monitoring`
   - Check if Prometheus is correctly evaluating the rules: Access Prometheus UI and go to Status > Rules

### Getting Help

For additional help, run:
```bash
./scripts/check_monitoring_status.sh
```

This will provide a detailed report on the status of your monitoring setup. 
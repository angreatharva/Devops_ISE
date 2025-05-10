# Abstergo Application

A simple React application with Kubernetes deployment and monitoring setup.

## Project Structure

```
.
├── Dockerfile                # Docker image configuration
├── README.md                 # This file
├── eslint.config.js          # ESLint configuration
├── k8s                       # Kubernetes manifests
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── servicemonitor.yaml   # Prometheus ServiceMonitor
│   └── grafana-dashboard.yaml # Grafana dashboard
├── monitoring                # Monitoring configuration
│   ├── dashboard.yaml        # Grafana dashboard definition
│   ├── servicemonitor.yaml   # Prometheus ServiceMonitor template
│   ├── values.yaml           # Prometheus Operator values
│   ├── minimal-monitoring-values.yaml # Resource-optimized values
│   ├── alerts.yaml           # Prometheus alerting rules
│   └── MONITORING_GUIDE.md   # Comprehensive monitoring guide
├── package.json              # Node.js dependencies
├── scripts                   # Utility scripts
│   ├── deploy.sh             # Deployment script
│   ├── monitoring.sh         # Monitoring script
│   ├── install_minimal_monitoring.sh # Minimal resource monitoring
│   ├── access_monitoring.sh  # Dashboard access script
│   ├── generate_test_data.sh # Test traffic generator
│   ├── check_monitoring_status.sh # Monitoring status checker
│   ├── apply_alerts.sh       # Apply Prometheus alerts
│   └── verify.sh             # Verification script
├── public                    # Static web assets
└── src                       # Source code
    ├── App.jsx               # Main application component
    ├── App.css               # Application styles
    ├── main.jsx              # Entry point
    ├── index.css             # Global styles
    ├── metrics.js            # Prometheus metrics
    ├── metrics-server.js     # Metrics server
    ├── assets                # Images & other assets
    └── components            # React components
```

## Getting Started

1. **Verify Setup**:

   ```bash
   ./scripts/verify.sh
   ```

2. **Start Minikube**:

   ```bash
   ./scripts/deploy.sh start
   ```

3. **Build and Deploy the Application**:

   ```bash
   ./scripts/deploy.sh build
   ./scripts/deploy.sh deploy
   ```

4. **Verify the Deployment**:

   ```bash
   ./scripts/deploy.sh verify
   ```

5. **Setup Monitoring**:

   For standard environments:
   ```bash
   ./scripts/monitoring.sh install
   ```
   
   For resource-constrained environments:
   ```bash
   ./scripts/install_minimal_monitoring.sh
   ```

6. **Access the Dashboards**:

   ```bash
   ./scripts/access_monitoring.sh
   ```

7. **Generate Test Data (Optional)**:

   ```bash
   ./scripts/generate_test_data.sh
   ```

8. **Apply Alerting Rules (Optional)**:

   ```bash
   ./scripts/apply_alerts.sh
   ```

9. **Check Monitoring Status**:

   ```bash
   ./scripts/check_monitoring_status.sh
   ```

## Key Features

- React-based frontend
- Metrics collection with Prometheus
- Visualization with Grafana
- Resource-efficient monitoring setup
- Kubernetes deployment
- Prometheus alerting rules
- Comprehensive monitoring guide

## Monitoring

The application exposes Prometheus metrics at the `/metrics` endpoint on port 9113. The monitoring setup includes:

- Prometheus for metrics collection
- Grafana for visualization
- Custom dashboard for application metrics
- ServiceMonitor for automatic metrics scraping
- Alerting rules for critical metrics
- Resource-optimized configurations for limited environments

For detailed information about the monitoring setup, see [monitoring/MONITORING_GUIDE.md](monitoring/MONITORING_GUIDE.md).

## Metrics Collected

The application collects the following metrics:

- `http_requests_total` - Total number of HTTP requests
- `http_request_duration_seconds` - Duration of HTTP requests
- `frontend_errors_total` - Total number of frontend errors
- `api_errors_total` - Total number of API errors
- `page_views_total` - Total number of page views
- `user_interactions_total` - Total number of user interactions

## Alerts

The monitoring setup includes the following alerts:

- `AbstergoHighErrorRate` - Triggers when the error rate exceeds 5%
- `AbstergoHighResponseTime` - Triggers when response time exceeds thresholds
- `AbstergoContainerRestarting` - Triggers when containers restart unexpectedly
- `AbstergoHighMemoryUsage` - Triggers when memory usage is too high

## Resource Optimization

The monitoring stack is configured with minimal resource requirements to run on resource-constrained environments:

- Prometheus: 100Mi memory, 50m CPU
- Grafana: 50Mi memory, 50m CPU
- Prometheus Operator: 50Mi memory, 25m CPU

## Cleanup

To clean up resources:

```bash
./scripts/monitoring.sh cleanup   # Remove monitoring resources
./scripts/deploy.sh delete        # Remove application from Kubernetes
```

## Pipeline Fixes

The following issues were fixed in the Jenkins pipeline:

1. **YAML Syntax Error in service.yaml**: Fixed indentation issue in the service port configuration.

2. **Duplicate Port Definition in deployment.yaml**: Removed duplicate containerPort 9113 from the main container, keeping it only in the metrics container.

3. **Path References**: Updated file paths in the Jenkinsfile to correctly reference monitoring configuration files, with fallback paths.

4. **Monitoring Configuration**: Enhanced the monitoring setup to handle different directory structures and added error handling.

5. **Verification Script**: Added a verification script (`scripts/verify_pipeline.sh`) to check for common errors before running the pipeline.

To verify the configuration before running the pipeline:

```bash
./scripts/verify_pipeline.sh
```

## Running the Pipeline

The pipeline has several stages:

1. **Prepare**: Sets the build number
2. **Build**: Builds the Docker images for the main app and metrics server
3. **Update Deployment**: Updates the Kubernetes deployment files with the current version
4. **Deploy**: Deploys the application to Kubernetes
5. **Setup Monitoring**: Configures Prometheus and Grafana for monitoring
6. **Cleanup**: Removes local Docker images

## Monitoring

The application is monitored using Prometheus and Grafana. The metrics are exposed on port 9113 and collected by Prometheus using ServiceMonitor.

To access the Grafana dashboard:

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Then open http://localhost:3000 in your browser (default credentials: admin/prom-operator).

## Abstergo DevOps Project

This repository contains a web application with Kubernetes deployment configurations and monitoring setup using Prometheus and Grafana.

### Recent Changes and Improvements

- Fixed Jenkins pipeline to properly update image versions in deployment files
- Added script to clean up old Docker images to free up system resources
- Improved monitoring access script to properly wait for Grafana to be ready
- Fixed deployment file to use the correct image versions
- Added test data generator script to visualize metrics in Grafana
- Created manual deployment script for local testing

### System Requirements

- Docker
- Kubernetes (minikube)
- Helm
- 2GB+ RAM available for minikube
- kubectl

### Available Scripts

- `scripts/verify_pipeline.sh` - Verifies that all required files are present and configured correctly
- `scripts/access_monitoring.sh` - Provides access to Grafana dashboard with proper credentials
- `scripts/generate_test_data.sh` - Generates test traffic to visualize metrics
- `scripts/cleanup_docker_images.sh` - Cleans up old Docker images to free up system resources
- `scripts/manual_deploy.sh` - Deploys the application locally without requiring Jenkins

### How to Use

1. Verify your pipeline setup:
   ```
   bash scripts/verify_pipeline.sh
   ```

2. For manual deployment (without Jenkins):
   ```
   bash scripts/manual_deploy.sh
   ```

3. Access the monitoring dashboard:
   ```
   bash scripts/access_monitoring.sh
   ```

4. Generate test traffic:
   ```
   bash scripts/generate_test_data.sh
   ```

5. Clean up Docker images:
   ```
   bash scripts/cleanup_docker_images.sh
   ```

### Troubleshooting Issues

#### External IP stays in "pending" state
This is normal behavior in minikube. For minikube, you should access services using:
```
minikube service abstergo-service --url
```

#### Cannot access Grafana
Make sure to use the correct service name for port forwarding:
```
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

#### Container restarts or OOM errors
Reduce resource requirements in the deployment:
```
kubectl edit deployment abstergo-app
```
And adjust the resource limits and requests.

#### Jenkins pipeline fails to update image versions
This has been fixed in the latest version of the Jenkinsfile. The sed command now correctly updates the version numbers.


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
│   └── service.yaml
├── monitoring                # Monitoring configuration
│   ├── dashboard.yaml        # Grafana dashboard
│   ├── servicemonitor.yaml   # Prometheus ServiceMonitor
│   └── values.yaml           # Prometheus Operator values
├── package.json              # Node.js dependencies
├── scripts                   # Utility scripts
│   ├── deploy.sh             # Deployment script
│   ├── monitoring.sh         # Monitoring script
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

   ```bash
   ./scripts/monitoring.sh install
   ```

6. **Access the Dashboards**:

   ```bash
   ./scripts/monitoring.sh access
   ```

7. **Generate Test Data (Optional)**:

   ```bash
   ./scripts/monitoring.sh generate
   ```

## Key Features

- React-based frontend
- Metrics collection with Prometheus
- Visualization with Grafana
- Resource-efficient monitoring setup
- Kubernetes deployment

## Monitoring

The application exposes Prometheus metrics at the `/metrics` endpoint on port 9113. The monitoring setup includes:

- Prometheus for metrics collection
- Grafana for visualization
- Custom dashboard for application metrics
- ServiceMonitor for automatic metrics scraping

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


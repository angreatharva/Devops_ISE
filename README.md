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


# Abstergo Monitoring

This directory contains configurations and scripts for monitoring the Abstergo application using Prometheus and Grafana.

## Monitoring Components

- **Prometheus**: Collects and stores metrics from the application
- **Grafana**: Provides visualization of metrics
- **ServiceMonitor**: Kubernetes custom resource that tells Prometheus what to scrape
- **Dashboard**: Pre-configured Grafana dashboard for Abstergo app metrics

## Installation Options

### Standard Installation

```bash
./scripts/monitoring.sh install
```

This installs the full monitoring stack with standard resource requirements.

### Minimal Installation (for resource-constrained environments)

```bash
./scripts/install_minimal_monitoring.sh
```

This installs a minimal monitoring stack with reduced resource requirements, suitable for:
- Development environments
- CI/CD pipelines
- Systems with limited resources

### CI/CD Installation (Jenkins)

The pipeline automatically installs monitoring using `jenkins-monitoring.sh`, which is specifically designed to work in CI/CD environments.

## Resource Requirements

- **Standard Installation**: ~1GB RAM, ~500m CPU
- **Minimal Installation**: ~300MB RAM, ~200m CPU

## Accessing Dashboards

```bash
./scripts/monitoring.sh access
```

This command sets up port-forwarding to access Grafana and Prometheus dashboards.

## Generating Test Data

```bash
./scripts/monitoring.sh generate
```

Generates test traffic to the application so you can see metrics in the dashboards.

## Cleanup

```bash
./scripts/monitoring.sh cleanup
```

Removes all monitoring resources from the cluster. 
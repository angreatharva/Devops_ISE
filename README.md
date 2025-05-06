# Abstergo Corp Online Shopping Portal

This repository contains the codebase for Abstergo Corp's online shopping portal along with the CI/CD pipeline for automated deployment.

## DevOps Pipeline Architecture

The CI/CD pipeline consists of the following components:

1. **GitHub** - Source code repository
2. **Jenkins** - CI/CD orchestration
3. **Docker Hub** - Container image registry
4. **Kubernetes** - Container orchestration for deployment

## Pipeline Stages

1. **Compile** - Install dependencies and prepare the codebase
2. **Code Review** - Run linting and static code analysis
3. **Test** - Run automated tests
4. **Metric Check** - Check code quality metrics
5. **Package** - Build the application
6. **Docker** - Build and push Docker image
7. **Kubernetes Deploy** - Deploy the application to Kubernetes cluster

## Setup Instructions

### Prerequisites

- Jenkins with Docker and Kubernetes plugins
- Access to a Kubernetes cluster
- Docker Hub account
- GitHub repository

### Jenkins Credentials Setup

1. Add Docker Hub credentials as "docker-hub-credentials"
2. Add Kubernetes config file as "kubeconfig"

### Kubernetes Setup

1. Create a namespace for the application:
   ```
   kubectl create namespace abstergo
   ```

2. Apply the Kubernetes manifests:
   ```
   kubectl apply -f k8s/
   ```

### Jenkins Pipeline Setup

1. Create a new Jenkins pipeline job
2. Configure it to use the Jenkinsfile from the repository
3. Configure build triggers to trigger on GitHub webhook events

## Accessing the Application

After successful deployment, the application will be available at the LoadBalancer IP address of the Kubernetes service:

```
kubectl get service abstergo-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

# React + Vite

Devops ISE 

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react/README.md) uses [Babel](https://babeljs.io/) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh


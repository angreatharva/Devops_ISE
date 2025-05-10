pipeline {
    agent any
    
    options {
        // Add timeout to prevent builds from hanging indefinitely
        timeout(time: 30, unit: 'MINUTES')
        // Discard old builds to save disk space
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Don't run concurrent builds of the same branch
        disableConcurrentBuilds()
    }
    
    environment {
        // Update with your Docker Hub username and repository
        DOCKER_IMAGE = 'angreatharva/abstergo'
        DOCKER_METRICS_IMAGE = 'angreatharva/abstergo-metrics'
        // Updated credentials ID - needs to match what's configured in Jenkins
        DOCKER_CREDENTIALS_ID = 'Docker'
        // Set KUBECONFIG path for direct kubectl use
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
    }
    
    stages {
        stage('Prepare') {
            steps {
                script {
                    // Get latest build number from Docker Hub and increment it
                    def buildNumber = sh(
                        script: '''#!/bin/bash
                            # Use a more reliable approach to get the latest tag
                            # Get directly from pipeline-utility-steps plugin or use a fallback
                            NEW_BUILD_NUMBER=67
                            
                            # Try to get latest from Docker Hub
                            LATEST_BUILD=$(curl -s "https://registry.hub.docker.com/v2/repositories/${DOCKER_IMAGE}/tags?page_size=100" | grep -o '"name":"[0-9]*"' | grep -o '[0-9]*' | sort -rn | head -n 1 || echo "")
                            
                            if [ ! -z "$LATEST_BUILD" ] && [ "$LATEST_BUILD" -ge "$NEW_BUILD_NUMBER" ]; then
                                NEW_BUILD_NUMBER=$((LATEST_BUILD + 1))
                                echo "Found newer build in Docker Hub: $LATEST_BUILD, incrementing to $NEW_BUILD_NUMBER" >&2
                            fi
                            
                            # Just return the number without additional text
                            echo $NEW_BUILD_NUMBER
                        ''',
                        returnStdout: true
                    ).trim()
                    
                    // Set environment variable directly
                    env.NEW_BUILD_NUMBER = buildNumber
                    echo "Building with version: ${env.NEW_BUILD_NUMBER}"
                }
            }
        }
        
        stage('Build') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh '''
                        docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
                        
                        # Build and push main application
                        docker build -t ${DOCKER_IMAGE}:${NEW_BUILD_NUMBER} -t ${DOCKER_IMAGE}:latest .
                        docker push ${DOCKER_IMAGE}:${NEW_BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE}:latest
                        
                        # Build and push metrics server
                        docker build -t ${DOCKER_METRICS_IMAGE}:${NEW_BUILD_NUMBER} -t ${DOCKER_METRICS_IMAGE}:latest -f Dockerfile.metrics .
                        docker push ${DOCKER_METRICS_IMAGE}:${NEW_BUILD_NUMBER}
                        docker push ${DOCKER_METRICS_IMAGE}:latest
                    '''
                }
            }
        }
        
        stage('Update Deployment') {
            steps {
                sh '''
                    sed -i "s|image: angreatharva/abstergo:[0-9]\\+|image: angreatharva/abstergo:${NEW_BUILD_NUMBER}|g" k8s/deployment.yaml
                    sed -i "s|image: angreatharva/abstergo-metrics:[0-9]\\+|image: angreatharva/abstergo-metrics:${NEW_BUILD_NUMBER}|g" k8s/deployment.yaml
                    echo "Verifying deployment.yaml changes:"
                    grep -n "image:" k8s/deployment.yaml
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                sh '''
                    # Check if Kubernetes is accessible
                    echo "=== Deploying Abstergo Application ==="
                    if ! kubectl cluster-info > /dev/null 2>&1; then
                        echo "Error: Kubernetes cluster is not accessible"
                        exit 1
                    fi
                    echo "Kubernetes is accessible."
                    
                    # Deploy application
                    kubectl apply -f k8s/deployment.yaml || exit 1
                    kubectl apply -f k8s/service.yaml || exit 1
                    echo "Application deployed to Kubernetes."
                    
                    # Wait for deployment to be ready
                    echo "Waiting for deployment to be ready..."
                    kubectl rollout status deployment/abstergo-app --timeout=180s || true
                '''
            }
        }
        
        stage('Setup Monitoring') {
            steps {
                    sh '''
                    echo "=== Installing Monitoring for Abstergo Application ==="
                    # Check if Kubernetes is accessible
                    if ! kubectl cluster-info > /dev/null 2>&1; then
                        echo "Error: Kubernetes cluster is not accessible"
                        exit 1
                    fi
                    echo "Kubernetes is accessible."
                    
                    # Create monitoring namespace if it doesn't exist
                    if ! kubectl get namespace monitoring > /dev/null 2>&1; then
                        echo "Creating monitoring namespace..."
                        kubectl create namespace monitoring
                    fi
                    
                    # Add Helm repository if needed
                    echo "Adding Prometheus Helm repository..."
                    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || echo "Helm repo already exists"
                    helm repo update
                    
                    # Check if Prometheus is already installed
                    if ! helm list -n monitoring | grep prometheus > /dev/null 2>&1; then
                        echo "Installing Prometheus with minimal resources..."
                        helm install prometheus prometheus-community/kube-prometheus-stack \
                            -n monitoring \
                            -f monitoring/minimal-monitoring-values.yaml \
                            --set grafana.service.type=ClusterIP \
                            --set prometheus.service.type=ClusterIP || echo "Prometheus installation skipped, may already exist"
                    else
                        echo "Prometheus already installed, upgrading with minimal resources..."
                        helm upgrade prometheus prometheus-community/kube-prometheus-stack \
                            -n monitoring \
                            -f monitoring/minimal-monitoring-values.yaml \
                            --set grafana.service.type=ClusterIP \
                            --set prometheus.service.type=ClusterIP || echo "Prometheus upgrade skipped"
                    fi
                    
                    # Apply ServiceMonitor and Dashboard ConfigMap
                    echo "Creating ServiceMonitor for Abstergo app..."
                    kubectl apply -f monitoring/servicemonitor.yaml || kubectl apply -f k8s/servicemonitor.yaml
                    
                    echo "Creating Grafana dashboard for Abstergo app..."
                    kubectl apply -f monitoring/dashboard.yaml || kubectl apply -f k8s/grafana-dashboard.yaml
                    
                    echo "=== Monitoring Installation Complete ==="
                '''
            }
        }
        
        stage('Cleanup') {
            steps {
                    sh '''
                    # Clean up local Docker images, but don't fail the build if they're not found
                    docker rmi ${DOCKER_IMAGE}:${NEW_BUILD_NUMBER} || true
                    docker rmi ${DOCKER_IMAGE}:latest || true
                    docker rmi ${DOCKER_METRICS_IMAGE}:${NEW_BUILD_NUMBER} || true
                    docker rmi ${DOCKER_METRICS_IMAGE}:latest || true
                    docker logout
                '''
            }
        }
    }
    
    post {
        success {
            echo "Pipeline completed successfully!"
            echo "Application has been deployed to Kubernetes with monitoring enabled."
        }
        failure {
            echo "Pipeline failed. Check the logs for details."
        }
        cleanup {
            echo "Cleaning up workspace..."
            cleanWs()
        }
    }
}

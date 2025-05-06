pipeline {
    agent any
    environment {
        // Docker Hub credentials stored in Jenkins Credentials
        DOCKER_HUB_CREDENTIALS = credentials('Docker')
        // Map credentials to what jenkins_build.sh expects
        DOCKER_USER = "${DOCKER_HUB_CREDENTIALS_USR}"
        DOCKER_PASS = "${DOCKER_HUB_CREDENTIALS_PSW}"
        // Skip Kubernetes deployment in the build script
        SKIP_KUBERNETES = "true"
        // Set KUBECONFIG path for direct kubectl use
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
    }
    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        stage('Compile') {
            steps {
                echo 'Compiling code...'
                sh 'npm install'
            }
        }
        stage('Code Review') {
            steps {
                echo 'Running linter...'
                sh 'npm run lint'
            }
        }
        stage('Test') {
            steps {
                echo 'Running tests...'
                // Add your test commands here
            }
        }
        stage('Metric Check') {
            steps {
                echo 'Checking code metrics...'
                // Add your metrics checks here
            }
        }
        stage('Package') {
            steps {
                echo 'Building application...'
                sh 'npm run build'
            }
        }
        stage('Docker Build and Push') {
            steps {
                echo 'Building and pushing Docker image...'
                // Make the script executable and run it
                sh 'chmod +x jenkins_build.sh'
                sh './jenkins_build.sh'
            }
        }
        stage('Kubernetes Deploy') {
            steps {
                echo 'Deploying to Kubernetes...'
                sh '''
                    # Get the latest image tag
                    IMAGE_NAME="angreatharva/abstergo"
                    TAG="${BUILD_NUMBER}"
                    
                    # Update the image in deployment YAML
                    sed -i "s|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${TAG}|g" k8s/deployment.yaml
                    
                    # First check if kubectl is available
                    KUBECTL_PATH=$(command -v kubectl || echo "")
                    
                    if [ -z "$KUBECTL_PATH" ]; then
                        echo "ERROR: kubectl command not found"
                        echo "Please install kubectl on the Jenkins server"
                        exit 1
                    else
                        echo "Found kubectl at: $KUBECTL_PATH"
                    fi
                    
                    # Export PATH to include kubectl directory
                    export PATH=$(dirname "$KUBECTL_PATH"):$PATH
                    
                    # Verify kubectl works
                    if ! kubectl version --client; then
                        echo "ERROR: kubectl command found but not working"
                        exit 1
                    fi
                    
                    # Check if minikube is running or we're using a different cluster
                    if command -v minikube &> /dev/null; then
                        # If minikube is installed, check its status
                        if ! minikube status | grep -q "Running"; then
                            echo "WARNING: Minikube is not running"
                            echo "If you're using Minikube, please start it with: minikube start"
                        fi
                    fi
                    
                    # Check for kubectl access directly
                    echo "Checking Kubernetes cluster connection..."
                    if kubectl cluster-info; then
                        echo "Kubernetes connection successful!"
                    else
                        echo "ERROR: Cannot connect to Kubernetes cluster"
                        echo "Make sure the KUBECONFIG environment variable is set correctly"
                        echo "Current KUBECONFIG: $KUBECONFIG"
                        echo ""
                        echo "To fix this, run the following commands on the Jenkins server as root:"
                        echo "------------------------------------------------------"
                        echo "# Create a kubeconfig file that Jenkins can use"
                        echo "mkdir -p /var/lib/jenkins/.kube"
                        echo "kubectl config view --flatten --minify > /var/lib/jenkins/.kube/config"
                        echo "chown -R jenkins:jenkins /var/lib/jenkins/.kube"
                        echo "chmod 600 /var/lib/jenkins/.kube/config"
                        echo "------------------------------------------------------"
                        echo "If using Minikube, you may need to copy certificates:"
                        echo "mkdir -p /var/lib/jenkins/.minikube/profiles/minikube"
                        echo "cp ~/.minikube/ca.crt /var/lib/jenkins/.minikube/"
                        echo "cp ~/.minikube/profiles/minikube/client.* /var/lib/jenkins/.minikube/profiles/minikube/"
                        echo "chown -R jenkins:jenkins /var/lib/jenkins/.minikube"
                        echo "------------------------------------------------------"
                        echo "You can also use the prepared script: configure_k8s_access.sh"
                        exit 1
                    fi
                    
                    # Deploy using the configured kubeconfig 
                    echo "Deploying to Kubernetes cluster..."
                    kubectl apply -f k8s/configmap.yaml
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    
                    # Verify deployment
                    echo "Checking deployment status:"
                    kubectl get pods -l app=abstergo-app
                    kubectl get svc abstergo-service
                '''
            }
        }
    }
    post {
        success {
            echo 'Pipeline completed successfully!'
            echo 'Application has been deployed to Kubernetes.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for details.'
        }
        always {
            // Clean up Docker resources to avoid workspace clutter
            sh '''
                docker stop smoke-test || true
                docker rm smoke-test || true
            '''
        }
    }
}

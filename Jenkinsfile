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
                // Add timeout specifically for linting stage which seemed to hang
                timeout(time: 5, unit: 'MINUTES') {
                    sh 'npm run lint'
                }
            }
            // Add error handling for this stage
            post {
                failure {
                    echo 'Linting failed. Check code quality issues.'
                }
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                // Add your test commands here
                sh 'echo "Tests would run here"'
            }
        }
        
        stage('Metric Check') {
            steps {
                echo 'Checking code metrics...'
                // Add your metrics checks here
                sh 'echo "Metrics would be checked here"'
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
                // Make the script executable and run it with a timeout
                sh 'chmod +x jenkins_build.sh'
                timeout(time: 10, unit: 'MINUTES') {
                    sh './jenkins_build.sh'
                }
            }
        }
        
        stage('Kubernetes Deploy') {
            steps {
                echo 'Deploying to Kubernetes...'
                // Wrap in a timeout to prevent hanging
                timeout(time: 5, unit: 'MINUTES') {
                    sh '''
                        # Get the latest image tag
                        IMAGE_NAME="angreatharva/abstergo"
                        TAG="${BUILD_NUMBER}"
                        
                        # Update the image in deployment YAML
                        sed -i "s|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${TAG}|g" k8s/deployment.yaml
                        
                        # Check if kubectl is available
                        if ! command -v kubectl &> /dev/null; then
                            echo "ERROR: kubectl command not found"
                            echo "Please install kubectl on the Jenkins server"
                            exit 1
                        fi
                        
                        # Check cluster connection with a timeout
                        timeout 30s kubectl cluster-info || {
                            echo "ERROR: Cannot connect to Kubernetes cluster"
                            echo "Make sure the KUBECONFIG environment variable is set correctly"
                            echo "Current KUBECONFIG: $KUBECONFIG"
                            
                            # Check if the kubeconfig file exists
                            if [ ! -f "$KUBECONFIG" ]; then
                                echo "KUBECONFIG file does not exist at: $KUBECONFIG"
                                echo "Run the configure_k8s_access.sh script as root to set up access"
                            fi
                            
                            exit 1
                        }
                        
                        # Deploy using the configured kubeconfig 
                        echo "Deploying to Kubernetes cluster..."
                        kubectl apply -f k8s/configmap.yaml
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                        
                        # Verify deployment with a timeout
                        timeout 60s kubectl rollout status deployment/abstergo-app
                    '''
                }
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
            // Clean workspace to prevent issues with future builds
            cleanWs(cleanWhenNotBuilt: false,
                    deleteDirs: true,
                    disableDeferredWipeout: true,
                    notFailBuild: true)
        }
    }
}

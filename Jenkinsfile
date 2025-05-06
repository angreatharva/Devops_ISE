pipeline {
    agent any
    environment {
        // Docker Hub credentials stored in Jenkins Credentials
        DOCKER_HUB_CREDENTIALS = credentials('Docker')
        // Map credentials to what jenkins_build.sh expects
        DOCKER_USER = "${DOCKER_HUB_CREDENTIALS_USR}"
        DOCKER_PASS = "${DOCKER_HUB_CREDENTIALS_PSW}"
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
                // Use a Secret file credential in Jenkins for your kubeconfig YAML
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_PATH')]) {
                    sh '''
                        # Set up kubeconfig in workspace
                        mkdir -p "$WORKSPACE/.kube"
                        cp "$KUBECONFIG_PATH" "$WORKSPACE/.kube/config"
                        chmod 600 "$WORKSPACE/.kube/config"
                        export KUBECONFIG="$WORKSPACE/.kube/config"
                        
                        # Verify connectivity
                        kubectl cluster-info
                        
                        # Apply manifests
                        kubectl apply -f k8s/configmap.yaml || true
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                        
                        # Wait for rollout
                        kubectl rollout status deployment/abstergo-app --timeout=60s
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
        }
    }
}

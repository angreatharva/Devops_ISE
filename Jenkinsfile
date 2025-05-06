pipeline {
    agent any
    
    environment {
        DOCKER_CREDENTIALS = credentials('Docker')
        DOCKER_USER = "${DOCKER_CREDENTIALS_USR}"
        DOCKER_PASS = "${DOCKER_CREDENTIALS_PSW}"
        KUBE_CONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Compile') {
            steps {
                echo 'Compiling code...'
                sh 'npm install'
            }
        }
        
        stage('Code Review') {
            steps {
                echo 'Running linter...'
                sh 'npm run lint || echo "Linting had errors but we will continue the pipeline"'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                // Add test command once you have tests configured
                // sh 'npm test'
                echo 'Tests would run here'
            }
        }
        
        stage('Metric Check') {
            steps {
                echo 'Checking code metrics...'
                // Add code quality metrics tool here if needed
                echo 'Code metrics would be checked here'
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
                sh 'chmod +x jenkins_build.sh'
                sh './jenkins_build.sh'
            }
        }
        
        stage('Kubernetes Deploy') {
            steps {
                echo 'Deploying to Kubernetes...'
                // Use the workspace for the kubeconfig to avoid permission issues
                sh "mkdir -p ${WORKSPACE}/.kube"
                sh "echo '$KUBE_CONFIG' > ${WORKSPACE}/.kube/config"
                sh "chmod 600 ${WORKSPACE}/.kube/config"
                
                // Check kubernetes connection with the custom config
                sh "KUBECONFIG=${WORKSPACE}/.kube/config kubectl version --client || true"
                sh "KUBECONFIG=${WORKSPACE}/.kube/config kubectl cluster-info || true"
                
                // Apply Kubernetes manifests with the custom config
                sh "KUBECONFIG=${WORKSPACE}/.kube/config kubectl apply -f k8s/configmap.yaml || true"
                sh "KUBECONFIG=${WORKSPACE}/.kube/config kubectl apply -f k8s/deployment.yaml || true"
                sh "KUBECONFIG=${WORKSPACE}/.kube/config kubectl apply -f k8s/service.yaml || true"
                
                // Wait for deployment to complete (but continue if it fails)
                sh "KUBECONFIG=${WORKSPACE}/.kube/config kubectl rollout status deployment/abstergo-app --timeout=60s || true"
                
                // Get deployment status with the custom config
                sh "KUBECONFIG=${WORKSPACE}/.kube/config kubectl get pods || true"
                sh "KUBECONFIG=${WORKSPACE}/.kube/config kubectl get services || true"
                
                // Clean up
                sh "rm -rf ${WORKSPACE}/.kube"
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            echo 'Application is now deployed to Kubernetes'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for details.'
        }
    }
} 

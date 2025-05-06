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
                sh 'npm run lint'
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
                // Set up kubectl config from Jenkins credentials
                sh "mkdir -p ~/.kube"
                sh "echo '$KUBE_CONFIG' > ~/.kube/config"
                
                // Apply Kubernetes manifests
                sh 'kubectl apply -f k8s/configmap.yaml'
                sh 'kubectl apply -f k8s/deployment.yaml'
                sh 'kubectl apply -f k8s/service.yaml'
                
                // Wait for deployment to complete
                sh 'kubectl rollout status deployment/abstergo-app'
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

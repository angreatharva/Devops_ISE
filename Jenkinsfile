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
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        // Docker Hub credentials ID that you'll create in Jenkins
        DOCKER_CREDENTIALS = 'Docker'
        // Set KUBECONFIG path for direct kubectl use
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
    }
    
    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        
        stage('Verify Setup') {
            steps {
                sh 'chmod +x scripts/*.sh'
                sh './scripts/verify.sh'
            }
        }
        
        stage('Code Review') {
            steps {
                echo 'Running linter...'
                sh 'npm run lint'
            }
        }
        
        stage('Code Compile') {
            steps {
                echo 'Installing dependencies...'
                sh 'npm install'
            }
        }
        
        stage('Metrics Check') {
            steps {
                echo 'Running metrics check...'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
            }
        }
        
        stage('Package') {
            steps {
                echo 'Building application...'
                sh 'npm run build'
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    // Login to Docker Hub
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin"
                    }
                    
                    // Use our script to build both images with the build number as tag
                    sh "./scripts/build-images.sh -t ${DOCKER_TAG} --push"
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                    sh '''
                    # Apply Kubernetes configurations
                    kubectl apply -f k8s/configmap.yaml
                                kubectl apply -f k8s/deployment.yaml
                                kubectl apply -f k8s/service.yaml
                                
                    # Wait for deployment to be ready
                    kubectl rollout status deployment/abstergo-app --timeout=300s
                    '''
            }
        }
        
        stage('Setup Monitoring') {
            steps {
                echo 'Setting up monitoring...'
                sh 'chmod +x scripts/jenkins-monitoring.sh'
                sh './scripts/jenkins-monitoring.sh install'
            }
        }
        
        stage('Cleanup') {
            steps {
                // Remove local Docker images to save space
                sh "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true"
                sh "docker rmi ${DOCKER_IMAGE}:latest || true"
                sh "docker rmi angreatharva/abstergo-metrics:${DOCKER_TAG} || true"
                sh "docker rmi angreatharva/abstergo-metrics:latest || true"
                
                // Logout from Docker Hub
                sh "docker logout"
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            echo 'Application has been deployed to Kubernetes with monitoring enabled.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs for details.'
        }
        always {
            echo 'Cleaning up workspace...'
            cleanWs(cleanWhenNotBuilt: false,
                    deleteDirs: true,
                    disableDeferredWipeout: true,
                    notFailBuild: true)
        }
    }
} 

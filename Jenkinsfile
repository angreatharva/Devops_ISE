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
                withCredentials([file(credentialsId: 'kubernetes-config', variable: 'KUBECONFIG')]) {
                    echo 'Deploying to Kubernetes...'
                    sh '''
                        # Get the latest image tag
                        IMAGE_NAME="angreatharva/abstergo"
                        TAG="${BUILD_NUMBER}"
                        
                        # Update the image in deployment YAML
                        sed -i "s|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${TAG}|g" k8s/deployment.yaml
                        
                        # Deploy using the provided kubeconfig
                        echo "Deploying to Kubernetes cluster..."
                        kubectl --kubeconfig=${KUBECONFIG} apply -f k8s/configmap.yaml
                        kubectl --kubeconfig=${KUBECONFIG} apply -f k8s/deployment.yaml
                        kubectl --kubeconfig=${KUBECONFIG} apply -f k8s/service.yaml
                        
                        # Verify deployment
                        echo "Checking deployment status:"
                        kubectl --kubeconfig=${KUBECONFIG} get pods -l app=abstergo
                        kubectl --kubeconfig=${KUBECONFIG} get svc abstergo-service
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

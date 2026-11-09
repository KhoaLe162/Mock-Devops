
pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-southeast-1'
        AWS_ACCOUNT_ID = '084250374652'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    git --version
                    docker --version
                    aws --version
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    docker build -t tinycrm-frontend:${BUILD_NUMBER} ./frontend
                    docker build -t tinycrm-backend:${BUILD_NUMBER} ./tinyOS
                '''
            }
        }

        stage('Login to Amazon ECR') {
            steps {
                sh '''
                    aws ecr get-login-password --region "$AWS_REGION" |
                      docker login --username AWS --password-stdin "$ECR_REGISTRY"
                '''
            }
        }

        stage('Tag and Push Images') {
            steps {
                sh '''
                    docker tag tinycrm-frontend:${BUILD_NUMBER} \
                      "$ECR_REGISTRY/tinycrm-frontend:${BUILD_NUMBER}"

                    docker tag tinycrm-backend:${BUILD_NUMBER} \
                      "$ECR_REGISTRY/tinycrm-backend:${BUILD_NUMBER}"

                    docker push "$ECR_REGISTRY/tinycrm-frontend:${BUILD_NUMBER}"
                    docker push "$ECR_REGISTRY/tinycrm-backend:${BUILD_NUMBER}"
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    aws eks update-kubeconfig \
                    --region ap-southeast-1 \
                    --name tinycrm-dev-eks

                    helm upgrade --install tinycrm ./helm/tinycrm \
                    --namespace tinycrm \
                    --set-string frontend.image.tag=${BUILD_NUMBER} \
                    --set-string backend.image.tag=${BUILD_NUMBER} \
                    --wait \
                    --timeout 10m
                '''
            }
        }
    }
        

    post {
        success {
            echo 'TinyCRM images successfully pushed to Amazon ECR!'
        }
        failure {
            echo 'TinyCRM CI pipeline failed. Check the console output.'
        }
    }
}

pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "yaonet"
        DOCKER_PORT_MAPPING = "8000:8080"
        CONTAINER_NAME = "yaonet"
        HEALTH_CHECK_URL = "http://localhost:8000/health"
        HEALTH_CHECK_RETRIES = "5"
        HEALTH_CHECK_INTERVAL = "3"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "🔍 Checking out code from Git..."
                checkout scm
                sh "git log --oneline -5"
            }
        }

        stage('Build Image') {
            steps {
                echo "🔨 Building Docker image: ${DOCKER_IMAGE}:${BUILD_NUMBER}..."
                sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
                sh "docker images | grep yaonet"
            }
        }

        stage('Clean Old Container') {
            steps {
                echo "🧹 Cleaning up old container..."
                sh "docker stop ${CONTAINER_NAME} || true && docker rm ${CONTAINER_NAME} || true"
            }
        }

        stage('Deploy') {
            steps {
                echo "🚀 Deploying new container with port mapping ${DOCKER_PORT_MAPPING}..."
                sh "docker run -d --name ${CONTAINER_NAME} -p ${DOCKER_PORT_MAPPING} ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                sh "sleep 2"
                sh "docker ps | grep yaonet"
            }
        }

        stage('Health Check') {
            steps {
                echo "❤️  Performing health check..."
                script {
                    def retries = 0
                    def maxRetries = HEALTH_CHECK_RETRIES.toInteger()
                    def interval = HEALTH_CHECK_INTERVAL.toInteger()
                    
                    while (retries < maxRetries) {
                        try {
                            def response = sh(
                                script: "curl -s -o /dev/null -w '%{http_code}' ${HEALTH_CHECK_URL}",
                                returnStdout: true
                            ).trim()
                            
                            if (response == "200") {
                                echo "✅ Health check passed! Response code: ${response}"
                                break
                            } else {
                                echo "⚠️  Unexpected response code: ${response}. Retrying..."
                            }
                        } catch (Exception e) {
                            echo "⚠️  Health check attempt ${retries + 1}/${maxRetries} failed. Retrying in ${interval}s..."
                        }
                        
                        retries++
                        if (retries < maxRetries) {
                            sleep(time: interval, unit: 'SECONDS')
                        }
                    }
                    
                    if (retries >= maxRetries) {
                        error("❌ Health check failed after ${maxRetries} attempts!")
                    }
                }
            }
        }

        stage('Verification') {
            steps {
                echo "🔎 Verifying deployment..."
                sh "echo 'Container Status:' && docker ps --filter name=yaonet"
                sh "echo '\nRecent Logs:' && docker logs --tail 20 ${CONTAINER_NAME}"
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline execution successful!"
            sh "docker ps --filter name=yaonet --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
        }
        failure {
            echo "❌ Pipeline execution failed!"
            sh "echo 'Collecting debug information...' && docker logs --tail 50 ${CONTAINER_NAME} || true"
        }
        always {
            echo "🏁 Pipeline finished"
        }
    }
}

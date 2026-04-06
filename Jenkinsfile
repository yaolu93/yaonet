pipeline {
    agent any

    triggers {
        pollSCM('H/5 * * * *')
    }

    environment {
        DOCKER_IMAGE = "yaonet"
        DOCKER_PORT_MAPPING = "8000:8080"
        CONTAINER_NAME = "yaonet"
        DJANGO_IMAGE = "yaonet-django-articles"
        DJANGO_PORT_MAPPING = "8001:8001"
        DJANGO_CONTAINER_NAME = "yaonet-django-articles"
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

        stage('Build Django Articles Image') {
            steps {
                echo "🔨 Building Django articles image: ${DJANGO_IMAGE}:${BUILD_NUMBER}..."
                sh "docker build -f django_articles/Dockerfile -t ${DJANGO_IMAGE}:${BUILD_NUMBER} ."
                sh "docker images | grep ${DJANGO_IMAGE}"
            }
        }

        stage('Clean Old Container') {
            steps {
                echo "🧹 Cleaning up old container..."
                sh "docker stop ${CONTAINER_NAME} || true && docker rm ${CONTAINER_NAME} || true"
                sh "docker stop ${DJANGO_CONTAINER_NAME} || true && docker rm ${DJANGO_CONTAINER_NAME} || true"
            }
        }

        stage('Deploy') {
            steps {
                echo "🚀 Deploying new container with port mapping ${DOCKER_PORT_MAPPING}..."
                sh "docker run -d --name ${CONTAINER_NAME} -p ${DOCKER_PORT_MAPPING} ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                echo "🚀 Deploying Django articles container with port mapping ${DJANGO_PORT_MAPPING}..."
                sh "docker run -d --name ${DJANGO_CONTAINER_NAME} -p ${DJANGO_PORT_MAPPING} ${DJANGO_IMAGE}:${BUILD_NUMBER}"
                sh "sleep 2"
                sh "docker ps | grep yaonet"
            }
        }

        stage('Verification') {
            steps {
                echo "🔎 Verifying deployment..."
                sh "echo 'Container Status:' && docker ps --filter name=yaonet"
                sh "echo '\nRecent Logs:' && docker logs --tail 20 ${CONTAINER_NAME}"
                sh "echo '\nChecking Flask health endpoint...' && curl -fsS http://localhost:8000/health"
                sh "echo '\nChecking Django articles endpoint...' && curl -fsS http://localhost:8001/articles/ | head -n 20"
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline execution successful!"
            sh "docker ps --filter name=yaonet --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
            sh "docker ps --filter name=${DJANGO_CONTAINER_NAME} --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
        }
        failure {
            echo "❌ Pipeline execution failed!"
            sh "echo 'Collecting debug information...' && docker logs --tail 50 ${CONTAINER_NAME} || true"
            sh "echo 'Collecting django debug information...' && docker logs --tail 50 ${DJANGO_CONTAINER_NAME} || true"
        }
        always {
            echo "🏁 Pipeline finished"
            echo "🧹 Cleaning up old Docker images..."
            // 删除旧的 yaonet images，只保留最新的3个
            sh "docker images ${DOCKER_IMAGE} --format '{{.ID}}' | tail -n +4 | xargs -r docker rmi -f || true"
            // 删除旧的 django articles images，只保留最新的3个
            sh "docker images ${DJANGO_IMAGE} --format '{{.ID}}' | tail -n +4 | xargs -r docker rmi -f || true"
            // 清理所有未使用的 images（24小时前的）
            sh "docker image prune -a -f --filter 'until=24h' || true"
            echo "✨ Docker cleanup completed"
        }
    }
}

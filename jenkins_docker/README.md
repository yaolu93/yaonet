# Jenkins Docker Setup (Yaonet)

This folder contains all Jenkins-related setup files for this project.

## Files

- `Dockerfile`: Jenkins image with Docker CLI installed
- `start_jenkins.sh`: build image and run Jenkins container
- `stop_jenkins.sh`: stop and remove Jenkins container
- `get_admin_password.sh`: print initial admin password

## Prerequisites

- Linux with Docker installed
- Current user can run Docker commands

## One-Command Startup

```bash
cd /home/yao/fromGithub/yaonet/jenkins_docker
./start_jenkins.sh
```

By default this script will:

1. Build image `jenkins_with_docker`
2. Use persistent Jenkins home `/mydata/jenkins_home`
3. Start container `jenkins` on ports `8180` and `50000`
4. Mount `/var/run/docker.sock` for Docker-in-Docker style CLI access

## Get Initial Admin Password

```bash
cd /home/yao/fromGithub/yaonet/jenkins_docker
./get_admin_password.sh
```

Then open:

- http://localhost:8180

## Copy-Paste Manual Commands (No Script)

```bash
cd /home/yao/fromGithub/yaonet/jenkins_docker
docker build -t jenkins_with_docker .
mkdir -p /mydata/jenkins_home
docker run -d \
  --name jenkins \
  -u root \
  -p 8180:8080 \
  -p 50000:50000 \
  -v /mydata/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins_with_docker
docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## Create Pipeline Job for This Repo

1. New Item -> Pipeline
2. Pipeline script from SCM -> Git
3. Repository URL: your repository URL
4. Script Path: `Jenkinsfile`
5. Save -> Build Now

## Stop / Remove Jenkins

```bash
cd /home/yao/fromGithub/yaonet/jenkins_docker
./stop_jenkins.sh
```

## Optional Environment Overrides

You can override defaults when running `start_jenkins.sh`:

```bash
JENKINS_CONTAINER_NAME=jenkins \
JENKINS_IMAGE_NAME=jenkins_with_docker \
JENKINS_HOME_DIR=/mydata/jenkins_home \
JENKINS_HTTP_PORT=8180 \
JENKINS_AGENT_PORT=50000 \
./start_jenkins.sh
```

## Troubleshooting

- Port conflict on 8180:
  - set another port, for example `JENKINS_HTTP_PORT=8280 ./start_jenkins.sh`
- Docker command not found in pipeline:
  - ensure `/var/run/docker.sock` is mounted
- Permission denied on Docker socket:
  - make sure Docker daemon is running and accessible
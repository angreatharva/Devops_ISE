#!/bin/bash
# Configure Git for large repositories
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 300
git config --global core.compression 9

set -e          # fail fast on any error

# Check docker permissions and print helpful message if there's an issue
if ! docker info &>/dev/null; then
  echo "ERROR: Cannot connect to the Docker daemon. Make sure Docker is running and that your user has the right permissions."
  echo "If you're running in Jenkins, make sure the jenkins user is part of the docker group."
  echo "Run: sudo usermod -aG docker jenkins && sudo systemctl restart jenkins"
  exit 1
fi

# 1) Define your image name & tag
IMAGE_NAME="angreatharva/abstergo"       # replace my-app with your repo name
TAG="${BUILD_NUMBER}"              # Jenkins build number as tag

# 2) Build the Docker image
echo ">>> Building image ${IMAGE_NAME}:${TAG}"
docker build -t "${IMAGE_NAME}:${TAG}" .

# 3) (Optional) Smoke-test by running it locally
echo ">>> Starting smoke-test container"
docker rm -f smoke-test || true
docker run -d --name smoke-test \
  -p 127.0.0.1:5173:5173 \
  "${IMAGE_NAME}:${TAG}"
sleep 5
echo ">>> Containers:"
docker ps -a

# 4) Log in to Docker Hub
echo ">>> Logging in to Docker Hub as ${DOCKER_USER}"
echo "${DOCKER_PASS}" | docker login \
  --username "${DOCKER_USER}" \
  --password-stdin

# 5) Tag and push
echo ">>> Tagging image as latest"
docker tag "${IMAGE_NAME}:${TAG}" "${IMAGE_NAME}:latest"

echo ">>> Pushing ${IMAGE_NAME}:${TAG}"
docker push "${IMAGE_NAME}:${TAG}"

echo ">>> Pushing ${IMAGE_NAME}:latest"
docker push "${IMAGE_NAME}:latest" 
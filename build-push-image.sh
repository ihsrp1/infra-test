#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Build the Docker image
echo "Building Docker image..."
docker build -t my-node-app .

# Tag the Docker image
echo "Tagging Docker image..."
docker tag my-node-app igorhsoares/interview-test:latest

# Push the Docker image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
# docker login -u <your-dockerhub-username> -p <your-dockerhub-password>
docker push igorhsoares/interview-test:latest
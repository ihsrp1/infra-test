#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Minikube if not installed
if ! command_exists minikube; then
    echo "Minikube not found, installing..."
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube
    sudo mv minikube /usr/local/bin/
fi

# Install kubectl if not installed
if ! command_exists kubectl; then
    echo "kubectl not found, installing..."
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Check if Minikube is already running
if minikube status >/dev/null 2>&1; then
    echo "Minikube is already running."
else
    # Start Minikube
    echo "Starting Minikube..."
    minikube start --nodes 4 --driver=docker
fi

# Enable Minikube registry add-on
echo "Enabling Minikube registry add-on..."
minikube addons enable registry

echo "Labeling the 3 Minikube nodes to have 3 different zones..."
kubectl label nodes minikube-m02 topology.kubernetes.io/zone=zone2
kubectl label nodes minikube-m03 topology.kubernetes.io/zone=zone3
kubectl taint nodes minikube-m04 database="true":NoSchedule

# Apply Kubernetes configurations
echo "Applying Kubernetes configurations..."
kubectl apply -f ./k8s/db
kubectl apply -f ./k8s/application

# Wait for running pods of the "myapp" deployment
while true; do
    running_pods=$(kubectl get pods -l app=myapp -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')
    
    if [ -n "$running_pods" ]; then
        echo "Running pods found for 'myapp'. Executing the service command..."
        minikube service myapp-lb --url
        break  # Exit the loop if running pods are found
    else
        echo "No running pods found for 'myapp'. Waiting for 2 seconds..."
        sleep 2  # Wait for 2 seconds before checking again
    fi
done

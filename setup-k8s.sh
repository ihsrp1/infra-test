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

echo "Labeling the 3 Minikube nodes to have different zones..."
# Check and label minikube-m02
if ! kubectl get node minikube-m02 --show-labels | grep -q 'topology.kubernetes.io/zone=zone2'; then
    echo "Labeling minikube-m02 with zone2..."
    kubectl label nodes minikube-m02 topology.kubernetes.io/zone=zone2
else
    echo "minikube-m02 is already labeled with zone2."
fi

# Check and label minikube-m03
if ! kubectl get node minikube-m03 --show-labels | grep -q 'topology.kubernetes.io/zone=zone3'; then
    echo "Labeling minikube-m03 with zone3..."
    kubectl label nodes minikube-m03 topology.kubernetes.io/zone=zone3
else
    echo "minikube-m03 is already labeled with zone3."
fi

# Check and taint minikube-m04
if ! kubectl describe node minikube-m04 | grep -q 'database=true:NoSchedule'; then
    echo "Tainting minikube-m04 with database=true:NoSchedule..."
    kubectl taint nodes minikube-m04 database=true:NoSchedule
else
    echo "minikube-m04 is already tainted with database=true:NoSchedule."
fi

# Check if metrics-server is already deployed
if ! kubectl get deployment metrics-server -n kube-system > /dev/null 2>&1; then
    echo "Metrics-server not found. Deploying metrics-server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
else
    echo "Metrics-server is already deployed."
fi

# Check for SSL or certificate-related errors
if kubectl get deployment metrics-server -n kube-system -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' | grep -q "False"; then
    echo "SSL or certificate-related errors detected. Editing metrics-server deployment..."
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
fi

# Apply Kubernetes configurations
echo "Applying Kubernetes configurations..."
kubectl apply -f ./k8s/db
kubectl apply -f ./k8s/application

# # Wait for running pods of the "myapp" deployment
# while true; do
#     running_pods=$(kubectl get pods -l app=myapp -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')
    
#     if [ -n "$running_pods" ]; then
#         echo "Running pods found for 'myapp'. Executing the service command..."
#         minikube service myapp-lb --url
#         break  # Exit the loop if running pods are found
#     else
#         echo "No running pods found for 'myapp'. Waiting for 2 seconds..."
#         sleep 2  # Wait for 2 seconds before checking again
#     fi
# done

# Wait for Pods to be ready
echo "Waiting for Pods to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/myapp

# Get the URL of the LoadBalancer service
minikube service myapp-lb --url
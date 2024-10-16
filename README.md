# Cloud Infrastructure Interview test

This project organizes and manages a distributed application in a Kubernetes cluster using a specific directory structure, automation scripts, and a CI/CD pipeline on GitHub Actions.

## Project Structure

The main structure of the project is as follows:

```
.github/
k8s/
  ├── application/
  └── db/
src/
terraform/
  └── local/
tests/
Dockerfile
setup-k8s.sh
build-push-image.sh
```

- **.github/**: Contains the CI/CD pipeline for automating linting, building, and pushing the Docker image.
- **k8s/**: Contains the `.yaml` files necessary for configuring Kubernetes resources, including the application and the database.
  - **application/**: Configuration files for the application.
  - **db/**: Configuration files for the database.
- **src/**: Directory with the application source code.
- **terraform/**: Terraform scripts for configuring the Kubernetes cluster.
  - **local/**: Configuration for provisioning resources locally.
- **tests/**: Contains automated tests to validate the application’s functionality.
- **Dockerfile**: Instructions to build the Docker image for the application.
- **setup-k8s.sh**: Script to configure the Kubernetes cluster.
- **build-push-image.sh**: Script to build and push the Docker image to the private repository.

## Kubernetes Cluster Details

The Kubernetes cluster is composed of:

- **1 control node** to manage the cluster.
- **1 database node** with a taint `database=true:NoSchedule`, preventing other types of pods from being scheduled on this node.
- **2 application nodes**, each labeled with `topology.kubernetes.io/zone` to simulate geographic distribution:
  - Node 1: `topology.kubernetes.io/zone=zone2`
  - Node 2: `topology.kubernetes.io/zone=zone3`

### Kubernetes Resources

- **Deployments**:
  - **Application**: Configured with `topologySpreadConstraints` to distribute the pods between zones `zone2` and `zone3`.
  - **Horizontal Autoscaling**: Set to automatically adjust the number of replicas based on CPU usage.
  - **Pod Disruption Budget**: Configured to ensure that at least 1 pod is always available.
  
- **StatefulSet**:
  - **Database**: Managed with a StatefulSet to ensure data persistence and pod order maintenance.

## CI/CD Pipeline on GitHub Actions

The CI/CD pipeline is located in **.github/** and performs the following steps:

1. **Lint**: Validates the application’s source code to ensure they follow style and quality standards.
2. **Build and Push**: Builds the application’s Docker image and pushes it to a private repository. The credentials for the repository are stored in the GitHub repository’s secrets.

## Usage

### 1. Set Up the Kubernetes Cluster

Run the `setup-k8s.sh` script to configure the local Kubernetes cluster using `Minikube` and `kubectl` with the defined requirements and the application should already be running at the given IP and port:

```bash
./setup-k8s.sh
```

### 2. Build and Push the Docker Image (optional)

Use the `build-push-image.sh` script to build the application’s image and push it to the private repository:

```bash
./build-push-image.sh
```

## Tests

One of the test cases involved deploying a dedicated pod within the cluster solely for the purpose of sending a continuous stream of requests to the application’s LoadBalancer. This load test aimed to evaluate if the application could handle high traffic and to observe if any overload conditions occurred.

## Requirements

- Docker and Minikube for the local development environment.
- Terraform for resource provisioning.
- Kubectl to interact with the Kubernetes cluster.
- Access to GitHub Actions for continuous integration and delivery.
# Define variables
DOCKER_IMAGE_NAME := k8s-laravel
DOCKER_BUILD_ARGS := --build-arg user=aeviterna --build-arg uid=1000
KUBE_DEPLOYMENT := k8s/deployment.yml
KUBE_SERVICE := k8s/service.yml

# -- DOCKER

# Build Docker image
build:
	docker build $(DOCKER_BUILD_ARGS) -t $(DOCKER_IMAGE_NAME) .

# Run the Docker container
run:
	docker run -p 3000:3000 --name $(DOCKER_IMAGE_NAME) $(DOCKER_IMAGE_NAME)

# Stop and remove the Docker container
stop:
	docker stop $(DOCKER_IMAGE_NAME)
	docker rm $(DOCKER_IMAGE_NAME)

# Clean up Docker images and containers
clean:
	docker stop $(DOCKER_IMAGE_NAME) || true
	docker rm $(DOCKER_IMAGE_NAME) || true
	docker rmi $(DOCKER_IMAGE_NAME) || true

# -- KUBERNETES

# Load Docker image into Kubernetes
k8s-load:
	eval $(minikube -p minikube docker-env)
	docker build $(DOCKER_BUILD_ARGS) -t $(DOCKER_IMAGE_NAME) .

# Apply Kubernetes deployment and service
k8s-apply:
	kubectl apply -f $(KUBE_DEPLOYMENT)
	kubectl apply -f $(KUBE_SERVICE)

# Get pod status
k8s-get-pods:
	kubectl get pods

# Delete Kubernetes deployment and service
k8s-delete:
	kubectl delete -f $(KUBE_DEPLOYMENT)
	kubectl delete -f $(KUBE_SERVICE)

# Default target when just running `make` without specifying a target
default: build

.PHONY: build run stop clean default k8s-apply k8s-get-pods k8s-delete
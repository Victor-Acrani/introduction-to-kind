# Check to see if we can use ash, in Alpine images, or default to BASH.
SHELL_PATH = /bin/ash
SHELL = $(if $(wildcard $(SHELL_PATH)),/bin/ash,/bin/bash)

# ==============================================================================
#	INSTALL
# ==============================================================================
# Go Installation
#
#   Access Go oficial website and install in your machine.
#
#   https://go.dev/dl/
#   
#   # export Go path
#   export PATH=$PATH:/usr/local/go/bin
#
# ==============================================================================
# Docker Installation
#	
#	Access Docker website and install according to your OS.
#	https://docs.docker.com/engine/install/ubuntu/
#
# ==============================================================================
# Kind Installation with Go
#
#	go install sigs.k8s.io/kind@v0.22.0
#
#	For other methods check: https://kind.sigs.k8s.io/docs/user/quick-start/ 
#
#	# export kind path
#	export PATH="/home/{YOUR_USER_NAME}:$PATH"
#	export PATH=$PATH:$(go env GOPATH)/bin
#
# ==============================================================================
# Kubectl Installation 
#
#	comand line for ubuntu
#	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
#
#	For other methods check: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
#
#	# export kubectl path
#	export PATH=$PATH:~/.local/bin
#
# ==============================================================================
# Kustomize Installation 
#
#	GOBIN=$(pwd)/ GO111MODULE=on go install sigs.k8s.io/kustomize/kustomize/v5@latest
#	
#	For other methods check: https://kubectl.docs.kubernetes.io/installation/kustomize/source/ 
#
# ==============================================================================
# DEPENDENCIES
# ==============================================================================
GOLANG          := golang:1.21
KIND            := kindest/node:v1.27.1
ALPINE          := alpine:3.18

KIND_CLUSTER    := local-cluster
BASE_IMAGE_NAME := acrani/application
VERSION         := 0.0.1

# Version 1
SERVICE_NAME_V1  := test-app-v1
SERVICE_IMAGE_V1 := $(BASE_IMAGE_NAME)/$(SERVICE_NAME_V1):$(VERSION)

# ==============================================================================
#	KIND
# ==============================================================================

# create Kind cluster.
create-cluster:
	kind create cluster \
	--image $(KIND) \
	--name $(KIND_CLUSTER) \
	--config zarf/k8s/local/kind-config.yaml

	# Using kubectl wait command to monitor the availability of a Kubernetes deployment
	# Setting a timeout of 120 seconds for the wait operation
	# Specifying the namespace where the deployment is located
	# Specifying the condition to wait for, in this case, "Available"
	# Specifying the type of Kubernetes resource to wait for, which is a deployment

	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

# get Kind clusters.
get-cluster:
	kind get clusters

# delete Kind cluster.
delete-cluster:
	kind delete cluster --name $(KIND_CLUSTER)

# list cluster images.
list-loaded-images:
	kind get nodes --name $(KIND_CLUSTER) | xargs -n1 -I {} docker exec {} crictl images	

# load app-v1 docker image to kind cluster. 
# NOTE: first build the docker image and then run this command.
load-app-v1-image:
	kind load docker-image $(SERVICE_IMAGE_V1) --name $(KIND_CLUSTER)	

# ==============================================================================
#	DOCKER
# ==============================================================================

# build app-v1 image.
build-image-app-v1:
	docker build \
		-f zarf/docker/dockerfile.app-v1 \
		-t $(SERVICE_IMAGE_V1) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

# run directly from docker (use this for testing outside Kubernetes).
run-image-app-v1:
	docker run -d -p 3000:3000 $(SERVICE_IMAGE_V1)

# ==============================================================================
#	K8S WITHIN KIND
# ==============================================================================
# Example 1 is a simple http server with a health check handler.
# The purpose of this example is undestanding how to deploy a single pod, check its logs
# and make a http request. 

# apply k8s manifest.
apply-v1:
	kubectl apply -f zarf/k8s/base/v1/base-pod-example.yaml

# apply k8s manifest and replace env variable inside k8s manifest.
# use this for loading sensitive content. 
# sed command creates a new k8s manifest, then it is applyed and finally deleted.
apply-v1-with-env-var:
	sed "s/REPLACE_ENV_VAR/smooth operator/g" zarf/k8s/base/v1/base-pod-example.yaml > kubernetes.yaml | \
	kubectl apply -f kubernetes.yaml
	rm kubernetes.yaml

# get all elements from v1 example.
get-all-v1:
	kubectl get all -o wide -n pod-namespace

# delete all elements from v1 example.
delete-v1:
	kubectl delete -f zarf/k8s/base/v1/base-pod-example.yaml	

# describe all elements from v1 example.
describe-v1: 
	kubectl describe pod -n pod-namespace -l app=pod-app	

# show app-v1 pod logs.
log-v1:
	kubectl logs -n pod-namespace -l app=pod-app --all-containers=true -f --tail=100	

# execute a GET request to app-v1 pod.
call-v1:
	curl -il http://localhost:3000/api/v1/health

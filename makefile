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
KIND            := kindest/node:v1.27.1
KIND_CLUSTER    := test-cluster

# ==============================================================================
#	KIND
# ==============================================================================
create-cluster:
	kind create cluster \
	--image $(KIND) \
	--name $(KIND_CLUSTER) \
	--config zarf/k8s/dev/kind-config.yaml

	# Using kubectl wait command to monitor the availability of a Kubernetes deployment
	# Setting a timeout of 120 seconds for the wait operation
	# Specifying the namespace where the deployment is located
	# Specifying the condition to wait for, in this case, "Available"
	# Specifying the type of Kubernetes resource to wait for, which is a deployment

	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

get-cluster:
	kind get clusters

delete-cluster:
	kind delete cluster --name $(KIND_CLUSTER)


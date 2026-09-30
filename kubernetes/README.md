# Kubernetes cluster

## Overview

Kubernetes cluster deployed in Yandex Cloud.

The infrastructure was created using Terraform, configured with Ansible and deployed using kubeadm.

## Technologies

- Yandex Cloud
- Terraform
- Ansible
- Kubernetes
- kubeadm
- containerd
- Calico
- nginx-ingress
- kube-prometheus-stack
- Grafana
- Prometheus
- Alertmanager
- Yandex Container Registry
- GitHub


---

# Cluster architecture

## Kubernetes version


Kubernetes v1.34.12


## Container runtime


containerd 2.2.1


## Network plugin


Calico


## Ingress Controller


ingress-nginx


## Monitoring stack


kube-prometheus-stack



---

# Nodes

| Node | Role | IP |
|-|-|-|
| k8s-master-01 | Control Plane | 10.20.10.29 |
| k8s-worker-01 | Worker | 10.20.20.10 |
| k8s-worker-02 | Worker | 10.20.30.15 |


Cluster scheme:

                Internet
                   |
                   |
          nginx Ingress Controller
                   |
                   |
            Kubernetes Service
                   |
                   |
            diplom-app Deployment
                /          \
               /            \
      worker-01              worker-02


---

# Application

## Application name


diplom-app


Namespace:


default


Replicas:


2


Application:


nginx based web application


The application is deployed as Kubernetes Deployment with two replicas running on worker nodes.


---

# Container Registry

## Yandex Container Registry

Production image:


cr.yandex/crp6gcfckbknlsc51u2f/diplom-app:1.0



## GitHub Container Registry

Public image:


ghcr.io/mteplov/diplom-app:1.0



---

# Kubernetes manifests

Application manifests location:


kubernetes/app/


Structure:


kubernetes/
│
├── app/
│ ├── deployment.yaml
│ ├── service.yaml
│ └── ingress.yaml
│
├── README.md
├── nodes-status.txt
├── pods-status.txt
├── services-status.txt
└── ingress-status.txt



---

# Application deployment

Apply application manifests:

```bash
kubectl apply -f kubernetes/app/

Check deployment:

kubectl get deployment

Expected result:

NAME          READY
diplom-app    2/2
Pods

Check application pods:

kubectl get pods -l app=diplom-app

Example:

NAME                          READY
diplom-app-xxxxxxxxxx-xxxxx   1/1
diplom-app-xxxxxxxxxx-xxxxx   1/1

Get detailed information:

kubectl describe pods -l app=diplom-app

View application logs:

kubectl logs -l app=diplom-app
Service

Application Service:

diplom-app

Service type:

NodePort

Ports:

80:30080

Configuration:

port: 80
targetPort: 80
nodePort: 30080

Check service:

kubectl get svc diplom-app

Check endpoints:

kubectl get endpoints diplom-app
Ingress

Ingress controller:

nginx

Ingress resource:

diplom-app

Application path:

/app

Check ingress:

kubectl get ingress -A

Detailed information:

kubectl describe ingress diplom-app

Application address:

http://158.160.220.27/app

Test application:

curl http://158.160.220.27/app

Expected response:

Application is running in Kubernetes.

Monitoring

Monitoring stack deployed using kube-prometheus-stack.

Components:

Prometheus
Alertmanager
Grafana
Node Exporter
Kube State Metrics

Namespace:

monitoring

Check monitoring pods:

kubectl get pods -n monitoring

Check monitoring services:

kubectl get svc -n monitoring

Grafana service:

NodePort 30090

Grafana URL:

http://158.160.220.27:30090

Prometheus:

NodePort 30091

Alertmanager:

NodePort 30092
Infrastructure provisioning

Infrastructure was created using Terraform.

Terraform directory:

terraform/

Terraform components:

VPC network
Subnets
Security groups
Compute instances
Service accounts
Object Storage backend

Terraform commands:

Initialize:

terraform init

Check configuration:

terraform plan

Apply infrastructure:

terraform apply

Destroy infrastructure:

terraform destroy

Terraform state stored in:

Yandex Object Storage S3 backend
Configuration management

Server configuration was performed using Ansible.

Ansible directory:

ansible/

Playbooks:

prepare.yml
containerd.yml
kubernetes-install.yml
kubeadm-init.yml

Configured:

system preparation
package installation
containerd runtime
Kubernetes components
kubeadm initialization
worker node configuration

Run example:

ansible-playbook -i inventory.ini prepare.yml
Kubernetes verification

Get cluster nodes:

kubectl get nodes

Get all resources:

kubectl get all -A

Get pods:

kubectl get pods -A

Get services:

kubectl get svc -A

Get ingress:

kubectl get ingress -A
CI/CD

Source repository:

https://github.com/mteplov/diplom

Current workflow:

Source code stored in GitHub
Docker image build
Image stored in container registry
Kubernetes deployment using manifests
Useful Kubernetes commands

Restart application:

kubectl rollout restart deployment diplom-app

Check rollout:

kubectl rollout status deployment diplom-app

Scale application:

kubectl scale deployment diplom-app --replicas=3

Delete application:

kubectl delete -f kubernetes/app/

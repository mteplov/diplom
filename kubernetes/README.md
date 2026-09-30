# Kubernetes cluster

## Cluster

- Kubernetes v1.34.12
- Container runtime: containerd 2.2.1
- Network plugin: Calico

## Nodes

| Node | IP |
|-|-|
| k8s-master-01 | 10.20.10.29 |
| k8s-worker-01 | 10.20.20.10 |
| k8s-worker-02 | 10.20.30.15 |

## Deploy test application

Apply:

```bash
kubectl apply -f nginx/


## Container Registry

### Yandex Container Registry

Production image:

cr.yandex/crp6gcfckbknlsc51u2f/diplom-app:1.0


### GitHub Container Registry

Public package:

ghcr.io/mteplov/diplom-app:1.0

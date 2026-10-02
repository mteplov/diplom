# Diplom project — Kubernetes CI/CD platform

## Overview

Проект реализует полный цикл доставки приложения:

- создание инфраструктуры в Yandex Cloud через Terraform;
- настройка серверов через Ansible;
- развертывание Kubernetes кластера;
- сборка Docker image;
- публикация образа в Yandex Container Registry;
- автоматический deployment приложения через GitHub Actions.

---

# Architecture
Developer
|
|
GitHub Repository
|
|
GitHub Actions
|
+----------------------+
| |
Terraform Docker Build
| |
| |
Yandex Cloud Yandex Container Registry
|
|
Kubernetes Cluster
|
|
NGINX Ingress
|
|
Application Pods


---

# Project structure


.
├── app/ # исходный код приложения
│
├── terraform/ # Terraform конфигурация
│ ├── network.tf # сеть
│ ├── instances.tf # виртуальные машины
│ ├── images.tf # образы VM
│ ├── outputs.tf # outputs
│ └── variables.tf # переменные
│
├── ansible/ # настройка серверов
│
├── kubernetes/
│ └── app/
│ ├── deployment.yaml # Kubernetes Deployment
│ ├── service.yaml # Kubernetes Service
│ └── ingress.yaml # внешний доступ
│
├── deploy.sh # автоматический запуск инфраструктуры
├── deploy.sh.bak # резервная копия
│
├── .github/
│ └── workflows/
│ └── cicd.yml # CI/CD pipeline
│
├── docs/ # документация
│
├── ansible.cfg
│
└── README.md


---

# Initial deployment

Для полного развертывания используется:


./deploy.sh


Скрипт выполняет:

1. Подготовку окружения.
2. Terraform init.
3. Terraform plan/apply.
4. Создание инфраструктуры Yandex Cloud.
5. Настройку серверов через Ansible.
6. Подготовку Kubernetes.
7. Развертывание приложения.


После выполнения проверить:


kubectl get nodes


Ожидаемый результат:


NAME STATUS
k8s-master-01 Ready
k8s-worker-01 Ready
k8s-worker-02 Ready


---

# Terraform

Terraform управляет инфраструктурой Yandex Cloud.

Создаются:

- VPC сеть;
- подсети;
- виртуальные машины;
- Kubernetes узлы.


Команды:

Проверка:


terraform validate


План:


terraform plan


Применение:


terraform apply



Получить созданные ресурсы:


terraform output


---

# Kubernetes

Приложение разворачивается в Kubernetes.


Deployment:


kubectl get deployment diplom-app



Pods:


kubectl get pods -l app=diplom-app -o wide



Service:


kubectl get svc diplom-app



Ingress:


kubectl get ingress


---

# Application check

Проверка приложения:


curl -I http://127.0.0.1/app



Успешный ответ:


HTTP/1.1 200 OK


---

# Docker Registry

Образы хранятся в Yandex Container Registry.


Registry:


cr.yandex/crp6gcfckbknlsc51u2f/diplom-app



Проверить текущий image:


kubectl get deployment diplom-app
-o jsonpath='{.spec.template.spec.containers[0].image}'


---

# CI/CD GitHub Actions

Workflow:


.github/workflows/cicd.yml



## Commit to master

При обычном изменении выполняется:


Terraform Plan
|
Terraform Apply



---

## Release deployment

Для выпуска новой версии создается tag:



git tag v1.0.0

git push origin v1.0.0



После этого выполняется полный pipeline:



Terraform Plan
|
Terraform Apply
|
Docker Build
|
Docker Push
|
Kubernetes Deploy



Docker image получает версию:


cr.yandex/crp6gcfckbknlsc51u2f/diplom-app:v1.0.0


---

# Required secrets and variables

Секреты не хранятся в Git.


GitHub:


Repository
-> Settings
-> Secrets and variables
-> Actions



## Secrets


YC_TOKEN

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

TF_VAR_PASSWORD_HASH

TF_VAR_SSH_PUBLIC_KEY



## Variables


YC_CLOUD_ID

YC_FOLDER_ID

YC_ZONE

TF_STATE_BUCKET


---

# Yandex Cloud information

После Terraform apply получить:



terraform output



Пример:


k8s_master_public_ip = <public_ip>

worker_01_private_ip = <private_ip>

worker_02_private_ip = <private_ip>



---

# Kubernetes access

SSH:


ssh ubuntu@<k8s_master_public_ip>



Проверка кластера:


kubectl cluster-info

kubectl get nodes


---

# Failure test

Для проверки восстановления можно заменить image:



kubectl set image deployment/diplom-app
diplom-app=cr.yandex/crp6gcfckbknlsc51u2f/diplom-app:does-not-exist



Kubernetes создаст новую replica, но рабочие pod останутся доступны.


После исправления через CI/CD приложение восстанавливается автоматически.

---

# Result

В результате реализована полноценная DevOps цепочка:

- Terraform управляет инфраструктурой;
- Ansible выполняет настройку серверов;
- Docker создает версии приложения;
- Yandex Container Registry хранит образы;
- Kubernetes выполняет deployment;
- GitHub Actions автоматизирует CI/CD процесс.

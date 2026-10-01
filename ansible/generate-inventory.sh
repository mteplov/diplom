#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="${REPO_ROOT}/terraform"
INVENTORY_FILE="${REPO_ROOT}/ansible/inventory.ini"

cd "${TERRAFORM_DIR}"

MASTER_IP="$(terraform output -raw k8s_master_public_ip)"
WORKER_01_IP="$(terraform output -raw k8s_worker_01_public_ip)"
WORKER_02_IP="$(terraform output -raw k8s_worker_02_public_ip)"

for ip in "${MASTER_IP}" "${WORKER_01_IP}" "${WORKER_02_IP}"; do
  if [[ ! "${ip}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: invalid public IP: ${ip}" >&2
    exit 1
  fi
done

cat > "${INVENTORY_FILE}" <<INVENTORY
[kube_master]
k8s-master-01 ansible_host=${MASTER_IP} ansible_user=teplov

[kube_workers]
k8s-worker-01 ansible_host=${WORKER_01_IP} ansible_user=teplov
k8s-worker-02 ansible_host=${WORKER_02_IP} ansible_user=teplov

[kubernetes:children]
kube_master
kube_workers

[kubernetes:vars]
ansible_ssh_private_key_file=~/.ssh/id_github_no_pass
INVENTORY

echo "Generated: ${INVENTORY_FILE}"
echo
cat "${INVENTORY_FILE}"

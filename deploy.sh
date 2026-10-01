#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

TERRAFORM_DIR="$PROJECT_DIR/terraform"
ANSIBLE_DIR="$PROJECT_DIR/ansible"
INVENTORY="$ANSIBLE_DIR/inventory.ini"

SSH_USER="${SSH_USER:-teplov}"

echo
echo "=========================================="
echo " Kubernetes Diplom Deployment"
echo "=========================================="
echo

# --------------------------------------------------
# Check required commands
# --------------------------------------------------

for cmd in terraform ansible-playbook ssh openssl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: command '$cmd' not found."
        exit 1
    fi
done

# --------------------------------------------------
# Helper functions
# --------------------------------------------------

prompt_if_empty() {
    local var_name="$1"
    local prompt="$2"

    if [[ -z "${!var_name:-}" ]]; then
        read -r -p "$prompt: " "$var_name"
        export "$var_name"
    fi

    if [[ -z "${!var_name:-}" ]]; then
        echo "ERROR: $var_name cannot be empty."
        exit 1
    fi
}

prompt_secret_if_empty() {
    local var_name="$1"
    local prompt="$2"

    if [[ -z "${!var_name:-}" ]]; then
        read -r -s -p "$prompt: " "$var_name"
        echo
        export "$var_name"
    fi

    if [[ -z "${!var_name:-}" ]]; then
        echo "ERROR: $var_name cannot be empty."
        exit 1
    fi
}

# --------------------------------------------------
# Yandex Cloud configuration
# --------------------------------------------------

echo
echo "=========================================="
echo " Yandex Cloud configuration"
echo "=========================================="
echo

prompt_secret_if_empty \
    "YC_TOKEN" \
    "Yandex Cloud token"

prompt_if_empty \
    "YC_CLOUD_ID" \
    "Yandex Cloud cloud ID"

prompt_if_empty \
    "YC_FOLDER_ID" \
    "Yandex Cloud folder ID"

if [[ -z "${YC_ZONE:-}" ]]; then
    read -r -p "Yandex Cloud availability zone [ru-central1-a]: " YC_ZONE
    YC_ZONE="${YC_ZONE:-ru-central1-a}"
    export YC_ZONE
fi

# --------------------------------------------------
# Terraform backend configuration
# --------------------------------------------------

echo
echo "=========================================="
echo " Terraform state configuration"
echo "=========================================="
echo

prompt_if_empty \
    "TF_STATE_BUCKET" \
    "Yandex Object Storage bucket for Terraform state"

prompt_if_empty \
    "AWS_ACCESS_KEY_ID" \
    "Yandex Object Storage access key"

prompt_secret_if_empty \
    "AWS_SECRET_ACCESS_KEY" \
    "Yandex Object Storage secret key"

# --------------------------------------------------
# SSH configuration
# --------------------------------------------------

echo
echo "=========================================="
echo " SSH configuration"
echo "=========================================="
echo

if [[ -z "${SSH_PUBLIC_KEY:-}" ]]; then
    DEFAULT_PUBLIC_KEY=""

    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        DEFAULT_PUBLIC_KEY="$HOME/.ssh/id_ed25519.pub"
    elif [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
        DEFAULT_PUBLIC_KEY="$HOME/.ssh/id_rsa.pub"
    elif [[ -f "$HOME/.ssh/id_github_no_pass.pub" ]]; then
        DEFAULT_PUBLIC_KEY="$HOME/.ssh/id_github_no_pass.pub"
    fi

    if [[ -n "$DEFAULT_PUBLIC_KEY" ]]; then
        read -r -p "SSH public key file [$DEFAULT_PUBLIC_KEY]: " SSH_PUBLIC_KEY_FILE
        SSH_PUBLIC_KEY_FILE="${SSH_PUBLIC_KEY_FILE:-$DEFAULT_PUBLIC_KEY}"

        if [[ ! -f "$SSH_PUBLIC_KEY_FILE" ]]; then
            echo "ERROR: SSH public key file not found: $SSH_PUBLIC_KEY_FILE"
            exit 1
        fi

        SSH_PUBLIC_KEY="$(cat "$SSH_PUBLIC_KEY_FILE")"
    else
        read -r -p "SSH public key: " SSH_PUBLIC_KEY
    fi

    export SSH_PUBLIC_KEY
fi

if [[ -z "${SSH_PUBLIC_KEY:-}" ]]; then
    echo "ERROR: SSH_PUBLIC_KEY cannot be empty."
    exit 1
fi

# --------------------------------------------------
# VM password hash
# --------------------------------------------------

if [[ -z "${PASSWORD_HASH:-}" ]]; then
    echo
    echo "The VMs use a SHA-512 password hash for user '$SSH_USER'."
    echo "Enter a password for the VMs."

    read -r -s -p "VM password: " VM_PASSWORD
    echo

    if [[ -z "$VM_PASSWORD" ]]; then
        echo "ERROR: VM password cannot be empty."
        unset VM_PASSWORD
        exit 1
    fi

    PASSWORD_HASH="$(openssl passwd -6 "$VM_PASSWORD")"

    unset VM_PASSWORD
    export PASSWORD_HASH
fi

# --------------------------------------------------
# Find SSH private key
# --------------------------------------------------

if [[ -n "${SSH_PRIVATE_KEY:-}" ]]; then
    PRIVATE_KEY="$SSH_PRIVATE_KEY"
elif [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    PRIVATE_KEY="$HOME/.ssh/id_ed25519"
elif [[ -f "$HOME/.ssh/id_rsa" ]]; then
    PRIVATE_KEY="$HOME/.ssh/id_rsa"
elif [[ -f "$HOME/.ssh/id_github_no_pass" ]]; then
    PRIVATE_KEY="$HOME/.ssh/id_github_no_pass"
else
    echo "ERROR: SSH private key not found."
    echo
    echo "Set SSH_PRIVATE_KEY, for example:"
    echo "  export SSH_PRIVATE_KEY=\$HOME/.ssh/id_ed25519"
    echo
    exit 1
fi

echo
echo "SSH user : $SSH_USER"
echo "SSH key  : $PRIVATE_KEY"
echo "Cloud    : $YC_CLOUD_ID"
echo "Folder   : $YC_FOLDER_ID"
echo "Zone     : $YC_ZONE"
echo "State    : $TF_STATE_BUCKET"
echo

# --------------------------------------------------
# Terraform init
# --------------------------------------------------

echo
echo "=========================================="
echo " STEP 1: Terraform init"
echo "=========================================="
echo

terraform -chdir="$TERRAFORM_DIR" init \
    -reconfigure \
    -input=false \
    -backend-config="bucket=$TF_STATE_BUCKET"

# --------------------------------------------------
# Terraform apply
# --------------------------------------------------

echo
echo "=========================================="
echo " STEP 2: Terraform apply"
echo "=========================================="
echo

terraform -chdir="$TERRAFORM_DIR" apply \
    -auto-approve \
    -input=false \
    -var="cloud_id=$YC_CLOUD_ID" \
    -var="folder_id=$YC_FOLDER_ID" \
    -var="zone=$YC_ZONE" \
    -var="password_hash=$PASSWORD_HASH" \
    -var="ssh_public_key=$SSH_PUBLIC_KEY"

# --------------------------------------------------
# Get Terraform outputs
# --------------------------------------------------

echo
echo "=========================================="
echo " STEP 3: Get VM IP addresses"
echo "=========================================="
echo

MASTER_PUBLIC_IP="$(terraform -chdir="$TERRAFORM_DIR" output -raw k8s_master_public_ip)"
MASTER_INTERNAL_IP="$(terraform -chdir="$TERRAFORM_DIR" output -raw k8s_master_internal_ip)"

WORKER1_PUBLIC_IP="$(terraform -chdir="$TERRAFORM_DIR" output -raw k8s_worker_01_public_ip)"
WORKER1_INTERNAL_IP="$(terraform -chdir="$TERRAFORM_DIR" output -raw k8s_worker_01_internal_ip)"

WORKER2_PUBLIC_IP="$(terraform -chdir="$TERRAFORM_DIR" output -raw k8s_worker_02_public_ip)"
WORKER2_INTERNAL_IP="$(terraform -chdir="$TERRAFORM_DIR" output -raw k8s_worker_02_internal_ip)"

echo "Master:"
echo "  public  = $MASTER_PUBLIC_IP"
echo "  private = $MASTER_INTERNAL_IP"
echo

echo "Worker 01:"
echo "  public  = $WORKER1_PUBLIC_IP"
echo "  private = $WORKER1_INTERNAL_IP"
echo

echo "Worker 02:"
echo "  public  = $WORKER2_PUBLIC_IP"
echo "  private = $WORKER2_INTERNAL_IP"
echo

# --------------------------------------------------
# Generate Ansible inventory
# --------------------------------------------------

echo
echo "=========================================="
echo " STEP 4: Generate Ansible inventory"
echo "=========================================="
echo

cat > "$INVENTORY" <<INVENTORY_EOF
[kube_master]
k8s-master-01 ansible_host=$MASTER_PUBLIC_IP kube_internal_ip=$MASTER_INTERNAL_IP

[kube_workers]
k8s-worker-01 ansible_host=$WORKER1_PUBLIC_IP kube_internal_ip=$WORKER1_INTERNAL_IP
k8s-worker-02 ansible_host=$WORKER2_PUBLIC_IP kube_internal_ip=$WORKER2_INTERNAL_IP

[kubernetes:children]
kube_master
kube_workers

[all:vars]
ansible_user=$SSH_USER
ansible_ssh_private_key_file=$PRIVATE_KEY
ansible_python_interpreter=/usr/bin/python3
INVENTORY_EOF

cat "$INVENTORY"

# --------------------------------------------------
# Wait for SSH
# --------------------------------------------------

echo
echo "=========================================="
echo " STEP 5: Wait for SSH"
echo "=========================================="
echo

wait_for_ssh() {
    local host="$1"

    echo "Waiting for SSH: $host"

    for attempt in $(seq 1 60); do
        if ssh \
            -i "$PRIVATE_KEY" \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=5 \
            -o BatchMode=yes \
            "$SSH_USER@$host" \
            "echo SSH_OK" >/dev/null 2>&1
        then
            echo "SSH is ready: $host"
            return 0
        fi

        echo "  attempt $attempt/60..."
        sleep 5
    done

    echo "ERROR: SSH is not available on $host"
    return 1
}

wait_for_ssh "$MASTER_PUBLIC_IP"
wait_for_ssh "$WORKER1_PUBLIC_IP"
wait_for_ssh "$WORKER2_PUBLIC_IP"

# --------------------------------------------------
# GitHub Actions Runner token
# --------------------------------------------------

echo
echo "=========================================="
echo " STEP 6: GitHub Actions Runner"
echo "=========================================="
echo

prompt_secret_if_empty \
    "GITHUB_RUNNER_TOKEN" \
    "GitHub Actions Runner token"

# Generate a new Grafana administrator password for every deployment.
GRAFANA_ADMIN_PASSWORD="$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 24)"
export GRAFANA_ADMIN_PASSWORD

echo "GITHUB_RUNNER_TOKEN is set."
echo "Grafana administrator password has been generated."

# --------------------------------------------------
# Run Ansible by phases
# --------------------------------------------------

echo
echo "=========================================="
echo " STEP 7: Run Ansible deployment by phases"
echo "=========================================="
echo

ANSIBLE_MAX_ATTEMPTS=5
ANSIBLE_RETRY_DELAY=15

run_ansible_phase() {
    local phase_name="$1"
    local playbook="$2"

    echo
    echo "=================================================="
    echo " ANSIBLE PHASE: $phase_name"
    echo " Playbook: $playbook"
    echo "=================================================="
    echo

    for attempt in $(seq 1 "$ANSIBLE_MAX_ATTEMPTS"); do
        echo
        echo "------------------------------------------"
        echo " $phase_name: attempt $attempt/$ANSIBLE_MAX_ATTEMPTS"
        echo "------------------------------------------"
        echo

        if [[ "$attempt" -gt 1 ]]; then
            echo "Waiting for all nodes to become reachable..."

            wait_for_ssh "$MASTER_PUBLIC_IP"
            wait_for_ssh "$WORKER1_PUBLIC_IP"
            wait_for_ssh "$WORKER2_PUBLIC_IP"

            echo
            echo "Waiting $ANSIBLE_RETRY_DELAY seconds before retry..."
            sleep "$ANSIBLE_RETRY_DELAY"
        fi

        if ANSIBLE_HOST_KEY_CHECKING=False \
            ansible-playbook \
                -i "$INVENTORY" \
                "$ANSIBLE_DIR/$playbook"
        then
            echo
            echo "SUCCESS: $phase_name completed."
            return 0
        fi

        echo
        echo "WARNING: $phase_name attempt $attempt/$ANSIBLE_MAX_ATTEMPTS failed."

        if [[ "$attempt" -lt "$ANSIBLE_MAX_ATTEMPTS" ]]; then
            echo "The phase will be retried automatically."
            echo "Waiting $ANSIBLE_RETRY_DELAY seconds..."
            sleep "$ANSIBLE_RETRY_DELAY"
        fi
    done

    echo
    echo "ERROR: $phase_name failed after $ANSIBLE_MAX_ATTEMPTS attempts."
    return 1
}

# --------------------------------------------------
# Ansible phases
# --------------------------------------------------

run_ansible_phase "Prepare Kubernetes nodes" "prepare.yml"

run_ansible_phase "Install containerd" "containerd.yml"

run_ansible_phase "Install Docker, Terraform and GitHub Actions Runner" "runner.yml"

run_ansible_phase "Install Kubernetes packages" "kubernetes-install.yml"

run_ansible_phase "Initialize Kubernetes master" "kubeadm-init.yml"

run_ansible_phase "Install Kubernetes CNI" "cni.yml"

run_ansible_phase "Join Kubernetes workers" "kubeadm-join.yml"

run_ansible_phase "Install Helm" "helm.yml"

run_ansible_phase "Install ingress-nginx" "ingress-nginx.yml"

run_ansible_phase "Install monitoring" "monitoring.yml"

run_ansible_phase "Configure Grafana ingress" "monitoring-ingress.yml"

run_ansible_phase "Deploy application" "app.yml"

echo
echo "=========================================="
echo " Deployment completed successfully"
echo "=========================================="
echo
echo "Kubernetes master:"
echo "  https://$MASTER_PUBLIC_IP:6443"
echo
echo "Master SSH:"
echo "  ssh -i $PRIVATE_KEY $SSH_USER@$MASTER_PUBLIC_IP"
echo
echo "Grafana:"
echo "  URL      : http://$MASTER_PUBLIC_IP/"
echo "  User     : admin"
echo "  Password : $GRAFANA_ADMIN_PASSWORD"
echo
echo "Application:"
echo "  http://$MASTER_PUBLIC_IP/app"
echo

output "k8s_master_public_ip" {
  description = "Public IP address of Kubernetes master"
  value       = yandex_compute_instance.k8s_master.network_interface[0].nat_ip_address
}

output "k8s_master_internal_ip" {
  description = "Internal IP address of Kubernetes master"
  value       = yandex_compute_instance.k8s_master.network_interface[0].ip_address
}

output "k8s_worker_01_public_ip" {
  description = "Public IP address of Kubernetes worker 01"
  value       = yandex_compute_instance.k8s_worker_01.network_interface[0].nat_ip_address
}

output "k8s_worker_01_internal_ip" {
  description = "Internal IP address of Kubernetes worker 01"
  value       = yandex_compute_instance.k8s_worker_01.network_interface[0].ip_address
}

output "k8s_worker_02_public_ip" {
  description = "Public IP address of Kubernetes worker 02"
  value       = yandex_compute_instance.k8s_worker_02.network_interface[0].nat_ip_address
}

output "k8s_worker_02_internal_ip" {
  description = "Internal IP address of Kubernetes worker 02"
  value       = yandex_compute_instance.k8s_worker_02.network_interface[0].ip_address
}

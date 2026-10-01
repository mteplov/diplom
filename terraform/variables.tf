variable "cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "zone" {
  description = "Default availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "password_hash" {
  description = "SHA-512 password hash for the teplov user"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for the teplov user"
  type        = string
}

resource "yandex_compute_instance" "k8s_master" {
  name        = "k8s-master-01"
  hostname    = "k8s-master-01"
  platform_id = "standard-v3"

  zone = "ru-central1-a"

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 40
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.master.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_master.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml", {
      hostname       = "k8s-master-01"
      password_hash  = var.password_hash
      ssh_public_key = local.ssh_public_key
    })
  }
}


resource "yandex_compute_instance" "k8s_worker_01" {
  name        = "k8s-worker-01"
  hostname    = "k8s-worker-01"
  platform_id = "standard-v3"

  zone = "ru-central1-b"

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 40
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.worker1.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_worker.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml", {
      hostname       = "k8s-worker-01"
      password_hash  = var.password_hash
      ssh_public_key = local.ssh_public_key
    })
  }
}


resource "yandex_compute_instance" "k8s_worker_02" {
  name        = "k8s-worker-02"
  hostname    = "k8s-worker-02"
  platform_id = "standard-v3"

  zone = "ru-central1-d"

  scheduling_policy {
    preemptible = true
  }

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 40
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.worker2.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_worker.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml", {
      hostname       = "k8s-worker-02"
      password_hash  = var.password_hash
      ssh_public_key = local.ssh_public_key
    })
  }
}

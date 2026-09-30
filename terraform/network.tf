resource "yandex_vpc_network" "diplom" {
  name = "diplom-network"
}

resource "yandex_vpc_subnet" "master" {
  name           = "subnet-master"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.20.10.0/24"]
}

resource "yandex_vpc_subnet" "worker1" {
  name           = "subnet-worker-1"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.20.20.0/24"]
}

resource "yandex_vpc_subnet" "worker2" {
  name           = "subnet-worker-2"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.diplom.id
  v4_cidr_blocks = ["10.20.30.0/24"]
}

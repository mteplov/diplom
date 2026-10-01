resource "yandex_vpc_security_group" "k8s_master" {
  name       = "k8s-master-sg"
  network_id = yandex_vpc_network.diplom.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    port           = 6443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "etcd"
    from_port      = 2379
    to_port        = 2380
    v4_cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "kubelet"
    port           = 10250
    v4_cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    protocol       = "UDP"
    description    = "Calico VXLAN"
    port           = 8472
    v4_cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "ANY"
    description    = "Internal traffic"
    v4_cidr_blocks = ["10.20.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "All outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "k8s_worker" {
  name       = "k8s-worker-sg"
  network_id = yandex_vpc_network.diplom.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "kubelet"
    port           = 10250
    v4_cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    protocol       = "UDP"
    description    = "Calico VXLAN"
    port           = 8472
    v4_cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "NodePort"
    from_port      = 30000
    to_port        = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "ANY"
    description    = "Internal traffic"
    v4_cidr_blocks = ["10.20.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "All outgoing"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

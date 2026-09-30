terraform {
  backend "s3" {
    bucket = "teplov-netology-diplom-tfstate"
    key    = "infrastructure/terraform.tfstate"
    region = "ru-central1"

    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}

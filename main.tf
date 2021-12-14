terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

provider "vault" {
  address="https://vault-cluster.vault.3262e218-24bf-49f9-93e0-681713aa750c.aws.hashicorp.cloud:8200"
}
provider "google" {
  # credentials = file("rryjewski-gcpdemo-sa-creds.json")

  # get project id from doormat. https://doormat.hashicorp.services/accounts/requests/my Click on
  # the request and you'll get details of the project
  project = "hc-d7442f1a33034ed6b588e77e0dc"
  region  = "us-central1"
  zone    = "us-central1-c"
  access_token = data.vault_generic_secret.gcp_auth.data["token"]
}

data "vault_generic_secret" "gcp_auth" {
  path = "gcp/roleset/example-roleset/token"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags = ["web", "dev", "temp"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}

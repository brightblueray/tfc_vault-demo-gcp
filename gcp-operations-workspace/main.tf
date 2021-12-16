# Make sure you grab a vault token

terraform {
 # Leverage TFC for state management and run execution
  cloud {
    organization = "hashicorp-rryjewski"
    workspaces {
      tags = ["demo"]
    }
  }

  # Two providers required: Google for GPC and Vault for secrets management
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

# Created a temp GCP Project and copy details
locals {
  projectId = "hc-d7442f1a33034ed6b588e77e0dc"
}

variable "vault_user" {}
variable "vault_pwd" {}

# Using Hashicorp Cloud Platform (HCP) Vault
provider "vault" {
  address="https://vault-cluster.vault.3262e218-24bf-49f9-93e0-681713aa750c.aws.hashicorp.cloud:8200"
  auth_login {
    namespace = "admin"
    path = "auth/userpass/login/${var.vault_user}"
    parameters = {password = var.vault_pwd}
  }
}

provider "google" {
  project = local.projectId
  region  = "us-central1"
  zone    = "us-central1-c"
  access_token = data.vault_generic_secret.gcp_auth.data["token"]
}

data "vault_generic_secret" "gcp_auth" {
  path = "dynamic-gcp-creds-demo-path/roleset/gcp-builder-roleset/token"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network-rryjewski"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance-rryjewski"
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
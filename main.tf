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
  project = "rryjewski-gcpdemo-test"
}

# Using Hashicorp Cloud Platform (HCP) Vault
provider "vault" {
  address="https://vault-cluster.vault.3262e218-24bf-49f9-93e0-681713aa750c.aws.hashicorp.cloud:8200"
}

variable "name" { default = "dynamic-gcp-creds-demo" }

# Manually created a service account to be used to manage the temporary oath tokens
resource "vault_gcp_secret_backend" "gcp" {
  credentials = file("rryjewski_sa_creds.json")
  path       = "${var.name}-path"

  default_lease_ttl_seconds = "120"
  max_lease_ttl_seconds     = "240"
}

#
resource "vault_gcp_secret_roleset" "infra-roleset" {
  backend = vault_gcp_secret_backend.gcp.path
  roleset = "gcp-builder-roleset"
  secret_type = "access_token"
  project = local.projectId
  token_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  binding {
    resource = "//cloudresourcemanager.googleapis.com/projects/${local.projectId}"

    roles = [
      "roles/compute.admin",
    ]
  }
}



provider "google" {
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
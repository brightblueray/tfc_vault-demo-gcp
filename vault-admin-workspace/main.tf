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

variable "name" { default = "dynamic-gcp-creds-demo" }
variable "vault_user" {}
variable "vault_pwd" {}
  

# variable "gcp-dynamic-creds-sa" {}

# Using Hashicorp Cloud Platform (HCP) Vault
provider "vault" {
  address="https://vault-cluster.vault.3262e218-24bf-49f9-93e0-681713aa750c.aws.hashicorp.cloud:8200"
  auth_login {
    namespace = "admin"
    path = "auth/userpass/login/${var.vault_user}"
    parameters = {password = var.vault_pwd}
  }
}

# Use a previously created a service account to manage access token
resource "vault_gcp_secret_backend" "gcp" {
  credentials = file("creds.json")
  # credentials = var.gcp-dynamic-creds-sa
  path       = "${var.name}-path"

  default_lease_ttl_seconds = "120"
  max_lease_ttl_seconds     = "240"
}

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

output "backend" {
  value = vault_gcp_secret_backend.gcp.path
}

output "roleset" {
  value = vault_gcp_secret_roleset.infra-roleset.id
}

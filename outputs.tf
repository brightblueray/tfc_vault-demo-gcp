output "backend" {
  value = vault_gcp_secret_backend.gcp.path
}

output "roleset" {
  value = vault_gcp_secret_roleset.infra-roleset.roleset
}

provider "oci" {
  private_key_path     = var.private_key_path
  user_ocid            = var.user_ocid
  region               = var.region
  tenancy_ocid         = var.tenancy_ocid
  fingerprint          = var.fingerprint
}
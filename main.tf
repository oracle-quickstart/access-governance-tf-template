resource "null_resource" "si_creation_response" {
  count      = length(var.service_instance_display_name) > 0 ? 1 : 0
  depends_on = [oci_identity_user_group_membership.agcs_user_to_agcs_group, data.oci_identity_domains.admin_domain_data]

  provisioner "local-exec" {
    working_dir = path.module
    command     = "pip3 install -r ${path.module}/agcs-resources-scripts/requirements.txt --user"
    on_failure  = continue
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = "python3 ${path.module}/agcs-resources-scripts/create-ag-service-instance.py > ag_si_creation_response.txt"
    environment = {
      # Makes the config runnable from local machine using terraform CLI.
      IDCS_ENDPOINT                       = data.oci_identity_domains.admin_domain_data.domains[0].url
      ADMIN_OCID_SERVICE_INSTANCE         = var.user_ocid
      ADMIN_TENANCY_OCID_SERVICE_INSTANCE = var.tenancy_ocid
      ADMIN_FINGERPRINT_SERVICE_INSTANCE  = var.fingerprint
      ADMIN_PRIVATE_KEY_PATH              = var.private_key_path
      #      ADMIN_REGION_SERVICE_INSTANCE       = length(var.admin_region_service_instance) > 0 ? var.admin_region_service_instance : var.region
      ADMIN_REGION_SERVICE_INSTANCE = var.region

      AGCS_USER_OCID_OCI_SYSTEM         = var.use_existing_agcs_user ? var.agcs_user_ocid_oci_system : oci_identity_user.agcs_user[count.index].id
      AGCS_USER_TENANCY_OCID_OCI_SYSTEM = var.use_existing_agcs_user ? local.agcs_tenancy : oci_identity_user.agcs_user[count.index].compartment_id
      AGCS_USER_FINGERPRINT_OCI_SYSTEM  = var.use_existing_agcs_user ? var.agcs_user_fingerprint_oci_system : oci_identity_api_key.upload_api_key[count.index].fingerprint
      AGCS_USER_PRIVATE_KEY_PATH        = var.use_existing_agcs_user ? var.agcs_user_private_key_path : ""
      AGCS_USER_PRIVATE_KEY             = var.use_existing_agcs_user ? var.agcs_user_private_key : tls_private_key.private_keys[count.index].private_key_pem_pkcs8
      AGCS_USER_REGION_OCI_SYSTEM       = length(var.agcs_user_region_oci_system) > 0 ? var.agcs_user_region_oci_system : var.region

      USE_EXISTING_AGCS_USER            = var.use_existing_agcs_user
      AG_LICENSE_TYPE                   = var.ag_license_type
      SERVICE_INSTANCE_COMPARTMENT_OCID = var.service_instance_compartment_ocid
      SERVICE_INSTANCE_DISPLAY_NAME     = var.service_instance_display_name
      SERVICE_INSTANCE_DESCRIPTION      = var.service_instance_description
      OCI_SYSTEM_NAME                   = var.oci_system_name
      OCI_SYSTEM_DESCRIPTION            = var.oci_system_description

      NAMESPACE_SERVICE_ENDPOINT     = var.namespace_service_endpoint
      SHOULD_CREATE_CONNECTED_SYSTEM = var.should_create_connected_system
    }
  }
}

resource "null_resource" "si_deletion_response" {
  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    working_dir = path.module
     when       = destroy
    command     = "pip3 install -r ${path.module}/agcs-resources-scripts/requirements.txt --user"
    on_failure  = continue
  }

  depends_on = [data.oci_identity_domains.admin_domain_data]

  triggers = {
    instanceOCIDTrigger = lookup(data.external.created_instance.result, "output")
    # To Run from Terraform CLI
    ADMIN_OCID_SERVICE_INSTANCE         = var.user_ocid
    ADMIN_OCID_SERVICE_INSTANCE         = var.user_ocid
    ADMIN_TENANCY_OCID_SERVICE_INSTANCE = var.tenancy_ocid
    ADMIN_FINGERPRINT_SERVICE_INSTANCE  = var.fingerprint
    ADMIN_PRIVATE_KEY_PATH              = var.private_key_path
    IDCS_ENDPOINT                       = data.oci_identity_domains.admin_domain_data.domains[0].url
    #    ADMIN_REGION_SERVICE_INSTANCE       = length(var.admin_region_service_instance) > 0 ? var.admin_region_service_instance : var.region
    ADMIN_REGION_SERVICE_INSTANCE = var.region
    NAMESPACE_SERVICE_ENDPOINT    = var.namespace_service_endpoint
  }


  provisioner "local-exec" {
    working_dir = path.module
    when        = destroy
    on_failure  = continue
    command     = "python3 ${path.module}/agcs-resources-scripts/delete-ag-service-instance.py > ag_si_deletion_response.txt"
    environment = {
      instanceOCID  = self.triggers.instanceOCIDTrigger
      IDCS_ENDPOINT = self.triggers.IDCS_ENDPOINT
      # To Run from Terraform CLI
      ADMIN_OCID_SERVICE_INSTANCE         = self.triggers.ADMIN_OCID_SERVICE_INSTANCE
      ADMIN_OCID_SERVICE_INSTANCE         = self.triggers.ADMIN_OCID_SERVICE_INSTANCE
      ADMIN_TENANCY_OCID_SERVICE_INSTANCE = self.triggers.ADMIN_TENANCY_OCID_SERVICE_INSTANCE
      ADMIN_FINGERPRINT_SERVICE_INSTANCE  = self.triggers.ADMIN_FINGERPRINT_SERVICE_INSTANCE
      ADMIN_PRIVATE_KEY_PATH              = self.triggers.ADMIN_PRIVATE_KEY_PATH
      ADMIN_REGION_SERVICE_INSTANCE       = self.triggers.ADMIN_REGION_SERVICE_INSTANCE
      NAMESPACE_SERVICE_ENDPOINT          = self.triggers.NAMESPACE_SERVICE_ENDPOINT
    }
  }
}
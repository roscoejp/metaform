locals {
  // If you add more entries to this you'll need to add more removal steps and
  // dependencies at the end of this run.
  external_service_account_roles = [
    "roles/resourcemanager.projectCreator",
    "roles/compute.networkAdmin",
    "roles/resourcemanager.organizationAdmin",
  ]
}

resource "random_id" "id" {
  byte_length = 4
}

/******************************************************************************
* Ensure external robot has the necessary role bindings
******************************************************************************/
resource "google_organization_iam_member" "org_external" {
  count = "${var.org_id != "" ? 1 * length(local.external_service_account_roles) : 0}"

  org_id = "${var.org_id}"
  role   = "${local.external_service_account_roles[count.index]}"
  member = "serviceAccount:${var.external_service_account_name}"
}

resource "google_folder_iam_member" "folder_external" {
  count = "${var.folder_id != "" ? 1 * length(local.external_service_account_roles) : 0}"

  folder = "${var.folder_id}"
  role   = "${local.external_service_account_roles[count.index]}"
  member = "serviceAccount:${var.external_service_account_name}"
}

/******************************************************************************
* Create org internal project
******************************************************************************/
resource "google_project" "terraform" {
  depends_on = ["google_organization_iam_member.org_external", "google_folder_iam_member.folder_external"]

  name                = "${var.project_name}-${random_id.id.hex}"
  org_id              = "${var.org_id}"
  folder_id           = "${var.folder_id}"
  billing_account     = "${var.billing_account}"
  project_id          = "${var.project_name}-${random_id.id.hex}"
  auto_create_network = "${var.auto_create_network}"
}

/******************************************************************************
* Create org internal service account, key
******************************************************************************/
resource "google_service_account" "terraform" {
  account_id = "${var.internal_service_account_name}"
  project    = "${google_project.terraform.project_id}"
}

resource "google_service_account_key" "terraform" {
  service_account_id = "${google_service_account.terraform.email}"
}

/******************************************************************************
* Ensure org internal service account has org, folder, billing permissions
******************************************************************************/
resource "google_organization_iam_member" "org_internal_admin" {
  count = "${var.org_id != "" ? 1 : 0}"

  org_id = "${var.org_id}"
  role   = "roles/resourcemanager.organizationAdmin"
  member = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_folder_iam_member" "folder_internal_admin" {
  count = "${var.folder_id != "" ? 1 : 0}"

  folder = "${var.folder_id}"
  role   = "roles/resourcemanager.organizationAdmin"
  member = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_billing_account_iam_member" "billing_internal_admin" {
  count = "${var.billing_account != "" ? 1 : 0}"

  billing_account_id = "${var.billing_account}"
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.terraform.email}"
}

/******************************************************************************
* Remove external serviceaccount bindings
* Should probably use a bash script to modify a policy and then reapply using
* Terraform. See the Google reference:
* https://github.com/terraform-google-modules/terraform-google-iam/blob/master/scripts/create_additive_authoritative_structures.sh
******************************************************************************/
resource "null_resource" "remove_org_external_creator" {
  count      = "${var.org_id != "" ? 1 : 0}"
  depends_on = ["google_organization_iam_member.org_internal_admin"]

  provisioner "local-exec" {
    command = "gcloud organizations remove-iam-policy-binding ${var.org_id} --member=serviceAccount:${var.external_service_account_name} --role=roles/resourcemanager.projectCreator"
  }
}

resource "null_resource" "remove_org_external_network" {
  count      = "${var.org_id != "" ? 1 : 0}"
  depends_on = ["null_resource.remove_org_external_creator"]

  provisioner "local-exec" {
    command = "gcloud organizations remove-iam-policy-binding ${var.org_id} --member=serviceAccount:${var.external_service_account_name} --role=roles/compute.networkAdmin"
  }
}

resource "null_resource" "remove_org_external_admin" {
  count      = "${var.org_id != "" ? 1 : 0}"
  depends_on = ["null_resource.remove_org_external_network"]

  provisioner "local-exec" {
    command = "gcloud organizations remove-iam-policy-binding ${var.org_id} --member=serviceAccount:${var.external_service_account_name} --role=roles/resourcemanager.organizationAdmin"
  }
}

# Remove bindings from folders
resource "null_resource" "remove_folder_external_creator" {
  count      = "${var.folder_id != "" ? 1 : 0}"
  depends_on = ["google_folder_iam_member.folder_internal_admin"]

  provisioner "local-exec" {
    command = "gcloud resource-manager folders remove-iam-policy-binding ${var.folder_id} --member=serviceAccount:${var.external_service_account_name} --role=roles/resourcemanager.projectCreator"
  }
}

resource "null_resource" "remove_folder_external_network" {
  count      = "${var.folder_id != "" ? 1 : 0}"
  depends_on = ["null_resource.remove_folder_external_creator"]

  provisioner "local-exec" {
    command = "gcloud resource-manager folders remove-iam-policy-binding ${var.folder_id} --member=serviceAccount:${var.external_service_account_name} --role=roles/compute.networkAdmin"
  }
}

resource "null_resource" "remove_folder_external_admin" {
  count      = "${var.folder_id != "" ? 1 : 0}"
  depends_on = ["null_resource.remove_folder_external_network"]

  provisioner "local-exec" {
    command = "gcloud resource-manager folders remove-iam-policy-binding ${var.folder_id} --member=serviceAccount:${var.external_service_account_name} --role=roles/resourcemanager.organizationAdmin"
  }
}

# Remove bindings from billing account
resource "null_resource" "remove_external_billing" {
  count = "${var.billing_account != "" ? 1 : 0}"

  depends_on = [
    "google_organization_iam_member.org_internal_admin",
    "google_folder_iam_member.folder_internal_admin",
  ]

  provisioner "local-exec" {
    command = "gcloud resource-manager folders remove-iam-policy-binding ${var.folder_id} --member=serviceAccount:${var.external_service_account_name} --role=roles/resourcemanager.organizationAdmin"
  }
}

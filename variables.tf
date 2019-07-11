// Provider vars
variable "credentials" {
  description = "(Optional) Either the path to or the contents of a service account key file in JSON format. You can manage key files using the Cloud Console."
}

// External service account
variable "external_service_account_name" {
  description = "(Required) Identity that will be granted the Project Creator role."
}

// Billing vars
variable "billing_account" {
  description = "(Optional) The alphanumeric ID of the billing account this project belongs to. The user or service account performing this operation with Terraform must have Billing Account Administrator privileges (roles/billing.admin) in the organization. See Google Cloud Billing API Access Control for more details."
  default     = ""
}

// Project vars
variable "project_name" {
  description = "(Required) The project ID. Changing this forces a new project to be created."
  default     = "terraform-admin"
}

variable "org_id" {
  description = "(Optional) The numeric ID of the organization this project belongs to. Changing this forces a new project to be created. Only one of org_id or folder_id may be specified. If the org_id is specified then the project is created at the top level. Changing this forces the project to be migrated to the newly specified organization."
  default     = ""
}

variable "folder_id" {
  description = "(Optional) The numeric ID of the folder this project should be created under. Only one of org_id or folder_id may be specified. If the folder_id is specified, then the project is created under the specified folder. Changing this forces the project to be migrated to the newly specified folder."
  default     = ""
}

variable "auto_create_network" {
  description = "(Optional) Create the 'default' network automatically. Default true. If set to false, the default network will be deleted. Note that, for quota purposes, you will still need to have 1 network slot available to create the project succesfully, even if you set auto_create_network to false, since the network will exist momentarily. Setting this to false also requires billing to be enabled on the new project."
  default     = true
}

// Service Account vars
variable "internal_service_account_name" {
  description = "(Required) The account id that is used to generate the service account email address and a stable unique id. It is unique within a project, must be 6-30 characters long, and match the regular expression [a-z]([-a-z0-9]*[a-z0-9]) to comply with RFC1035. Changing this forces a new service account to be created."
  default     = "terraform-admin"
}

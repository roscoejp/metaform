output "internal_project_id" {
  value = "${google_project.terraform.project_id}"
}

output "internal_terraform_service_account_email" {
  value = "${google_service_account.terraform.email}"
}

output "internal_terraform_service_account_credentials" {
  description = "Base 64 encoded service account JSON key"
  value       = "${base64decode(google_service_account_key.terraform.private_key)}"
}

// Uncommenting this will write the credentials file to disk
# output "terraform_credentials_file" {
#   description = "Location of the Terraform credentials JSON file."
#   value       = "${local_file.terraform_credentials_file.filename}"
# }

# resource "local_file" "terraform_credentials_file" {
#   content  = "${base64decode(google_service_account_key.terraform.private_key)}"
#   filename = "./terraform-creds.json"
# }
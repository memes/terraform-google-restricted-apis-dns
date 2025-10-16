variable "project_id" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id variable must must be 6 to 30 lowercase letters, digits, or hyphens; it must start with a letter and cannot end with a hyphen."
  }
  description = <<-EOD
  The GCP project identifier where the VPC network will be created.
  EOD
}

variable "names" {
  type     = list(string)
  nullable = true
  validation {
    condition     = var.names == null ? true : alltrue([for name in var.names : can(regex("^[a-z][a-z0-9-]{0,62}$", name))])
    error_message = "Each names variable entry must be RFC1035 compliant and between 1 and 63 characters in length."
  }
  description = <<-EOD
  The list of names to use when creating VPC network resources.
  EOD
}

variable "project_id" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id variable must must be 6 to 30 lowercase letters, digits, or hyphens; it must start with a letter and cannot end with a hyphen."
  }
  description = <<-EOD
  The GCP project identifier where the Cloud DNS resources will be created.
  EOD
}

variable "name" {
  type = string
  validation {
    # TODO
    condition     = can(regex("^[a-z][a-z0-9-]{0,51}$", var.name))
    error_message = "The name variable must be RFC1035 compliant and between 1 and 52 characters in length."
  }
  default     = "restricted"
  description = <<-EOD
  The name to use when naming resources managed by this module. Must be RFC1035
  compliant and between 1 and 52 characters in length, inclusive.
  EOD
}

variable "overrides" {
  type = list(string)
  default = [
    "gcr.io",
    "pkg.dev",
  ]
}

variable "labels" {
  type = map(string)
  validation {
    # GCP resource labels must be lowercase alphanumeric, underscore or hyphen,
    # and the key must be <= 63 characters in length
    condition     = length(compact([for k, v in var.labels : can(regex("^[a-z][a-z0-9_-]{0,62}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v)) ? "x" : ""])) == length(keys(var.labels))
    error_message = "Each label key:value pair must match expectations."
  }
  default     = {}
  description = <<-EOD
  An optional map of key:value labels to apply to the resources. Default value
  is an empty map.
  EOD
}

variable "network_self_links" {
  type = list(string)
  validation {
    condition     = length(compact([for net in var.network_self_links : can(regex("^(?:https://www.googleapis.com/compute/v1/)?projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/global/networks/[a-z]([a-z0-9-]+[a-z0-9])?$", net)) ? "x" : ""])) == length(var.network_self_links)
    error_message = "Each network_self_links value must be a fully-qualified self-link URI."
  }
  description = <<-EOD
  Fully-qualified VPC network self-links to which the restricted APIs Cloud DNS
  zones will be attached. If left empty, the Cloud DNS zones will need to be
  associated with the VPCs outside this module.
  EOD
}

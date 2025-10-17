variable "project_id" {
  type     = string
  nullable = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project_id variable must must be 6 to 30 lowercase letters, digits, or hyphens; it must start with a letter and cannot end with a hyphen."
  }
  description = <<-EOD
  The GCP project identifier where the Cloud DNS resources will be created.
  EOD
}

variable "name" {
  type     = string
  nullable = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,51}$", var.name))
    error_message = "The name variable must be RFC1035 compliant and between 1 and 52 characters in length."
  }
  default     = "restricted"
  description = <<-EOD
  The name to use when naming resources managed by this module. Must be RFC1035
  compliant and between 1 and 52 characters in length, inclusive.
  EOD
}

variable "description" {
  type     = string
  nullable = true
  validation {
    condition     = var.description == null ? true : length(var.description) <= 1024
    error_message = "Description must be a string with at most 1024 characters."
  }
  default     = "Override DNS entries for Google APIs access"
  description = <<-EOD
  A human readable description to apply to DNS records. Default is 'Override DNS entries for Google APIs access'.
  EOD
}

variable "overrides" {
  type     = list(string)
  nullable = true
  validation {
    condition     = var.overrides == null ? true : alltrue([for override in var.overrides : can(regex("^(?:[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\\.)+[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\\.?$", override))])
    error_message = "Each overrides entry must be a valid DNS domain."
  }
  default = [
    "gcr.io",
    "gke.goog",
    "pkg.dev",
  ]
  description = <<-EOD
  A list of additional Google Cloud endpoint domains that should be forced to
  resolve through restricted.googleapis.com. These must be compatible with VPC
  Service Controls. Default value will allow restricted access to GCR, GAR,
  and to GKE DNS endpoints in `gke.goog`.
  EOD
}

variable "labels" {
  type     = map(string)
  nullable = true
  validation {
    # GCP resource labels must be lowercase alphanumeric, underscore or hyphen,
    # and the key must be <= 63 characters in length
    condition     = var.labels == null ? true : alltrue([for k, v in var.labels : can(regex("^[a-z][a-z0-9_-]{0,62}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v))])
    error_message = "Each label key:value pair must match expectations."
  }
  default     = {}
  description = <<-EOD
  An optional map of key:value labels to apply to the resources. Default value
  is an empty map.
  EOD
}

variable "network_self_links" {
  type     = list(string)
  nullable = true
  validation {
    condition     = var.network_self_links == null ? true : alltrue([for net in var.network_self_links : can(regex("^(?:https://www.googleapis.com/compute/v1/)?projects/[a-z][a-z0-9-]{4,28}[a-z0-9]/global/networks/[a-z]([a-z0-9-]+[a-z0-9])?$", net))])
    error_message = "Each network_self_links value must be a fully-qualified self-link URI."
  }
  description = <<-EOD
  Fully-qualified VPC network self-links to which the restricted APIs Cloud DNS
  zones will be attached. If left empty, the Cloud DNS zones will need to be
  associated with the VPCs outside this module.
  EOD
}

variable "use_private_access_endpoints" {
  type        = bool
  default     = false
  description = <<-EOD
  Add Cloud DNS entries that resolve to the private.googleapis.com endpoints instead of restricted.googleapis.com. Use
  this when creating VPCs which require private Google APIs access but for which the restricted endpoints are not
  supported for target GCP services.
  EOD
}

variable "addresses" {
  type = object({
    ipv4 = set(string)
    ipv6 = set(string)
  })
  nullable = true
  validation {
    condition     = var.addresses == null ? true : (var.addresses.ipv4 == null ? true : alltrue([for address in var.addresses.ipv4 : can(cidrhost(format("%s/32", address), 0))])) || (var.addresses.ipv6 == null ? true : alltrue([for address in var.addresses.ipv6 : can(cidrhost(format("%s/128", address), 0))]))
    error_message = "If addresses is not null, any IPv4 or IPv6 address must be valid."
  }
  default     = null
  description = <<-EOD
  Override the addresses used for Google APIs DNS A and/or AAAA records. If the variable contains *any* ipv4 or ipv6
  addresses the values will be used instead of standard Google endpoints.
  EOD
}

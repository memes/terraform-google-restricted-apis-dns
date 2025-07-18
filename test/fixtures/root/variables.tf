variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = "Override DNS entries for Google APIs access"
}

variable "overrides" {
  type = list(string)
  default = [
    "gcr.io",
    "pkg.dev",
  ]
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "use_private_access_endpoints" {
  type    = bool
  default = false
}

variable "addresses" {
  type = object({
    ipv4 = set(string)
    ipv6 = set(string)
  })
  nullable = true
  default  = null
}

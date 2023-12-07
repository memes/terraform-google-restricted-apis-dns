variable "project_id" {
  type = string
}

variable "name" {
  type = string
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

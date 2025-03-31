# Restricted APIs DNS module

![GitHub release](https://img.shields.io/github/v/release/memes/terraform-google-restricted-apis-dns?sort=semver)
![Maintenance](https://img.shields.io/maintenance/yes/2024)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

This Terraform module creates opinionated private Cloud DNS records that resolve
Google Cloud API endpoints to the `restricted.googleapis.com` or
`private.googleapis.com` endpoints.

* A zone is created to override all `*.googleapis.com` entries by resolving to
  * `199.36.153.4/30` and `2600:2d00:0002:1000::/64`, or
  * `199.36.153.8/30` and `2600:2d00:002:2000::/64`, or
  * custom IPv4 and/or IPv6 addresses provided by `addresses` variable
  > NOTE: Private connectivity routes to these addresses are not managed by this
  > module; see [multi-region-private-network] for companion module
* Additional domains are set through the `overrides` variable; by default the
  `gcr.io` and `pkg.dev` domains for GCR and GAR are included.

## Opinions

1. A zone for `googleapis.com` domain is **always** created
2. `A` and `AAAA` records will **always** be created for each domain if there is
   an associated set IPv4 or IPv6 addresses, respectively
3. Wildcard zones (e.g. `*.googleapis.com`) will resolve to the base domain via
   `CNAME`

> NOTE: The intent of this module is to easily repeat a common use-case where
> all Google Cloud endpoints must resolve to a privately routable endpoint.
> It is not a general purpose Cloud DNS module; use Google's [cloud-dns] module
> for that purpose.

## Examples

### Default use-case

|Item|Managed by module|Description|
|----|-----------------|-----------|
|Override googleapis.com|&check;|Always directed to `restricted.googleapis.com`|
|Override gcr.io|&check;|Default `overrides` value will direct to `restricted.googleapis.com`|
|Override pkg.dev|&check;|Default `overrides` value will direct to `restricted.googleapis.com`|
|Added to VPC network|&check;|Zones will be added as Private Cloud DNS to any VPC network provided in `network_self_links`|
|Route to private endpoints||Must be managed per-VPC|

```hcl
module "restricted_apis" {
    source  = "memes/restricted-apis-dns/google"
    version = "2.0.0"
    project_id = "my-project-id"
    network_self_links = [
        "projects/my-project-id/globals/network/my-network",
    ]
}
```

### Disable restricted override for Container Registry and Artifact Registry

|Item|Managed by module|Description|
|----|-----------------|-----------|
|Override googleapis.com|&check;|Always directed to `restricted.googleapis.com`|
|Override gcr.io||Setting `overrides` to []|
|Override pkg.dev||Setting `overrides` to []|
|Added to VPC network|&check;|Zones will be added as Private Cloud DNS to any VPC network provided in `network_self_links`|
|Route to private endpoints||Must be managed per-VPC|

```hcl
module "restricted_apis" {
    source  = "memes/restricted-apis-dns/google"
    version = "2.0.0"
    project_id = "my-project-id"
    overrides = []
    network_self_links = [
        "projects/my-project-id/globals/network/my-network",
    ]
}
```

### Enable private access overrides

|Item|Managed by module|Description|
|----|-----------------|-----------|
|Override googleapis.com|&check;|Always directed to `private.googleapis.com`|
|Override gcr.io|&check;|Default `overrides` value will direct to `private.googleapis.com`|
|Override pkg.dev|&check;|Default `overrides` value will direct to `private.googleapis.com`|
|Added to VPC network|&check;|Zones will be added as Private Cloud DNS to any VPC network provided in `network_self_links`|
|Route to private endpoints||Must be managed per-VPC|

```hcl
module "private_apis" {
    source  = "memes/restricted-apis-dns/google"
    version = "2.0.0"
    project_id = "my-project-id"
    use_private_access_endpoints = true
    network_self_links = [
        "projects/my-project-id/globals/network/my-network",
    ]
}
```

### Enable private access with support for Cloud Functions

|Item|Managed by module|Description|
|----|-----------------|-----------|
|Override googleapis.com|&check;|Always directed to `private.googleapis.com`|
|Override gcr.io|&check;|Explicit `overrides` value will direct to `private.googleapis.com`|
|Override pkg.dev|&check;|Explicit `overrides` value will direct to `private.googleapis.com`|
|Added to VPC network|&check;|Zones will be added as Private Cloud DNS to any VPC network provided in `network_self_links`|
|Route to private endpoints||Must be managed per-VPC|
|Override cloudfunctions.net|&check;|Explicit `overrides` value will direct to `private.googleapis.com`|

```hcl
module "private_apis" {
    source  = "memes/restricted-apis-dns/google"
    version = "2.0.0"
    project_id = "my-project-id"
    use_private_access_endpoints = true
    overrides = [
        "gcr.io",
        "pkg.dev",
        "cloudfunctions.net",
    ]
    network_self_links = [
        "projects/my-project-id/globals/network/my-network",
    ]
}
```

### Custom addresses for zones

|Item|Managed by module|Description|
|----|-----------------|-----------|
|Override googleapis.com|&check;|`10.10.10.10`|
|Override gcr.io|&check;|Default `overrides` value will direct to `10.10.10.10`|
|Override pkg.dev|&check;|Default `overrides` value will direct to `10.10.10.10`|
|Added to VPC network|&check;|Zones will be added as Private Cloud DNS to any VPC network provided in `network_self_links`|
|Route to private endpoints||Must be managed per-VPC|

```hcl
module "private_apis" {
    source  = "memes/restricted-apis-dns/google"
    version = "2.0.0"
    project_id = "my-project-id"
    addresses = [
        ipv4 = ["10.10.10.10"],
        ipv6 = null
    ]
    network_self_links = [
        "projects/my-project-id/globals/network/my-network",
    ]
}
```
<!-- markdownlint-disable MD033 MD034-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.27 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_dns_managed_zone.zone](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone) | resource |
| [google_dns_record_set.zone_a](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.zone_aaaa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.zone_cname](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_network_self_links"></a> [network\_self\_links](#input\_network\_self\_links) | Fully-qualified VPC network self-links to which the restricted APIs Cloud DNS<br/>zones will be attached. If left empty, the Cloud DNS zones will need to be<br/>associated with the VPCs outside this module. | `list(string)` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project identifier where the Cloud DNS resources will be created. | `string` | n/a | yes |
| <a name="input_addresses"></a> [addresses](#input\_addresses) | Override the addresses used for Google APIs DNS A and/or AAAA records. If the variable contains *any* ipv4 or ipv6<br/>addresses the values will be used instead of standard Google endpoints. | <pre>object({<br/>    ipv4 = set(string)<br/>    ipv6 = set(string)<br/>  })</pre> | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | A human readable description to apply to DNS records. Default is 'Override DNS entries for Google APIs access'. | `string` | `"Override DNS entries for Google APIs access"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | An optional map of key:value labels to apply to the resources. Default value<br/>is an empty map. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name to use when naming resources managed by this module. Must be RFC1035<br/>compliant and between 1 and 52 characters in length, inclusive. | `string` | `"restricted"` | no |
| <a name="input_overrides"></a> [overrides](#input\_overrides) | A list of additional Google Cloud endpoint domains that should be forced to<br/>resolve through restricted.googleapis.com. These must be compatible with VPC<br/>Service Controls. Default value will allow restricted access to GCR and GAR. | `list(string)` | <pre>[<br/>  "gcr.io",<br/>  "pkg.dev"<br/>]</pre> | no |
| <a name="input_use_private_access_endpoints"></a> [use\_private\_access\_endpoints](#input\_use\_private\_access\_endpoints) | Add Cloud DNS entries that resolve to the private.googleapis.com endpoints instead of restricted.googleapis.com. Use<br/>this when creating VPCs which require private Google APIs access but for which the restricted endpoints are not<br/>supported for target GCP services. | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
<!-- markdownlint-enable MD033 MD034 -->

[multi-region-private-network]: https://registry.terraform.io/modules/memes/multi-region-private-network/google/latest?tab=readme
[cloud-dns]: https://registry.terraform.io/modules/terraform-google-modules/cloud-dns/google/4latest?tab=readme

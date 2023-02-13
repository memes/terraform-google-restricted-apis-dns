# Restricted APIs DNS module

![GitHub release](https://img.shields.io/github/v/release/memes/terraform-google-restricted-apis-dns?sort=semver)
![Maintenance](https://img.shields.io/maintenance/yes/2023)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](CODE_OF_CONDUCT.md)

This Terraform module creates private Cloud DNS records that resolve Google Cloud
APIs to the `restricted.googleapis.com` private endpoints.

* A zone is created to override `*.googleapis.com` to `restricted.googleapis.com`
  via `199.36.153.4/30`
  > NOTE: Private connectivity route to `199.36.153.4/30` is not managed by this
  > module; see [multi-region-private-network] for companion module
* Additional domains are set through the `overrides` variable; by default the
  `gcr.io` and `pkg.dev` domains for GCR and GAR are includes.

## Examples

### Enable standard overrides

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
    version = "1.0.1"
    project_id = "my-project-id"
    network_self_links = [
        "projects/my-project-id/globals/network/my-network",
    ]
}
```

<!-- markdownlint-disable MD033 MD034-->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.42 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_restrictedapis"></a> [restrictedapis](#module\_restrictedapis) | terraform-google-modules/cloud-dns/google | 4.1.0 |
| <a name="module_zones"></a> [zones](#module\_zones) | terraform-google-modules/cloud-dns/google | 4.1.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_network_self_links"></a> [network\_self\_links](#input\_network\_self\_links) | Fully-qualified VPC network self-links to which the restricted APIs Cloud DNS<br>zones will be attached. If left empty, the Cloud DNS zones will need to be<br>associated with the VPCs outside this module. | `list(string)` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The GCP project identifier where the Cloud DNS resources will be created. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | An optional map of key:value labels to apply to the resources. Default value<br>is an empty map. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The name to use when naming resources managed by this module. Must be RFC1035<br>compliant and between 1 and 52 characters in length, inclusive. | `string` | `"restricted"` | no |
| <a name="input_overrides"></a> [overrides](#input\_overrides) | n/a | `list(string)` | <pre>[<br>  "gcr.io",<br>  "pkg.dev"<br>]</pre> | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable MD033 MD034 -->

[multi-region-private-network]: https://registry.terraform.io/modules/memes/multi-region-private-network/google/latest?tab=readme

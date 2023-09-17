# terrraform-k8s-learn
Learn Terraform and Kubernetes basics

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.23.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gitea_postgresql"></a> [gitea\_postgresql](#module\_gitea\_postgresql) | ./modules/postgresql | n/a |
| <a name="module_netbox_gitea"></a> [netbox\_gitea](#module\_netbox\_gitea) | ./modules/gitea | n/a |
| <a name="module_netbox_netbox"></a> [netbox\_netbox](#module\_netbox\_netbox) | ./modules/netbox | n/a |
| <a name="module_netbox_postgresql"></a> [netbox\_postgresql](#module\_netbox\_postgresql) | ./modules/postgresql | n/a |
| <a name="module_netbox_redis"></a> [netbox\_redis](#module\_netbox\_redis) | ./modules/redis | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_client_certificate"></a> [client\_certificate](#input\_client\_certificate) | Client certificate | `string` | n/a | yes |
| <a name="input_client_key"></a> [client\_key](#input\_client\_key) | Client key | `string` | n/a | yes |
| <a name="input_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#input\_cluster\_ca\_certificate) | Cluster certificate | `string` | n/a | yes |
| <a name="input_gitea_db_password"></a> [gitea\_db\_password](#input\_gitea\_db\_password) | Gitea database password | `string` | n/a | yes |
| <a name="input_host"></a> [host](#input\_host) | Kubernetes cluster | `string` | n/a | yes |
| <a name="input_netbox_password"></a> [netbox\_password](#input\_netbox\_password) | Netbox database password | `string` | n/a | yes |
| <a name="input_redis_cache_password"></a> [redis\_cache\_password](#input\_redis\_cache\_password) | Redis db password | `string` | n/a | yes |
| <a name="input_redis_password"></a> [redis\_password](#input\_redis\_password) | Redis db password | `string` | n/a | yes |
| <a name="input_secret_key"></a> [secret\_key](#input\_secret\_key) | Netbox secret key | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
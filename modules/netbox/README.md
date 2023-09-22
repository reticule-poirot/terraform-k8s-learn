<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_config_map.netbox_env](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_cron_job_v1.netbox_cron](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cron_job_v1) | resource |
| [kubernetes_deployment.netbox](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_ingress_v1.netbox](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_persistent_volume_claim.netbox_pvc](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_secret.netbox_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.netbox_tls](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.netbox_service](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_fqdn"></a> [fqdn](#input\_fqdn) | Netbox fqdn | `string` | `"netbox.example.local"` | no |
| <a name="input_name"></a> [name](#input\_name) | Netbox pod name | `string` | `"netbox"` | no |
| <a name="input_netbox_data_size"></a> [netbox\_data\_size](#input\_netbox\_data\_size) | Netbox data volume size | `string` | `"0.5Gi"` | no |
| <a name="input_netbox_db"></a> [netbox\_db](#input\_netbox\_db) | Netbox database name | `string` | `"netbox"` | no |
| <a name="input_netbox_db_password"></a> [netbox\_db\_password](#input\_netbox\_db\_password) | Netbox db password | `string` | n/a | yes |
| <a name="input_netbox_db_port"></a> [netbox\_db\_port](#input\_netbox\_db\_port) | Netbox db port | `number` | `5432` | no |
| <a name="input_netbox_db_service"></a> [netbox\_db\_service](#input\_netbox\_db\_service) | Netbox database service | `string` | n/a | yes |
| <a name="input_netbox_db_user"></a> [netbox\_db\_user](#input\_netbox\_db\_user) | Netbox db user | `string` | `"netbox"` | no |
| <a name="input_netbox_version"></a> [netbox\_version](#input\_netbox\_version) | Netbox version | `string` | `"latest"` | no |
| <a name="input_redis_cache_password"></a> [redis\_cache\_password](#input\_redis\_cache\_password) | Redis cache password | `string` | n/a | yes |
| <a name="input_redis_cache_service"></a> [redis\_cache\_service](#input\_redis\_cache\_service) | Redis cache service | `string` | n/a | yes |
| <a name="input_redis_password"></a> [redis\_password](#input\_redis\_password) | Redis password | `string` | n/a | yes |
| <a name="input_redis_port"></a> [redis\_port](#input\_redis\_port) | Redis db port | `number` | `6379` | no |
| <a name="input_redis_service"></a> [redis\_service](#input\_redis\_service) | Redis service | `string` | n/a | yes |
| <a name="input_secret_key"></a> [secret\_key](#input\_secret\_key) | Netbox secret key | `string` | n/a | yes |
| <a name="input_tls_cert"></a> [tls\_cert](#input\_tls\_cert) | Netbox tls certificate | `string` | `null` | no |
| <a name="input_tls_key"></a> [tls\_key](#input\_tls\_key) | Netbox tls certificate key | `string` | `null` | no |
| <a name="input_use_ingress"></a> [use\_ingress](#input\_use\_ingress) | Use ingress | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_netbox_db"></a> [netbox\_db](#output\_netbox\_db) | n/a |
| <a name="output_netbox_db_user"></a> [netbox\_db\_user](#output\_netbox\_db\_user) | n/a |
<!-- END_TF_DOCS -->
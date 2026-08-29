<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.16 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 3.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_config_map_v1.postgresql_env](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.postgresql_pvc](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_persistent_volume_v1.postgresql_pv](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_v1) | resource |
| [kubernetes_secret_v1.postgresql_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_service_v1.postgresql_service](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1) | resource |
| [kubernetes_stateful_set_v1.postgresql](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/stateful_set_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Postgresql pod name | `string` | n/a | yes |
| <a name="input_psql_data_size"></a> [psql\_data\_size](#input\_psql\_data\_size) | Postgresql data volume size | `string` | `"1Gi"` | no |
| <a name="input_psql_db"></a> [psql\_db](#input\_psql\_db) | Postgresql database name | `string` | n/a | yes |
| <a name="input_psql_password"></a> [psql\_password](#input\_psql\_password) | Postgresql user password | `string` | n/a | yes |
| <a name="input_psql_port"></a> [psql\_port](#input\_psql\_port) | Postgresql port | `number` | `5432` | no |
| <a name="input_psql_user"></a> [psql\_user](#input\_psql\_user) | Postgresql database user | `string` | n/a | yes |
| <a name="input_psql_version"></a> [psql\_version](#input\_psql\_version) | Postgresql version | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service"></a> [service](#output\_service) | Postgresql service name and port |
<!-- END_TF_DOCS -->
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
| [kubernetes_config_map.gitea_env](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_deployment.gitea](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_persistent_volume_claim.gitea_pvc](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_secret.gitea_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.gitea_service](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_gitea_data_size"></a> [gitea\_data\_size](#input\_gitea\_data\_size) | Gitea dats volume size | `string` | `"1Gi"` | no |
| <a name="input_gitea_db"></a> [gitea\_db](#input\_gitea\_db) | Gitea db | `string` | `"gitea"` | no |
| <a name="input_gitea_db_password"></a> [gitea\_db\_password](#input\_gitea\_db\_password) | Netbox db password | `string` | n/a | yes |
| <a name="input_gitea_db_port"></a> [gitea\_db\_port](#input\_gitea\_db\_port) | Gitea db port | `number` | `5432` | no |
| <a name="input_gitea_db_service"></a> [gitea\_db\_service](#input\_gitea\_db\_service) | Gitea database service | `string` | n/a | yes |
| <a name="input_gitea_db_type"></a> [gitea\_db\_type](#input\_gitea\_db\_type) | Gitea db type | `string` | `"postgres"` | no |
| <a name="input_gitea_db_user"></a> [gitea\_db\_user](#input\_gitea\_db\_user) | Gitea db user | `string` | `"gitea"` | no |
| <a name="input_gitea_version"></a> [gitea\_version](#input\_gitea\_version) | Gitea version | `string` | `"latest-rootless"` | no |
| <a name="input_name"></a> [name](#input\_name) | Gitea pod name | `string` | `"gitea"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitea_db"></a> [gitea\_db](#output\_gitea\_db) | Gitea db |
| <a name="output_gitea_db_user"></a> [gitea\_db\_user](#output\_gitea\_db\_user) | Gitea db user |
<!-- END_TF_DOCS -->
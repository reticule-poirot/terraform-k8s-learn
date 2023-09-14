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
| [kubernetes_deployment.redis_deployment](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_persistent_volume_claim.redis_pvc](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_secret.redis_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_service.redis_service](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_command"></a> [command](#input\_command) | Redis container entry point | `list(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Redis pod name | `string` | n/a | yes |
| <a name="input_redis_data_size"></a> [redis\_data\_size](#input\_redis\_data\_size) | Redis data volume size | `string` | `"1Gi"` | no |
| <a name="input_redis_password"></a> [redis\_password](#input\_redis\_password) | Redis db password | `string` | n/a | yes |
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | Redis version | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service"></a> [service](#output\_service) | Redis service name |
<!-- END_TF_DOCS -->
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
| [kubernetes_config_map_v1.prometheus_config](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_deployment_v1.prometheus](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment_v1) | resource |
| [kubernetes_ingress_v1.netbox](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress_v1) | resource |
| [kubernetes_persistent_volume_claim_v1.prometheus_pvc](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim_v1) | resource |
| [kubernetes_service_v1.prometheus_service](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_fqdn"></a> [fqdn](#input\_fqdn) | Prometheus fqdn | `string` | `"prometheus.example.local"` | no |
| <a name="input_name"></a> [name](#input\_name) | Prometheus pod name | `string` | `"prometheus"` | no |
| <a name="input_prometheus_config"></a> [prometheus\_config](#input\_prometheus\_config) | Prometheus config | `string` | n/a | yes |
| <a name="input_prometheus_data_size"></a> [prometheus\_data\_size](#input\_prometheus\_data\_size) | Postgresql data volume size | `string` | `"0.5Gi"` | no |
| <a name="input_prometheus_version"></a> [prometheus\_version](#input\_prometheus\_version) | prom/prometheus image tag | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
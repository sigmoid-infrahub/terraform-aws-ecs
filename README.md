# Module: ECS

This module creates an Amazon ECS cluster, task definitions, and services, supporting both Fargate and EC2 capacity providers.

## Features
- ECS Cluster management with Container Insights support
- Capacity provider strategy support (EC2, FARGATE, FARGATE_SPOT)
- Task Definition and Service management
- Service Connect integration
- Execute command configuration
- Network configuration (Subnets, Security Groups, Public IP)

## Usage
```hcl
module "ecs" {
  source = "../../terraform-modules/terraform-aws-ecs"

  cluster_name = "my-cluster"
}
```

## Inputs
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_name` | `string` | n/a | ECS cluster name |
| `capacity_providers` | `list(string)` | `[]` | Capacity providers |
| `default_capacity_provider_strategy` | `any` | `null` | Default capacity provider strategy |
| `container_insights` | `string` | `"enabled"` | Container insights setting |
| `services` | `any` | `[]` | Service definitions |
| `task_definitions` | `any` | `[]` | Task definition specs |
| `subnets` | `list(string)` | `[]` | Subnets for services |
| `security_groups` | `list(string)` | `[]` | Security groups for services |
| `assign_public_ip` | `bool` | `false` | Assign public IP in awsvpc mode |
| `execute_command_configuration` | `any` | `null` | Execute command configuration |
| `service_connect_defaults` | `any` | `null` | Service connect defaults |
| `tags` | `map(string)` | `{}` | Tags to apply |

## Outputs
| Name | Description |
|------|-------------|
| `cluster_id` | ECS cluster ID |
| `cluster_arn` | ECS cluster ARN |
| `module` | Full module outputs |

## Environment Variables
None

## Notes
- `capacity_providers` can include EC2, FARGATE, FARGATE_SPOT.
- Task definitions and services can be passed as complex objects for flexible configuration.

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.container_insights
  }

  dynamic "execute_command_configuration" {
    for_each = var.execute_command_configuration == null ? [] : [var.execute_command_configuration]
    content {
      kms_key_id = lookup(execute_command_configuration.value, "kms_key_id", null)
      logging    = lookup(execute_command_configuration.value, "logging", null)

      dynamic "log_configuration" {
        for_each = lookup(execute_command_configuration.value, "log_configuration", null) == null ? [] : [execute_command_configuration.value.log_configuration]
        content {
          cloud_watch_log_group_name     = lookup(log_configuration.value, "cloud_watch_log_group_name", null)
          cloud_watch_encryption_enabled = lookup(log_configuration.value, "cloud_watch_encryption_enabled", null)
          s3_bucket_name                 = lookup(log_configuration.value, "s3_bucket_name", null)
          s3_bucket_encryption_enabled   = lookup(log_configuration.value, "s3_bucket_encryption_enabled", null)
          s3_key_prefix                  = lookup(log_configuration.value, "s3_key_prefix", null)
        }
      }
    }
  }

  dynamic "service_connect_defaults" {
    for_each = var.service_connect_defaults == null ? [] : [var.service_connect_defaults]
    content {
      namespace = lookup(service_connect_defaults.value, "namespace", null)
    }
  }

  tags = local.resolved_tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count = length(var.capacity_providers) > 0 || var.default_capacity_provider_strategy != null ? 1 : 0

  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy == null ? [] : var.default_capacity_provider_strategy
    content {
      base              = lookup(default_capacity_provider_strategy.value, "base", null)
      weight            = lookup(default_capacity_provider_strategy.value, "weight", null)
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  for_each = { for entry in var.task_definitions : entry.family => entry }

  family                   = each.value.family
  container_definitions    = jsonencode(each.value.container_definitions)
  cpu                      = lookup(each.value, "cpu", null)
  memory                   = lookup(each.value, "memory", null)
  network_mode             = lookup(each.value, "network_mode", null)
  requires_compatibilities = lookup(each.value, "requires_compatibilities", null)
  execution_role_arn       = lookup(each.value, "execution_role_arn", null)
  task_role_arn            = lookup(each.value, "task_role_arn", null)

  dynamic "volume" {
    for_each = lookup(each.value, "volumes", [])
    content {
      name = volume.value.name

      dynamic "host_path" {
        for_each = lookup(volume.value, "host", null) == null ? [] : [volume.value.host]
        content {
          path = lookup(host_path.value, "sourcePath", null)
        }
      }
    }
  }

  tags = local.resolved_tags
}

resource "aws_ecs_service" "this" {
  for_each = { for entry in var.services : entry.name => entry }

  name            = each.value.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.value.task_definition_key].arn
  desired_count   = lookup(each.value, "desired_count", 0)

  deployment_minimum_healthy_percent = lookup(each.value, "deployment_minimum_healthy_percent", null)
  deployment_maximum_percent         = lookup(each.value, "deployment_maximum_percent", null)
  enable_execute_command             = lookup(each.value, "enable_execute_command", null)

  dynamic "load_balancer" {
    for_each = lookup(each.value, "load_balancer", null) == null ? [] : [each.value.load_balancer]
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "network_configuration" {
    for_each = length(var.subnets) == 0 ? [] : [1]
    content {
      subnets          = var.subnets
      security_groups  = var.security_groups
      assign_public_ip = var.assign_public_ip
    }
  }

  tags = local.resolved_tags
}

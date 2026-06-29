resource "aws_iam_role" "task_execution" {
  count = var.create_task_execution_role ? 1 : 0

  name = "${var.cluster_name}-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.resolved_tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  count = var.create_task_execution_role ? 1 : 0

  role       = aws_iam_role.task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  count = var.create_task_role ? 1 : 0

  name = "${var.cluster_name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.resolved_tags
}

resource "aws_iam_role_policy_attachment" "task_managed" {
  for_each = var.create_task_role ? toset(var.task_role_policy_arns) : toset([])

  role       = aws_iam_role.task[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "task_inline" {
  for_each = var.create_task_role ? { for policy in var.task_role_inline_policies : policy.name => policy } : {}

  role   = aws_iam_role.task[0].name
  name   = each.value.name
  policy = each.value.policy
}

resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = "${var.cluster_name}-ecs-service-sg"
  description = "Security group for ECS services"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.service_port
    to_port     = var.service_port
    protocol    = "tcp"
    cidr_blocks = var.security_group_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.resolved_tags
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_group_retention_in_days
  kms_key_id        = var.log_group_kms_key_id != "" ? var.log_group_kms_key_id : null
  tags              = local.resolved_tags
}

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = local.container_insights_value
  }

  dynamic "configuration" {
    for_each = local.execute_command_configuration_enabled ? [1] : []
    content {
      dynamic "execute_command_configuration" {
        for_each = [local.execute_command_configuration]
        content {
          kms_key_id = lookup(execute_command_configuration.value, "kms_key_id", null)
          logging    = lookup(execute_command_configuration.value, "logging", var.execute_command_logging)

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
    }
  }

  tags = local.resolved_tags
}

data "aws_ssm_parameter" "ecs_ami" {
  count = local.is_ec2_launch_type ? 1 : 0

  name = var.ecs_ami_ssm_parameter
}

resource "aws_iam_role" "ec2_instance" {
  count = local.is_ec2_launch_type ? 1 : 0

  name_prefix = "${var.cluster_name}-ecs-ec2-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.resolved_tags
}

resource "aws_iam_role_policy_attachment" "ec2_instance" {
  count = local.is_ec2_launch_type ? 1 : 0

  role       = aws_iam_role.ec2_instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2_instance" {
  count = local.is_ec2_launch_type ? 1 : 0

  name_prefix = "${var.cluster_name}-ecs-ec2-"
  role        = aws_iam_role.ec2_instance[0].name

  tags = local.resolved_tags
}

resource "aws_launch_template" "ec2" {
  count = local.is_ec2_launch_type ? 1 : 0

  name_prefix   = "${var.cluster_name}-ecs-ec2-"
  image_id      = data.aws_ssm_parameter.ecs_ami[0].value
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance[0].arn
  }

  vpc_security_group_ids = local.security_group_ids

  user_data = base64encode(<<-EOT
    #!/bin/bash
    echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
  EOT
  )

  tag_specifications {
    resource_type = "instance"
    tags          = local.resolved_tags
  }

  tags = local.resolved_tags
}

resource "aws_autoscaling_group" "ec2" {
  count = local.is_ec2_launch_type ? 1 : 0

  name_prefix         = "${var.cluster_name}-ecs-ec2-"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = var.subnets

  launch_template {
    id      = aws_launch_template.ec2[0].id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.resolved_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_ecs_capacity_provider" "ec2" {
  count = local.is_ec2_launch_type ? 1 : 0

  name = "${var.cluster_name}-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ec2[0].arn

    managed_scaling {
      status = "ENABLED"
    }
  }

  tags = local.resolved_tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count = local.is_ec2_launch_type || length(var.capacity_providers) > 0 || var.default_capacity_provider_strategy != null ? 1 : 0

  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = local.capacity_providers

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
  execution_role_arn       = lookup(each.value, "execution_role_arn", local.task_execution_role_arn)
  task_role_arn            = lookup(each.value, "task_role_arn", local.task_role_arn)

  dynamic "volume" {
    for_each = lookup(each.value, "volumes", [])
    content {
      name      = volume.value.name
      host_path = lookup(lookup(volume.value, "host", {}), "sourcePath", null)
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size_in_gib > 20 ? [var.ephemeral_storage_size_in_gib] : []
    content {
      size_in_gib = ephemeral_storage.value
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

  dynamic "capacity_provider_strategy" {
    for_each = local.is_ec2_launch_type ? [1] : []
    content {
      capacity_provider = aws_ecs_capacity_provider.ec2[0].name
      weight            = 1
    }
  }

  dynamic "network_configuration" {
    for_each = length(var.subnets) == 0 ? [] : [1]
    content {
      subnets          = var.subnets
      security_groups  = local.security_group_ids
      assign_public_ip = local.is_ec2_launch_type ? null : var.assign_public_ip
    }
  }

  tags = local.resolved_tags

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_appautoscaling_target" "this" {
  for_each = local.autoscaling_services

  max_capacity       = lookup(each.value.autoscaling, "max_capacity", lookup(each.value, "desired_count", 1))
  min_capacity       = lookup(each.value.autoscaling, "min_capacity", 1)
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_target_tracking" {
  for_each = local.autoscaling_services

  name               = "${each.key}-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = lookup(each.value.autoscaling, "target_cpu_utilization", 70)
    scale_in_cooldown  = lookup(each.value.autoscaling, "scale_in_cooldown", 300)
    scale_out_cooldown = lookup(each.value.autoscaling, "scale_out_cooldown", 60)
  }
}

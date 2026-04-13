output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "module" {
  description = "Full module outputs"
  value = {
    cluster_id                = aws_ecs_cluster.this.id
    cluster_arn               = aws_ecs_cluster.this.arn
    task_execution_role_arn   = local.task_execution_role_arn
    task_role_arn             = local.task_role_arn
    security_group_id         = var.create_security_group ? aws_security_group.this[0].id : null
    log_group_name            = var.create_log_group ? aws_cloudwatch_log_group.this[0].name : null
    task_role_resolution_note = "Task definitions can override module-level role defaults via execution_role_arn/task_role_arn per entry."
  }
}

output "task_execution_role_arn" {
  description = "Resolved task execution role ARN. Task definitions may override this with execution_role_arn per entry."
  value       = local.task_execution_role_arn
}

output "task_role_arn" {
  description = "Resolved task role ARN. Task definitions may override this with task_role_arn per entry."
  value       = local.task_role_arn
}

output "security_group_id" {
  description = "Created security group ID when create_security_group is true"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "log_group_name" {
  description = "Created CloudWatch log group name when create_log_group is true"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].name : null
}

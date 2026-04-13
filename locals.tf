locals {
  resolved_tags = merge({
    ManagedBy = "sigmoid"
  }, var.tags)

  task_execution_role_arn = var.create_task_execution_role ? aws_iam_role.task_execution[0].arn : var.task_execution_role_arn
  task_role_arn           = var.create_task_role ? aws_iam_role.task[0].arn : var.task_role_arn
  security_group_ids      = var.create_security_group ? [aws_security_group.this[0].id] : var.security_groups
}

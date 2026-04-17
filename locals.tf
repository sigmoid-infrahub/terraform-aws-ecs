locals {
  sigmoid_tags = merge(
    var.sigmoid_environment != "" ? { "sigmoid:environment" = var.sigmoid_environment } : {},
    var.sigmoid_project != "" ? { "sigmoid:project" = var.sigmoid_project } : {},
    var.sigmoid_team != "" ? { "sigmoid:team" = var.sigmoid_team } : {},
  )


  resolved_tags = merge({
    ManagedBy = "sigmoid"
  }, var.tags, local.sigmoid_tags)

  task_execution_role_arn = var.create_task_execution_role ? aws_iam_role.task_execution[0].arn : var.task_execution_role_arn
  task_role_arn           = var.create_task_role ? aws_iam_role.task[0].arn : var.task_role_arn
  security_group_ids      = var.create_security_group ? [aws_security_group.this[0].id] : var.security_groups
  autoscaling_services = {
    for entry in var.services : entry.name => entry
    if try(entry.autoscaling.enabled, false)
  }
}

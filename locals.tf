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

  container_insights_value = var.container_insights == "enhanced" ? "enhanced" : var.container_insights == "disabled" ? "disabled" : "enabled"

  managed_execute_command_configuration = {
    kms_key_id = var.execute_command_kms_key_id != "" ? var.execute_command_kms_key_id : null
    logging    = var.execute_command_logging
    log_configuration = var.execute_command_logging == "OVERRIDE" ? {
      cloud_watch_log_group_name     = var.create_log_group ? aws_cloudwatch_log_group.this[0].name : null
      cloud_watch_encryption_enabled = var.execute_command_kms_key_id != ""
      s3_bucket_name                 = null
      s3_bucket_encryption_enabled   = null
      s3_key_prefix                  = null
    } : null
  }

  execute_command_configuration_enabled = var.execute_command_configuration != null || var.execute_command_logging != "DEFAULT" || var.execute_command_kms_key_id != ""
  execute_command_configuration         = var.execute_command_configuration != null ? var.execute_command_configuration : local.managed_execute_command_configuration
}

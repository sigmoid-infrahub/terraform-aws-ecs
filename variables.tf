variable "cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "capacity_providers" {
  type        = list(string)
  description = "Capacity providers"
  default     = []
}

variable "default_capacity_provider_strategy" {
  type        = any
  description = "Default capacity provider strategy"
  default     = null
}

variable "container_insights" {
  type        = string
  description = "Container insights setting"
  default     = "enabled"
}

variable "services" {
  type        = any
  description = "Service definitions"
  default     = []
}

variable "task_definitions" {
  type        = any
  description = "Task definition specs"
  default     = []
}

variable "subnets" {
  type        = list(string)
  description = "Subnets for services"
  default     = []
}

variable "security_groups" {
  type        = list(string)
  description = "Security groups for services"
  default     = []
}

variable "create_task_execution_role" {
  type        = bool
  description = "Create ECS task execution role in this module"
  default     = false
}

variable "create_task_role" {
  type        = bool
  description = "Create ECS task role in this module"
  default     = false
}

variable "create_security_group" {
  type        = bool
  description = "Create service security group in this module"
  default     = false
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for created security group"
  default     = null
}

variable "security_group_ingress_cidr_blocks" {
  type        = list(string)
  description = "Allowed ingress CIDR blocks for created security group"
  default     = ["10.0.0.0/8"]
}

variable "service_port" {
  type        = number
  description = "Ingress service port for created security group"
  default     = 80
}

variable "create_log_group" {
  type        = bool
  description = "Create CloudWatch log group in this module"
  default     = false
}

variable "log_group_retention_in_days" {
  type        = number
  description = "Retention in days for created CloudWatch log group"
  default     = 30
}

variable "task_role_policy_arns" {
  type        = list(string)
  description = "Managed policy ARNs to attach to created task role"
  default     = []
}

variable "task_role_inline_policies" {
  type = list(object({
    name   = string
    policy = string
  }))
  description = "Inline policies to attach to created task role"
  default     = []
}

variable "task_execution_role_arn" {
  type        = string
  description = "External task execution role ARN when role is not created"
  default     = null
}

variable "task_role_arn" {
  type        = string
  description = "External task role ARN when role is not created"
  default     = null
}

variable "assign_public_ip" {
  type        = bool
  description = "Assign public IP in awsvpc mode"
  default     = false
}

variable "execute_command_configuration" {
  type        = any
  description = "Execute command configuration"
  default     = null
}

variable "service_connect_defaults" {
  type        = any
  description = "Service connect defaults"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply"
  default     = {}
}

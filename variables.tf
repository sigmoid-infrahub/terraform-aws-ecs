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

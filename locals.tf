locals {
  resolved_tags = merge({
    ManagedBy = "sigmoid"
  }, var.tags)
}

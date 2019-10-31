locals {
  name_lower = lower("${var.project}-${var.environment}${var.suffix}")
  tags = merge(
    {
      project     = var.project
      environment = var.environment
    },
    var.tags,
  )
}

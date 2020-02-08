terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.region
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  environment = "${var.environment}-${random_string.suffix.result}"
  path        = local.environment
  tags = {
    example = "true"
  }
}

module "remote_state" {
  source = "../../"

  path = local.path

  project     = var.project
  environment = local.environment

  manage_log_bucket = false
  manage_iam_role   = false
  manage_kms_keys   = false

  tags = local.tags
}

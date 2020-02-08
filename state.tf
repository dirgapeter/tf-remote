locals {
  bucket_name      = local.name_lower
  bucket_logs_name = "${local.name_lower}-logs"
}

data "aws_iam_policy_document" "full_access_kms" {
  count = var.manage_iam_role && var.manage_kms_keys ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "kms:*",
    ]

    resources = [
      "${aws_kms_key.this[0].arn}"
    ]
  }
}

data "aws_iam_policy_document" "full_access" {
  count = var.manage_iam_role ? 1 : 0

  source_json = var.manage_kms_keys ? data.aws_iam_policy_document.full_access_kms[0].json : null

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*.tfstate",
    ]
  }
}

data "aws_iam_policy_document" "read_access_kms" {
  count = var.manage_iam_role && var.manage_kms_keys ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "kms:ListKeys",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      "${aws_kms_key.this[0].arn}",
    ]
  }
}

data "aws_iam_policy_document" "read_access" {
  count = var.manage_iam_role ? 1 : 0

  source_json = var.manage_kms_keys ? data.aws_iam_policy_document.read_access_kms[0].json : null

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*.tfstate",
    ]
  }
}

################################################################################################################
## Bucket receiving logs
################################################################################################################

resource "aws_kms_key" "logs" {
  count                   = var.manage_log_bucket && var.manage_kms_keys ? 1 : 0
  description             = "Used to encrypt objects in the S3 Bucket: ${local.bucket_logs_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = templatefile("${path.module}/templates/log-bucket-kms-key-policy.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
  })

  tags = merge(local.tags, map("Name", local.bucket_logs_name))
}

resource "aws_kms_alias" "logs" {
  count         = var.manage_log_bucket && var.manage_kms_keys ? 1 : 0
  name          = "alias/${local.bucket_logs_name}"
  target_key_id = aws_kms_key.logs[0].key_id
}

resource "aws_s3_bucket" "logs" {
  count  = var.manage_log_bucket ? 1 : 0
  bucket = local.bucket_logs_name
  acl    = "log-delivery-write"

  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = var.manage_kms_keys ? "aws:kms" : "AES256"
        kms_master_key_id = var.manage_kms_keys ? aws_kms_key.logs[0].arn : null
      }
    }
  }

  tags = merge(
    local.tags,
    {
      "Name" = local.bucket_logs_name
    },
  )
}

resource "aws_s3_bucket_public_access_block" "public_access_logs" {
  count  = var.manage_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################################################
## Bucket for state
################################################################################################################

resource "aws_kms_key" "this" {
  count                   = var.manage_kms_keys ? 1 : 0
  description             = "Used to encrypt objects in the S3 Bucket: ${local.bucket_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.tags, map("Name", local.bucket_name))
}

resource "aws_kms_alias" "this" {
  count         = var.manage_kms_keys ? 1 : 0
  name          = "alias/${local.bucket_name}"
  target_key_id = aws_kms_key.this[0].key_id
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
  acl    = "private"

  // all objects should be deleted from the bucket to destroy
  force_destroy = true

  versioning {
    enabled = true
  }

  dynamic "logging" {
    for_each = var.manage_log_bucket ? [1] : []
    content {
      target_bucket = aws_s3_bucket.logs[0].id
      target_prefix = var.logging_prefix
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.manage_kms_keys ? aws_kms_key.this[0].arn : null
        sse_algorithm     = var.manage_kms_keys ? "aws:kms" : "AES256"
      }
    }
  }

  tags = merge(
    {
      "Name" = local.bucket_name
    },
    local.tags,
  )
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "full_access" {
  count       = var.manage_iam_role ? 1 : 0
  name        = "${local.bucket_name}-full-access"
  description = "Grants full access to: ${local.bucket_name}"
  policy      = data.aws_iam_policy_document.full_access[0].json
}

resource "aws_iam_policy" "read_access" {
  count       = var.manage_iam_role ? 1 : 0
  name        = "${local.bucket_name}-read-access"
  description = "Grants read access to: ${local.bucket_name}"
  policy      = data.aws_iam_policy_document.read_access[0].json
}

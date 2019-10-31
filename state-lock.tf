locals {
  table_name      = "${local.name_lower}-lock"
  isPayPerRequest = var.dynamodb_billing_mode == "PAY_PER_REQUEST"
  read_capacity   = local.isPayPerRequest ? null : 20
  write_capacity  = local.isPayPerRequest ? null : 20
  hash_key        = "LockID"
}

data "aws_iam_policy_document" "lock_access" {
  count = var.manage_iam_role ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]

    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.name}:*:table/${local.table_name}",
    ]
  }
}

resource "aws_dynamodb_table" "lock" {
  name           = local.table_name
  hash_key       = local.hash_key
  billing_mode   = var.dynamodb_billing_mode
  read_capacity  = local.read_capacity
  write_capacity = local.write_capacity

  attribute {
    name = local.hash_key
    type = "S"
  }

  tags = merge(
    {
      "Name" = local.table_name
    },
    local.tags,
  )
}

resource "aws_iam_policy" "lock_access" {
  count       = var.manage_iam_role ? 1 : 0
  name        = "${local.table_name}-access"
  description = "Grants full access to: ${local.table_name}"
  policy      = data.aws_iam_policy_document.lock_access[0].json
}

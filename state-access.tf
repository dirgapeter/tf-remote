resource "aws_iam_group" "full_access" {
  count = var.manage_iam_role ? 1 : 0
  name  = "${local.name_lower}-full-access"
}

resource "aws_iam_group" "read_access" {
  count = var.manage_iam_role ? 1 : 0
  name  = "${local.name_lower}-read-access"
}

resource "aws_iam_group_policy_attachment" "full_access" {
  count      = var.manage_iam_role ? 1 : 0
  group      = aws_iam_group.full_access[0].name
  policy_arn = aws_iam_policy.full_access[0].arn
}

resource "aws_iam_group_policy_attachment" "read_access" {
  count      = var.manage_iam_role ? 1 : 0
  group      = aws_iam_group.read_access[0].name
  policy_arn = aws_iam_policy.read_access[0].arn
}

resource "aws_iam_group_policy_attachment" "lock_full_access" {
  count      = var.manage_iam_role ? 1 : 0
  group      = aws_iam_group.full_access[0].name
  policy_arn = aws_iam_policy.lock_access[0].arn
}

resource "aws_iam_group_policy_attachment" "lock_read_access" {
  count      = var.manage_iam_role ? 1 : 0
  group      = aws_iam_group.read_access[0].name
  policy_arn = aws_iam_policy.lock_access[0].arn
}

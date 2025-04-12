variable "groups" {
  type        = map(list(string))
  description = "A map of IAM groups with their associated user lists"
  default = {
    "system_admins" = [ "system_admin_1", "system_admin_2", "system_admin_3" ]
    "database_admins" = [ "database_admin_1", "database_admin_2", "database_admin_3" ]
    "read_only" = [ "read_only_1", "read_only_2", "read_only_3" ]
  }
}

locals {
  users = distinct(flatten([for group_users in var.groups : group_users]))
}

resource "aws_iam_user" "default" {
  for_each = toset(local.users)
  name     = each.value
}

resource "aws_iam_account_password_policy" "strict_policy" {
  minimum_password_length        = 8
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  hard_expiry                    = false
  max_password_age               = 90
  password_reuse_prevention      = 3
}

resource "aws_iam_group" "default" {
  for_each = toset(keys(var.groups))
  name     = each.value
}

resource "aws_iam_group_membership" "default" {
  for_each = { for group, users in var.groups : group => users }

  name  = each.key
  users = each.value
  group = aws_iam_group.default[each.key].name
}

resource "aws_iam_group_policy_attachment" "sysadmin_full_access" {
  group      = aws_iam_group.default["system_admins"].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "dbadmin_full_access" {
  group      = aws_iam_group.default["database_admins"].name
  policy_arn = "arn:aws:iam::aws:policy/job-function/DatabaseAdministrator"
}

resource "aws_iam_group_policy_attachment" "read_only" {
  group      = aws_iam_group.default["read_only"].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonMonitronFullAccess"
}
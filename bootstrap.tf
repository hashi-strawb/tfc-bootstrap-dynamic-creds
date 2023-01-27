#
# Config for the Bootstrap workspace, in the bootstrap directory
# but now we can allow it to be auto-detected from tags too
#

moved {
  from = tfe_variable.enable_aws_provider_auth
  to   = tfe_variable.workspace_enable_aws_provider_auth["bootstrap"]
}

moved {
  from = tfe_variable.tfc_aws_role_arn
  to   = tfe_variable.workspace_tfc_aws_role_arn["bootstrap"]
}

moved {
  from = aws_iam_role.tfc_role
  to   = aws_iam_role.workspace_role["bootstrap"]
}

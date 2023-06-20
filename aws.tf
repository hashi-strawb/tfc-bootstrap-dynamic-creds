#
# AWS OIDC Provider
#

# No need to re-invent the wheel here...
# https://registry.terraform.io/modules/hashi-strawb/tfc-dynamic-creds-provider/aws/latest
module "aws-oidc-provider" {
  source = "hashi-strawb/tfc-dynamic-creds-provider/aws"
  create = var.create_aws_oidc_provider
}
/*
moved {
  from = aws_iam_openid_connect_provider.tfc_provider
  to   = module.aws-oidc-provider.aws_iam_openid_connect_provider.tfc_provider[0]
}
*/



#
# Find workspaces and set up creds
#

# Find all Workspaces with specific tags
data "tfe_workspace_ids" "tagged" {
  tag_names = var.aws_tag_names
}
output "tagged_workspace_ids" {
  value = data.tfe_workspace_ids.tagged
}

data "tfe_workspace" "tagged" {
  for_each = data.tfe_workspace_ids.tagged.ids

  name = each.key
}
output "tagged_workspaces" {
  value = data.tfe_workspace.tagged
}



// Workaround for https://github.com/hashicorp/terraform-provider-tfe/issues/778
data "environment_variables" "tfe_token" {
  filter    = "TFE_TOKEN"
  sensitive = false
}
locals {
  tfe_token = data.environment_variables.tfe_token.items["TFE_TOKEN"]
}
data "terracurl_request" "project_name_for_workspace" {
  for_each = data.tfe_workspace.tagged

  name   = "project_name_for_workspace"
  url    = "https://app.terraform.io/api/v2/projects/${each.value.project_id}"
  method = "GET"

  headers = {
    Authorization = "Bearer ${local.tfe_token}"
    Content-Type  = "application/vnd.api+json"
  }
  response_codes = [200]
}





module "workspace-creds" {
  source  = "hashi-strawb/tfc-dynamic-creds-workspace/aws"
  version = ">= 0.4.0"

  for_each = data.tfe_workspace.tagged

  oidc_provider_arn = module.aws-oidc-provider.oidc_provider.arn

  tfc_organization_name = var.tfc_organization_name
  tfc_workspace_name    = each.key
  tfc_workspace_id      = each.value.id


  # TODO: get the project name with the tfe provider
  # Relies on https://github.com/hashicorp/terraform-provider-tfe/issues/778
  tfc_workspace_project_name = jsondecode(
    data.terracurl_request.project_name_for_workspace[each.key].response
  ).data.attributes.name

  cred_type = "workspace"
}

/*
moved {
  from = aws_iam_role.workspace_role["ami-cleanup"]
  to   = module.workspace-creds["ami-cleanup"].aws_iam_role.workspace_role[0]
}
moved {
  from = aws_iam_role.workspace_role["bootstrap"]
  to   = module.workspace-creds["bootstrap"].aws_iam_role.workspace_role[0]
}

moved {
  from = tfe_variable.workspace_enable_aws_provider_auth["ami-cleanup"]
  to   = module.workspace-creds["ami-cleanup"].tfe_variable.workspace_enable_aws_provider_auth[0]
}
moved {
  from = tfe_variable.workspace_enable_aws_provider_auth["bootstrap"]
  to   = module.workspace-creds["bootstrap"].tfe_variable.workspace_enable_aws_provider_auth[0]
}

moved {
  from = tfe_variable.workspace_tfc_aws_role_arn["ami-cleanup"]
  to   = module.workspace-creds["ami-cleanup"].tfe_variable.workspace_tfc_aws_role_arn[0]
}
moved {
  from = tfe_variable.workspace_tfc_aws_role_arn["bootstrap"]
  to   = module.workspace-creds["bootstrap"].tfe_variable.workspace_tfc_aws_role_arn[0]
}
*/

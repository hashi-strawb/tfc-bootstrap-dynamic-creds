#
# OIDC Provider
#


# Data source used to grab the TLS certificate for Terraform Cloud.
#
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate
data "tls_certificate" "tfc_certificate" {
  url = "https://${var.tfc_hostname}"
}

# Creates an OIDC provider which is restricted to
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider
resource "aws_iam_openid_connect_provider" "tfc_provider" {
  url             = data.tls_certificate.tfc_certificate.url
  client_id_list  = [var.tfc_aws_audience]
  thumbprint_list = [data.tls_certificate.tfc_certificate.certificates[0].sha1_fingerprint]
}




#
# Find workspaces and set up creds
#


# Find all Workspaces with specific tags
data "tfe_workspace_ids" "tagged" {
  tag_names    = var.tag_names
  organization = var.tfc_organization_name
}


# Use a wildcard on the Project, due to https://github.com/hashicorp/terraform-provider-tfe/issues/778
resource "aws_iam_role" "workspace_role" {
  for_each = data.tfe_workspace_ids.tagged.ids

  name = "tfc-${var.tfc_organization_name}-${each.key}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "Federated": "${aws_iam_openid_connect_provider.tfc_provider.arn}"
     },
     "Action": "sts:AssumeRoleWithWebIdentity",
     "Condition": {
       "StringEquals": {
         "app.terraform.io:aud": "${one(aws_iam_openid_connect_provider.tfc_provider.client_id_list)}"
       },
       "StringLike": {
         "app.terraform.io:sub": "organization:${var.tfc_organization_name}:project:*:workspace:${each.key}:run_phase:*"
       }
     }
   }
 ]
}
EOF

  # TODO: this is waaaaay too much access; limit it to just what's needed
  # TODO: separate policies for Plan and Apply
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "tfe_variable" "workspace_enable_aws_provider_auth" {
  for_each = data.tfe_workspace_ids.tagged.ids

  workspace_id = each.value

  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for AWS."
}

resource "tfe_variable" "workspace_tfc_aws_role_arn" {
  for_each = data.tfe_workspace_ids.tagged.ids

  workspace_id = each.value

  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.workspace_role[each.key].arn
  category = "env"

  description = "The AWS role arn runs will use to authenticate."
}

#
# Bootstrap Workspace, managing itself
#

# Based on https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/blob/main/aws/aws.tf

provider "aws" {
  default_tags {
    tags = {
      Name      = "StrawbTest"
      Owner     = "lucy.davinhart@hashicorp.com"
      Purpose   = "Bootstrap Credentials for ${var.tfc_organization_name} TFC Org"
      TTL       = "24h"
      Terraform = "true"
      Source    = "https://github.com/hashi-strawb/tfc-bootstrap-dynamic-creds/tree/main/bootstrap/"
      Workspace = terraform.workspace
    }
  }

  region = "eu-west-2"
}

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

# Creates a role which can only be used by the specified Terraform
# cloud workspace.
#
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "tfc_role" {
  name = "tfc-${var.tfc_organization_name}-${var.tfc_project_name}-${var.tfc_workspace_name}"

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
         "app.terraform.io:sub": "organization:${var.tfc_organization_name}:project:${var.tfc_project_name}:workspace:${var.tfc_workspace_name}:run_phase:*"
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
}




# Based on https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/blob/main/aws/tfc-workspace.tf


provider "tfe" {
  hostname = var.tfc_hostname
}

# Runs in this workspace will be automatically authenticated
# to AWS with the permissions set in the AWS policy.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/workspace
data "tfe_workspace" "my_workspace" {
  name         = var.tfc_workspace_name
  organization = var.tfc_organization_name
}

# The following variables must be set to allow runs
# to authenticate to AWS.
#
# https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/variable
resource "tfe_variable" "enable_aws_provider_auth" {
  workspace_id = data.tfe_workspace.my_workspace.id

  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for AWS."
}

resource "tfe_variable" "tfc_aws_role_arn" {
  workspace_id = data.tfe_workspace.my_workspace.id

  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.tfc_role.arn
  category = "env"

  description = "The AWS role arn runs will use to authenticate."
}

# The following variables are optional; uncomment the ones you need!

# resource "tfe_variable" "tfc_aws_audience" {
#   workspace_id = data.tfe_workspace.my_workspace.id

#   key      = "TFC_AWS_WORKLOAD_IDENTITY_AUDIENCE"
#   value    = var.tfc_aws_audience
#   category = "env"

#   description = "The value to use as the audience claim in run identity tokens"
# }

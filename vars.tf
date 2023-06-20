# Based on https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples/blob/main/aws/vars.tf

#
# Bootstrapper
#

variable "create_aws_oidc_provider" {
  type = bool
  default = true
  description = "Whether to create an OIDC provider in Terraform, or use an existing one"
}

variable "tfc_aws_audience" {
  type        = string
  default     = "aws.workload.identity"
  description = "The audience value to use in run identity tokens"
}

variable "tfc_hostname" {
  type        = string
  default     = "app.terraform.io"
  description = "The hostname of the TFC or TFE instance you'd like to use with AWS"
}

variable "tfc_organization_name" {
  type        = string
  default     = "hashi_strawb_testing"
  description = "The name of your Terraform Cloud organization"
}

variable "tfc_workspace_name" {
  type        = string
  default     = "bootstrap"
  description = "The name of the workspace that you'd like to use as the bootstrap workspace"
}



#
# Workspace Finder
#

variable "aws_tag_names" {
  default = [
    "creds:dynamic-aws",
    "aws-account:sandbox",
  ]
}

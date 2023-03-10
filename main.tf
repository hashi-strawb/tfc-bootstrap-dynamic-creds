terraform {
  cloud {
    organization = "hashi_strawb_testing"

    workspaces {
      name = "bootstrap"
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
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

provider "tfe" {
  hostname = var.tfc_hostname
}

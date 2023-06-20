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
    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.42.0"
    }
    environment = {
      source  = "EppO/environment"
      version = "1.3.4"
    }
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "1.1.0"
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
  hostname     = var.tfc_hostname
  organization = var.tfc_organization_name
}

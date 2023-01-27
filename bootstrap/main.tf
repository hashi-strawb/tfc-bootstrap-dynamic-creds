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

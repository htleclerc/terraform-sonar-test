# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_version = "> 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
  /*
  cloud {
    organization = "leclerc"
    workspaces {
      name = "test-terraform-sonar"
    }
  }
  */
}

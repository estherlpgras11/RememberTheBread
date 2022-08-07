terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.25.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.keypair_name
  public_key = file("./${var.keypair_name}.pub")
}

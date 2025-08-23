provider "aws" {
  region  = "eu-west-1"
  profile = var.aws_profile
}



terraform {
  required_version = "1.12.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.55.0"
    }
  }
  
  backend "s3" {
    bucket = "s3://deploy-artifacts-aytom/terraform"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
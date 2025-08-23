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
    bucket = "deploy-artifacts-aytom"
    key    = "terraform/terraform.tfstate"
    region = "eu-west-1"
  }
}
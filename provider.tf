terraform {
  required_providers {
   aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    } 
  }
  backend "s3" {
    bucket = "estado-terraform.tfstate " 
    key    = "infraestructura/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::398512629733:role/Terraform-Jenkins" 
  }
}
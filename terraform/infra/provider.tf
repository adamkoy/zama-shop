terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

terraform {
  backend "s3" {
    bucket         = "tfstate-zama-shop-paris"
    key            = "envs/dev/infra.tfstate"  
    region         = "eu-west-3"                   
    dynamodb_table = "zama-shop"
    encrypt        = true
  }
}
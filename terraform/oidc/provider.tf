provider "aws" {
  region  = "eu-west-3"
}

terraform {
  backend "s3" {
    bucket         = "tfstate-zama-shop-paris"
    key            = "envs/dev/oidc.tfstate"  
    region         = "eu-west-3"                   
    dynamodb_table = "zama-shop"
    encrypt        = true
  }
}
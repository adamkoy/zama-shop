resource "aws_ecr_repository" "zama_shop" {
  name                 = "zama-shop"
  image_tag_mutability = "MUTABLE" 
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Project = "zama-shop"
    Managed = "terraform"
  }
}
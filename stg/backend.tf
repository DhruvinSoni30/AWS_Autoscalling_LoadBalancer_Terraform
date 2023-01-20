terraform {
  backend "s3" {
    bucket  = "dhsoni-terraform"
    key     = "stg/terraform.tfstate"
    region  = "us-east-2"
    profile = "default"
  }
}
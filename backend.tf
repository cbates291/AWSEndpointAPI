terraform {
  backend "s3" {
    bucket = "manta-terraform-states"
    key    = "endpointAPI/terraform.tfstate"
    region = "us-east-1"
  }
}

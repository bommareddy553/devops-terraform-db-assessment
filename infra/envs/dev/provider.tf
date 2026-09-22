provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-assessment"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

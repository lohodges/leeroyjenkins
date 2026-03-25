provider "aws" {
  region = var.aws_region
}

# added by Lonnie Hodges on 2026-01-25
provider "aws" {
  alias  = "acm_useast1"
  region = var.aws_region_acm
}
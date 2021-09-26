

# Backend cannot do variable interpolation
terraform {
  backend "s3" {
    bucket = "sdlc-terraform-lock"
    key = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "sdlc-terraform-lock"
  }
}

data aws_caller_identity current {}

output account_id {
  value = data.aws_caller_identity.current.account_id
}

#######################################
# Provider declarations

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.env
      Service = "infrastructure"
    }
  }
}

#######################################
# KMS Keys

resource "aws_kms_key" "secrets" {
  description             = "Code secrets variables"
}

# Sysadmins trusted IPs
variable "whitelist_sg" {
  default = [
    "70.251.185.38/32"
  ]
}

module "whitelist_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0.0"

  name        = "${var.env}-whitelist-sg"
  description = "whitelist ips for developers"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "whitelist access"
      cidr_blocks = join(",", var.whitelist_sg)
    }
  ]
}

module service_build {
  source = "./modules/service_build"
  for_each = merge(var.ec2_services, var.artifact_services)

  config = merge({
    name = each.key
    type = each.value.type
  })

  service_artifacts_bucket = aws_s3_bucket.service_artifacts.bucket
}

resource aws_s3_bucket service_artifacts {
  bucket = "${var.route53_root_host_zone}-${var.app_name}-artifacts"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

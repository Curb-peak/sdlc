#######################################
# VPC declaration


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "${var.env}-vpc"
  cidr = var.vpc["cidr"]

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = [var.vpc["cidr_block_a"], var.vpc["cidr_block_b"], var.vpc["cidr_block_c"]]
  public_subnets  = [var.vpc["public_block_a"], var.vpc["public_block_b"], var.vpc["public_block_c"]]

  #intra_subnets

  enable_nat_gateway = false
  enable_vpn_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}




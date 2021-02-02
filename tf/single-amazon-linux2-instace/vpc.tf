module "vpc" {
    source  = "cloudposse/vpc/aws"
    version = "0.19.0"
    name = "fc-${var.env}"
    cidr_block = "10.0.0.0/16"
    #region = var.region

  }

  module "subnets" {
    source               = "cloudposse/dynamic-subnets/aws"
    version              = "0.36.0"
    availability_zones   = var.availability_zones
    name                 = "fc-${var.env}"
    vpc_id               = module.vpc.vpc_id
    igw_id               = module.vpc.igw_id
    cidr_block           = module.vpc.vpc_cidr_block
    nat_gateway_enabled  = false
    nat_instance_enabled = false

  }


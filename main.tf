provider "aws" {
  region = var.region
}

locals {
    name = "Test"
    tags = {
        Managedby   = "Terraform"
    }
  }

module "vpc" {
  source            = "./modules/vpc"
  name              = local.name
  vpc_cidr          = "10.0.0.0/16"
  public_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets   = ["10.0.10.0/24", "10.0.20.0/24"]
  tags              = local.tags
}

module "s3" {
  source          = "./modules/s3"
  s3_bucket_name  = "test-bucket-heitor-perozini"
}

module "ec2_bastion" {
  source               = "./modules/ec2_bastion"
  name              = local.name
  ec2_instance_type    = "t2.micro"
  vpc_id               = module.vpc.vpc_id
  public_subnets       = module.vpc.public_subnet_ids
  tags                 = local.tags
}

module "ec2_web" {
  source               = "./modules/ec2_web"
  name              = local.name
  ec2_instance_type    = "t2.micro"
  vpc_id               = module.vpc.vpc_id
  public_subnets       = module.vpc.public_subnet_ids
  private_subnets      = module.vpc.private_subnet_ids
  bastion_sg           = module.ec2_bastion.bastion_sg
  bucket_arn           = module.s3.bucket_arn
  key_pair             = module.ec2_bastion.keypair
  tags                 = local.tags

}


# configure aws provider
provider "aws" {
  region  = var.region
  profile = "default"
}

# create VPC
module "vpc" {

  source                       = "../modules/vpc"
  region                       = var.region
  project_name                 = var.project_name
  vpc_cidr                     = var.vpc_cidr
  public_subnet_az1_cidr       = var.public_subnet_az1_cidr
  public_subnet_az2_cidr       = var.public_subnet_az2_cidr

}


# create Security Group
module "security_group" {

  source = "../modules/security-groups"
  vpc_id = module.vpc.vpc_id

}

# create ALB
module "alb" {

  source = "../modules/alb"
  project_name = module.vpc.project_name
  alb_security_group = module.security_group.alb_security_group_id
  public_subnet_az1_id = module.vpc.public_subnet_az1_id
  public_subnet_az2_id = module.vpc.public_subnet_az2_id
  vpc_id = module.vpc.vpc_id
  
}

# create key pair
module "key_pair" {

    source = "../modules/key_pair"
}

module "auto_scaling" {

  source = "../modules/auto-scalling"
  project_name = module.vpc.project_name
  public_subnet_az1_id = module.vpc.public_subnet_az1_id
  public_subnet_az2_id = module.vpc.public_subnet_az2_id
  public_ec2_security_group = module.security_group.public_ec2_security_group_id
  key_name = module.key_pair.key_id
  min_size = var.min_size
  max_size = var.max_size
  instance_type = var.instance_type
  target_group_arn = module.alb.target_group_arn

}




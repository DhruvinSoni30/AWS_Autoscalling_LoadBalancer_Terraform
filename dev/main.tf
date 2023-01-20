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
  private_app_subnet_az1_cidr  = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr  = var.private_app_subnet_az2_cidr

}

# create NAT Gateway
module "nat_gateway" {

  source                     = "../modules/nat-gateway"
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  internet_gateway           = module.vpc.internet_gateway
  public_subnet_az2_id       = module.vpc.public_subnet_az2_id
  vpc_id                     = module.vpc.vpc_id
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id

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
  alb_security_group_id = module.security_group.alb_security_group_id
  public_subnet_az1_id = module.vpc.public_subnet_az1_id
  public_subnet_az2_id = module.vpc.public_subnet_az2_id
  vpc_id = module.vpc.vpc_id
  demo_instance_1 = module.ec2_instance.instance_id_1
  demo_instance_2 = module.ec2_instance.instance_id_2
  
}

# create key pair
module "key_pair" {

    source = "../modules/key_pair"
  
}
# create EC2 instance
module "ec2_instance" {

  source = "../modules/ec2"
  ami_id = var.ami_id
  instance_type = var.instance_type
  public_ec2_security_group = module.security_group.public_ec2_security_group_id
  private_ec2_security_group = module.security_group.private_ec2_security_group_id
  bastion_host_security_group = module.security_group.bastion_host_security_group_id
  public_subnet_az1 = module.vpc.public_subnet_az1_id
  public_subnet_az2 = module.vpc.public_subnet_az2_id
  private_app_subnet_az1 = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2 = module.vpc.private_app_subnet_az2_id
  project_name = module.vpc.project_name
  alb_id = module.alb.alb_id
  key_id = module.key_pair.key_id

}






module "vpc" {
  source = "./modules/vpc"
}

module "alb" {
  source             = "./modules/alb"
  vpc_resource       = module.vpc.vpc_resource
  vpc_security_group = module.vpc.security_group
  public_subnet_ids  = module.vpc.public_subnet_ids

  depends_on = [module.vpc]
}

module "route53" {
  source = "./modules/route53"
  alb    = module.alb.alb

  depends_on = [module.alb]
}

module "iam" {
  source = "./modules/iam"

  depends_on = [module.route53]
}

module "ec2" {
  source                   = "./modules/ec2"
  key_pair                 = module.vpc.key_pair
  ami                      = module.vpc.ami
  vpc_resource             = module.vpc.vpc_resource
  vpc_security_group       = module.vpc.security_group
  public_subnet_ids        = module.vpc.public_subnet_ids
  private_subnet_ids       = module.vpc.private_subnet_ids
  availability_zones       = module.vpc.availability_zones
  postgres_user            = var.postgres_user
  postgres_password        = var.postgres_password
  s3_backend_bucket        = var.s3_backend_bucket
  aws_access_key_id        = var.aws_access_key_id
  aws_secret_access_key    = var.aws_secret_access_key
  aws_default_region       = var.aws_default_region
  ec2_ssm_instance_profile = module.iam.ec2_ssm_instance_profile

  depends_on = [module.iam]
}

module "asg" {
  source                   = "./modules/asg"
  key_pair                 = module.vpc.key_pair
  ami                      = module.vpc.ami
  vpc_security_group       = module.vpc.security_group
  private_subnet_ids       = module.vpc.private_subnet_ids
  alb_target_group         = module.alb.alb_target_group
  s3_backend_bucket        = var.s3_backend_bucket
  s3_frontend_bucket       = var.s3_frontend_bucket
  aws_access_key_id        = var.aws_access_key_id
  aws_secret_access_key    = var.aws_secret_access_key
  aws_default_region       = var.aws_default_region
  ec2_ssm_instance_profile = module.iam.ec2_ssm_instance_profile

  depends_on = [module.ec2]
}
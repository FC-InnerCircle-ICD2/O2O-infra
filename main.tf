module "vpc" {
  source = "./modules/vpc"
}

module "alb" {
  source = "./modules/alb"
  vpc_resource = module.vpc.vpc_resource
  vpc_security_group = module.vpc.vpc_security_group
  vpc_public_1_subnet = module.vpc.vpc_public_1_subnet
  vpc_public_2_subnet = module.vpc.vpc_public_2_subnet

  depends_on = [module.vpc.vpc_resource]
}
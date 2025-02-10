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

# module "asg" {
#   source = "./modules/asg"
#   aws_key_pair = module.vpc.aws_key_pair
#   aws_ami = module.vpc.aws_ami
#   vpc_security_group = module.vpc.vpc_security_group
#   nat_1_gateway = module.vpc.nat_1_gateway
#   nat_2_gateway = module.vpc.nat_2_gateway
#   vpc_private_1_subnet = module.vpc.vpc_private_1_subnet
#   vpc_private_2_subnet = module.vpc.vpc_private_2_subnet
#   aws_lb_target_group = module.alb.aws_lb_target_group

#   depends_on = [module.vpc.vpc_security_group, module.vpc.nat_1_gateway, module.vpc.nat_2_gateway]
# }

# module "rds" {
#   source = "./modules/rds"
#   vpc_resource = module.vpc.vpc_resource
#   vpc_private_1_subnet = module.vpc.vpc_private_1_subnet
#   vpc_private_2_subnet = module.vpc.vpc_private_2_subnet
# }
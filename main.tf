module "vpc" {
  source = "./modules/vpc"
}

module "alb" {
  source = "./modules/alb"
  vpc_resource = module.vpc.vpc_resource
  vpc_security_group = module.vpc.security_group
  public_subnet_ids = module.vpc.public_subnet_ids

  depends_on = [ module.vpc.vpc_resource ]
}

module "ec2" {
  source = "./modules/ec2"
  key_pair = module.vpc.key_pair
  ami = module.vpc.ami
  vpc_security_group = module.vpc.security_group
  public_subnet_ids = module.vpc.public_subnet_ids

  depends_on = [ module.vpc.vpc_resource ]
}

# module "asg" {
#   source = "./modules/asg"
#   aws_key_pair = module.vpc.key_pair
#   aws_ami = module.vpc.ami
#   vpc_security_group = module.vpc.security_group
#   private_subnet_ids = module.vpc.private_subnet_ids

#   depends_on = [ module.vpc.security_group, module.vpc.nat_gateway[0], module.vpc.nat_gateway[0] ]
# }
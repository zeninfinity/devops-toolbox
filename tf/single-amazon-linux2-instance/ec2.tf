module "instance" {
  source = "cloudposse/ec2-instance/aws"
  ssh_key_pair                = var.ssh_key_name
  instance_type               = var.instance_size
  vpc_id                      = module.vpc.vpc_id
  ami                         = var.ami
  ami_owner                   = var.ami_owner
  subnet                      = module.subnets.public_subnet_ids[0]
  name                        = var.instance_name
  namespace                   = var.env
  allowed_ports               = [22]
  associate_public_ip_address = true
}

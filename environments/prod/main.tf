data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "ubuntu_ami" {
  count = var.ami_id == null ? 1 : 0
  name  = "/aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

module "network" {
  source            = "../../modules/network"
  project_name      = var.project_name
  availability_zone = var.availability_zone != null ? var.availability_zone : data.aws_availability_zones.available.names[0]
}

module "ec2" {
  source           = "../../modules/ec2"
  project_name     = var.project_name
  vpc_id           = module.network.vpc_id
  subnet_id        = module.network.subnet_id
  ami_id           = var.ami_id != null ? var.ami_id : nonsensitive(data.aws_ssm_parameter.ubuntu_ami[0].value)
  instance_type    = var.instance_type
  root_volume_size = var.root_volume_size
  ssh_allowed_cidr = var.ssh_allowed_cidr
  ssh_public_key   = trimspace(file(pathexpand(var.ssh_public_key_path)))
  depends_on       = [module.network]
}

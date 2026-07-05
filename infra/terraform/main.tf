data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "network" {
  source = "./modules/network"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "security_group" {
  source = "./modules/security_group"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  allowed_ssh_cidr      = var.allowed_ssh_cidr
  node_internal_cidrs   = [var.vpc_cidr]
  allow_public_http_tls = true
}

module "compute" {
  source = "./modules/compute"

  project_name        = var.project_name
  environment         = var.environment
  ami_id              = data.aws_ami.ubuntu.id
  instance_type       = var.instance_type
  key_name            = var.key_name
  public_subnet_ids   = module.network.public_subnet_ids
  security_group_ids  = [module.security_group.node_security_group_id]
  worker_count        = var.worker_count
  root_volume_size_gb = var.root_volume_size_gb
}

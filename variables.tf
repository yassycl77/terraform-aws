variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "project_name" {
  type    = string
  default = "ubuntu-ec2"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.project_name))
    error_message = "Utilisez 3 a 31 caracteres : lettres minuscules, chiffres et tirets."
  }
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
  validation {
    condition     = can(regex("^t3\\.", var.instance_type))
    error_message = "Ce projet utilise une AMI amd64 : choisissez un type t3 (par exemple t3.micro)."
  }
}

variable "ssh_allowed_cidr" {
  description = "Votre adresse IPv4 publique suivie de /32."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.ssh_allowed_cidr)) && can(regex("/32$", var.ssh_allowed_cidr))
    error_message = "Renseignez une seule adresse IPv4 au format x.x.x.x/32."
  }
}

variable "ssh_public_key_path" {
  description = "Chemin local vers votre cle SSH publique uniquement."
  type        = string
  default     = "~/.ssh/terraform-ec2.pub"
}

variable "root_volume_size" {
  type    = number
  default = 20
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384 && floor(var.root_volume_size) == var.root_volume_size
    error_message = "Le disque doit mesurer entre 8 et 16384 Gio, en nombre entier."
  }
}

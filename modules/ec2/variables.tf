variable "instance_type" {
  type    = string
  default = "t3.micro"
  validation {
    condition     = contains(["t3.nano", "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge", "t3.2xlarge"], var.instance_type)
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

variable "root_volume_size" {
  type    = number
  default = 20
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384 && floor(var.root_volume_size) == var.root_volume_size
    error_message = "Le disque doit mesurer entre 8 et 16384 Gio, en nombre entier."
  }
}
variable "project_name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "subnet_id" {
  type = string
}
variable "ami_id" {
  type = string
}
variable "ssh_public_key" {
  description = "Contenu de la cle publique, jamais de cle privee."
  type        = string
  validation {
    condition     = can(regex("^ssh-(ed25519|rsa) ", trimspace(var.ssh_public_key)))
    error_message = "Fournissez une cle publique OpenSSH ed25519 ou RSA."
  }
}

mock_provider "aws" {}

variables {
  project_name     = "test-ec2"
  vpc_id           = "vpc-12345678"
  subnet_id        = "subnet-12345678"
  ami_id           = "ami-0123456789abcdef0"
  ssh_allowed_cidr = "203.0.113.10/32"
  ssh_public_key   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMTLBWcXQJyr5kkZgKPKT5nMNCbrh+7upGigWNJ0MFEv test"
}

run "security_baseline" {
  command = plan
  assert {
    condition     = aws_instance.main.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 doit rester obligatoire."
  }
  assert {
    condition     = aws_instance.main.root_block_device[0].encrypted
    error_message = "Le disque racine doit rester chiffre."
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.ssh.cidr_ipv4 == "203.0.113.10/32" && aws_vpc_security_group_ingress_rule.ssh.from_port == 22 && aws_vpc_security_group_ingress_rule.ssh.to_port == 22
    error_message = "SSH doit rester limite au CIDR configure et au port 22."
  }
}

run "reject_open_ssh" {
  command = plan
  variables {
    ssh_allowed_cidr = "0.0.0.0/0"
  }
  expect_failures = [var.ssh_allowed_cidr]
}

run "reject_incompatible_architecture" {
  command = plan
  variables {
    instance_type = "t4g.micro"
  }
  expect_failures = [var.instance_type]
}

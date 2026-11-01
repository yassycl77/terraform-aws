moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.main
}

moved {
  from = aws_subnet.public
  to   = module.network.aws_subnet.public
}

moved {
  from = aws_internet_gateway.main
  to   = module.network.aws_internet_gateway.main
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route_table_association.public
  to   = module.network.aws_route_table_association.public
}

moved {
  from = aws_security_group.ssh
  to   = module.ec2.aws_security_group.ssh
}

moved {
  from = aws_vpc_security_group_ingress_rule.ssh
  to   = module.ec2.aws_vpc_security_group_ingress_rule.ssh
}

moved {
  from = aws_vpc_security_group_egress_rule.all
  to   = module.ec2.aws_vpc_security_group_egress_rule.all
}

moved {
  from = aws_key_pair.ssh
  to   = module.ec2.aws_key_pair.ssh
}

moved {
  from = aws_instance.main
  to   = module.ec2.aws_instance.main
}

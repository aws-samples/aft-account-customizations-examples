data "aws_region" "current" {}
locals {
  region       = data.aws_region.current.name
  cidr         = data.aws_ssm_parameter.cidr.value
  cidr_subnets = nonsensitive(cidrsubnets(local.cidr, 4, 4, 4, 4, 4, 4))
  azs          = ["${local.region}a", "${local.region}b", "${local.region}c"]
}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "cidr" {
  name = "/${data.aws_caller_identity.current.account_id}/vpc/cidr"
}

data "aws_ssm_parameter" "project" {
  name = "/aft/account-request/custom-fields/project"
}

resource "aws_vpc" "vpc" {
  #checkov:skip=CKV2_AWS_11: No need Dev environment.
  #checkov:skip=CKV2_AWS_12: Already done.
  cidr_block = local.cidr
  tags = {
    Name = "${data.aws_ssm_parameter.project.value}-DEV"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${data.aws_ssm_parameter.project.value}-DEV-public-subnet"
  }
}

resource "aws_eip" "eip" {
  #checkov:skip=CKV2_AWS_19: EIP attached to Nat Gateway.
  domain           = "vpc"
}


resource "aws_subnet" "public" {
  count = "${length(local.azs)}"
 
  vpc_id            = aws_vpc.vpc.id
  availability_zone = local.azs[count.index]
 
  cidr_block = local.cidr_subnets[count.index+3]
 
  tags = {
    Name        = "${data.aws_ssm_parameter.project.value}-DEV-public-subnet"
  }
    depends_on = [ aws_internet_gateway.gw ]

}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${data.aws_ssm_parameter.project.value}-DEV-gw-NAT"
  }

  depends_on = [ aws_internet_gateway.gw ]
}

resource "aws_subnet" "private" {
  count = "${length(local.azs)}"
  vpc_id            = aws_vpc.vpc.id
  availability_zone = local.azs[count.index]
 
  cidr_block = local.cidr_subnets[count.index]

  tags = {
    Name        = "${data.aws_ssm_parameter.project.value}-DEV-private-subnet"
  }

  depends_on = [ aws_nat_gateway.ngw ]
}

resource "aws_route_table" "main-public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name        = "${data.aws_ssm_parameter.project.value}-DEV-public-route"
  }

  depends_on = [ aws_internet_gateway.gw ]

}

resource "aws_route_table" "main-private" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name        = "${data.aws_ssm_parameter.project.value}-DEV-private-route"
  }
  depends_on = [ aws_nat_gateway.ngw ]

}

resource "aws_route_table_association" "public" {
  count = "${length(local.azs)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = aws_route_table.main-public.id
}

resource "aws_route_table_association" "private" {
  count = "${length(local.azs)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = aws_route_table.main-private.id
}
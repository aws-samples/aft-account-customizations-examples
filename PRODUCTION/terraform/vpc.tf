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

resource "aws_vpc" "vpc" {
  #checkov:skip=CKV2_AWS_12: Already done.
  cidr_block = local.cidr
  tags = {
    Name = "${data.aws_ssm_parameter.project.value}-PROD"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${data.aws_ssm_parameter.project.value}-PROD-public-subnet"
  }
}

resource "aws_eip" "eip" {
  #checkov:skip=CKV2_AWS_19: EIP attached to Nat Gateway.
  count = "${length(local.azs)}"
  domain           = "vpc"
}


resource "aws_subnet" "public" {
  count = "${length(local.azs)}"
 
  vpc_id            = aws_vpc.vpc.id
  availability_zone = local.azs[count.index]
 
  cidr_block = local.cidr_subnets[count.index+3]
 
  tags = {
    Name        = "${data.aws_ssm_parameter.project.value}-PROD-public-subnet"
  }
    depends_on = [ aws_internet_gateway.gw ]

}

resource "aws_nat_gateway" "ngw" {
  count = "${length(local.azs)}"
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${data.aws_ssm_parameter.project.value}-PROD-gw-NAT-${local.azs[count.index]}"
  }

  depends_on = [ aws_internet_gateway.gw ]
}

resource "aws_subnet" "private" {
  count = "${length(local.azs)}"
  vpc_id            = aws_vpc.vpc.id
  availability_zone = local.azs[count.index]
 
  cidr_block = local.cidr_subnets[count.index]

  tags = {
    Name        = "${data.aws_ssm_parameter.project.value}-PROD-private-subnet"
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
    Name        = "${data.aws_ssm_parameter.project.value}-PROD-public-route"
  }

  depends_on = [ aws_internet_gateway.gw ]

}

resource "aws_route_table" "main-private" {
  count = "${length(local.azs)}"
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw[count.index].id
  }
  tags = {
    Name        = "${data.aws_ssm_parameter.project.value}-PROD-private-route-${local.azs[count.index]}"
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
  route_table_id = aws_route_table.main-private[count.index].id
}
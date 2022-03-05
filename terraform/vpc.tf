# VPC, Subnets, and associated resources


resource "aws_vpc" "tf_vpc" {
    cidr_block = "10.1.0.0/16"
    instance_tenancy = "default"

    tags = {
      Name = "${var.project_name}vpc"
      Purpose = var.purpose_tag
    }
}

resource "aws_internet_gateway" "tf_gate" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "${var.project_name}i-gateway"
    Purpose = var.purpose_tag
  }
}

resource "aws_route_table" "tf_route" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # all traffic for the vpc. the NLB will reference this vpc so is fine
    gateway_id = aws_internet_gateway.tf_gate.id
  }
  # local routing created by default
  # not using ipv6 so can skip that routing

  tags = {
    Name = "${var.project_name}route"
    Purpose = var.purpose_tag
  }
}

# Create subnets and associate with route table
# subnet A is the EC2 resources fun
resource "aws_subnet" "subnetA" {
    vpc_id = aws_vpc.tf_vpc.id
    cidr_block = "10.1.0.0/24"
    availability_zone = "us-west-2a"

    tags = {
        Name = "${var.project_name}subnetA"
        Purpose = var.purpose_tag
    }
}

# route table association
resource "aws_route_table_association" "rtass_a" {
  subnet_id = aws_subnet.subnetA.id
  route_table_id = aws_route_table.tf_route.id
}

# subnet B
resource "aws_subnet" "subnetB" {
    vpc_id = aws_vpc.tf_vpc.id
    cidr_block = "10.1.1.0/24"
    availability_zone = "us-west-2b"

    tags = {
        Name = "${var.project_name}subnetB"
        Purpose = var.purpose_tag
    }
}

# route table association
resource "aws_route_table_association" "rtass_b" {
  subnet_id = aws_subnet.subnetB.id
  route_table_id = aws_route_table.tf_route.id
}

# NLB
resource "aws_lb" "sdm_nlb" {
  name               = "sdm-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [ aws_subnet.subnetA.id, aws_subnet.subnetB.id ]

  tags = {
    Name = "${var.project_name}NLB"
    Purpose = var.purpose_tag
  }
}

resource "aws_lb_target_group" "sdm_nlb" {
  name = "sdm-gate-target"
  port = 5000
  protocol = "TCP"
  vpc_id = aws_vpc.tf_vpc.id
}

resource "aws_lb_target_group_attachment" "sdm_gateA" {
  target_group_arn = aws_lb_target_group.sdm_nlb.arn
  target_id = aws_instance.sdm_gateway.id
  port = 5000
}

# configuring listeners manually with cert in UI

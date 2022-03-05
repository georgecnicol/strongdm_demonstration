# Security Groups

# SDM BASE FLAG ... an AWS best practice to allow communication between resources by security group identity rather than ip
resource "aws_security_group" "sdm_base_flag" {
  name = "${var.project_name}base-flag"
  description = "attach this to incoming taffic rule as a source to allow traffic from this asset"
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "${var.project_name}base-flag"
    Purpose = var.purpose_tag
  }
}

# fargateapp with this security group will receive communication from the SDM gateway
resource "aws_security_group" "fargate_allow_sdm" {
  name = "fargate ap allow sdm gate"
  description = "attach to fargate app"
  vpc_id = aws_vpc.tf_vpc.id
  ingress {
    description = "allow from sdm"
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    security_groups = [ aws_security_group.sdm_base_flag.id ]
  }

  tags = {
    Name = "${var.project_name}allow-5000-sdm"
    Purpose = var.purpose_tag
  }
}

# compute with this security group will receive communication from the SDM gateway
resource "aws_security_group" "compute_resource_allow_sdm" {
  name = "compute ap allow sdm gate"
  description = "attach to fargate app"
  vpc_id = aws_vpc.tf_vpc.id
  ingress {
    description = "allow from sdm"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [ aws_security_group.sdm_base_flag.id ]
  }

  tags = {
    Name = "${var.project_name}allow-22-sdm"
    Purpose = var.purpose_tag
  }
}



# Allow nlb to sdm gateway on 5000
resource "aws_security_group" "all_5000" {
  name = "sdm 5000"
  description = "attach to sdm gateway asset"
  vpc_id = aws_vpc.tf_vpc.id
  ingress {
    description = "allow 5000"
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}incoming-to-sdm-gate"
    Purpose = var.purpose_tag
  }
}

# Allow all port 22 communication
# maybe unnecessary
resource "aws_security_group" "all_22" {
  name = "sdm: allow ssh"
  description = "attach to sdm gate to allow ssh"
  vpc_id = aws_vpc.tf_vpc.id
  ingress{
    description = "allow 22"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
      Name = "${var.project_name}allow-22-all"
      Purpose = var.purpose_tag
  }
}

# permissive outbound
resource "aws_security_group" "generic_outbound" {
  name = "sdm: allow all outbound"
  description = "allow all outboun"
  vpc_id = aws_vpc.tf_vpc.id
  egress {
    protocol          = "-1"
    from_port         = 0
    to_port           = 0
    cidr_blocks       = ["0.0.0.0/0"]
  }
}

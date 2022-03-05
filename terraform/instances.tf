
# 1st: sdm Gateway
# 2nd: ec2 compute resource
# both AWS linux 2 in us-west-2 : ami-0ca05c6eaa4ac40e0

locals {
    sdm_api = "${jsondecode(data.aws_secretsmanager_secret_version.sdm_token_secret.secret_string)["gnicol-cool-scarf-9008"]}"
}

# EC2 compute resource reachable only via sdm gateway
resource "aws_instance" "sdm_compute_resource" {
  ami =  "ami-0ca05c6eaa4ac40e0"
  instance_type = "t3.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnetA.id
  key_name = data.aws_key_pair.ssh_key.key_name
  security_groups = [
                        aws_security_group.generic_outbound.id,
                        aws_security_group.compute_resource_allow_sdm.id
                    ]

  tags = {
    Name = "sdm_demo compute resource"
    Purpose = var.purpose_tag
  }
  user_data = <<EOF
#!bin/bash
user_profile="PS1='\[\033[36m\]\u\[\033[m\]@\[\033[34m\]\h \[\033[36;1m\]\W\[\033[m\] \[\033[33m\]\$\[\033[m\] '
export CLICOLOR=1
export LSCOLORS=dxFxBxDxCxegedabagacad"
root_profile="PS1='\[\033[31;3m\]\u\[\033[m\]@\[\033[34m\]\h \[\033[36;1m\]\W\[\033[m\] \[\033[33m\]\$\[\033[m\] '
export CLICOLOR=1
export LSCOLORS=dxFxBxDxCxegedabagacad"
echo "$user_profile" >> /home/ec2-user/.bash_profile
echo "$root_profile" >> /root/.bash_profile
hostnamectl set-hostname compute_resource
yum update -y

EOF
}

# SDM docs say medium
resource "aws_instance" "sdm_gateway" {
  ami =  "ami-0ca05c6eaa4ac40e0"
  instance_type = "t3.medium"
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnetA.id
  key_name = data.aws_key_pair.ssh_key.key_name
  security_groups = [
                        aws_security_group.generic_outbound.id,
                        aws_security_group.all_5000.id,
                        aws_security_group.all_22.id,
                        aws_security_group.sdm_base_flag.id
                    ]

  tags = {
    Name = "sdm_demo gateway"
    Purpose = var.purpose_tag
  }
  user_data = <<EOF
#!bin/bash
yum update -y
user_profile="PS1='\[\033[36m\]\u\[\033[m\]@\[\033[34m\]\h \[\033[36;1m\]\W\[\033[m\] \[\033[33m\]\$\[\033[m\] '
export CLICOLOR=1
export LSCOLORS=dxFxBxDxCxegedabagacad"
root_profile="PS1='\[\033[31;3m\]\u\[\033[m\]@\[\033[34m\]\h \[\033[36;1m\]\W\[\033[m\] \[\033[33m\]\$\[\033[m\] '
export CLICOLOR=1
export LSCOLORS=dxFxBxDxCxegedabagacad"
echo "$user_profile" >> /home/ec2-user/.bash_profile
echo "$root_profile" >> /root/.bash_profile
hostnamectl set-hostname sdm_gateway
setup_log="/root/setup.log"
curl -L "https://app.strongdm.com/releases/cli/linux" -o "/root/sdm_app.zip" &>> $setup_log
/bin/unzip /root/sdm_app.zip -d /root &>> $setup_log
/root/sdm install --user ec2-user --relay --token="${local.sdm_api}"  &>> $setup_log

EOF
}

# stdout the ip addressess
output "compute_resource_instance_ip_addresses" {
    value = [ aws_instance.sdm_compute_resource.public_ip, aws_instance.sdm_compute_resource.private_ip ]
}

output "sdm_gateway_ip_addresses" {
    value = [ aws_instance.sdm_gateway.public_ip, aws_instance.sdm_gateway.private_ip ]
}

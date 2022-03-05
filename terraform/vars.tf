# variable and data declarations

data "aws_caller_identity" "current" { }
data "aws_region" "current" {}
data "aws_ecr_repository" "ecr_sdm_demo" {
  name = "sdm_demo"
}

# SDM tokens
data "aws_secretsmanager_secret" "sdm_secret" {
  name = "sdm/demo/api"
}

data "aws_secretsmanager_secret_version" "sdm_token_secret" {
  secret_id = data.aws_secretsmanager_secret.sdm_secret.id
}

# ssh
data "aws_key_pair" "ssh_key" {
  key_name = "sdm_demo_pub_key"
}

# tags
variable "purpose_tag" {
    description = "repetitive tag"
    default = "sdm demo resources"
}

variable "project_name" {
    description = "portion of name tag that is repetitive"
    default = "sdm-demo-"
}

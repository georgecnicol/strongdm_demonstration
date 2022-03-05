# This is the flask app running in docker as a fargate task - turtles all the way down for fun
# ecs cluster, task definitions, etc


locals {
  ecr_repo    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/sdm_demo"
  region      = "${data.aws_region.current.name}"
  log_group   = "${aws_cloudwatch_log_group.sdm_demo_ecs_container_cloudwatch_loggroup.name}"
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}cluster"

  tags = {
    Name = "${var.project_name}fargate-cluster"
    Purpose = var.purpose_tag
  }
}

#task definition gets default private ip. set public ip to false.
resource "aws_ecs_task_definition" "sdm_demo_ecs_task_definition" {
  family                   = "${var.project_name}ECSTaskDefinition"
  task_role_arn            = "${aws_iam_role.sdm_demo_ecs_task_role.arn}"
  execution_role_arn       = "${aws_iam_role.sdm_demo_ecs_task_execution_role.arn}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  tags = {
    Name = "${var.project_name}fargate-task-definition"
    Purpose = var.purpose_tag
  }
  container_definitions = <<DEFINITION
[
  {
    "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "${local.log_group}",
            "awslogs-region": "${local.region}",
            "awslogs-stream-prefix": "/aws/ecs"
          }
        },
    "cpu":0,
    "dnsSearchDomains":[],
    "dnsServers":[],
    "dockerLabels":{},
    "dockerSecurityOptions":[],
    "essential":true,
    "extraHosts":[],
    "image": "${local.ecr_repo}",
    "links":[],
    "mountPoints":[],
    "name": "fargate-app",
    "portMappings":[
      {
        "containerPort": 5000,
        "hostPort":5000,
        "protocol": "tcp"
      }
    ],
    "ulimits":[],
    "volumesFrom":[],
    "environment": [
        {"name": "REGION", "value": "${local.region}"}
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "sdm_demo_fargate_service" {
    name ="sdm_demo_fargate_service"
    cluster = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.sdm_demo_ecs_task_definition.arn
    scheduling_strategy = "REPLICA" # fargate does not support daemon
    desired_count = 1
    launch_type = "FARGATE"
    # iam_role =  aws_iam_role.sdm_demo_ecs_role #  If using awsvpc network mode, do not specify this role
    depends_on = [aws_iam_role_policy.sdm_demo_ecs_policy]

    # ordered_placement_strategy - not required with 1 instance
    # placement_constraints - none here
    # service_registries - not using any of this for internal ip accessible content. might be useful for out of scope internal DNS

    network_configuration {
      subnets = [aws_subnet.subnetA.id]
      security_groups = [ aws_security_group.fargate_allow_sdm.id, aws_security_group.generic_outbound.id ]
      assign_public_ip = true
    }
}


# Cloudwatch logs
resource "aws_cloudwatch_log_group" "sdm_demo_ecs_container_cloudwatch_loggroup" {
  name = "${var.project_name}cloudwatch-log-group"

  tags = {
    Name    = "${var.project_name}cloudwatch-log-group"
    Purpose = var.purpose_tag
  }
}

resource "aws_cloudwatch_log_stream" "sdm_demo_ecs_container_cloudwatch_logstream" {
  name           = "${var.project_name}cloudwatch-log-stream"
  log_group_name =  "${aws_cloudwatch_log_group.sdm_demo_ecs_container_cloudwatch_loggroup.name}"
}

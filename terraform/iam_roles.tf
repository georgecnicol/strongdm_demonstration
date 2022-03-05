locals {
  iam_role_name       = "${var.project_name}ECSRunTaskSyncExecutionRole"
  iam_policy_name     = "${var.project_name}FargateTaskNotificationAccessPolicy"
  iam_task_role_policy_name = "${var.project_name}ECS-Task-Role-Policy"
}

resource "aws_iam_role" "sdm_demo_ecs_role" {
  name               = "${local.iam_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.sdm_demo_ecs_policy_document.json}"
}

data "aws_iam_policy_document" "sdm_demo_ecs_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "sdm_demo_ecs_policy" {
  name = "${local.iam_policy_name}"
  role = "${aws_iam_role.sdm_demo_ecs_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:GetLogEvents",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetRole",
                "iam:PassRole"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowPull",
            "Resource": [
                "${data.aws_ecr_repository.ecr_sdm_demo.arn}"
            ],
            "Effect": "Allow",
            "Action": [
                "ecr:List*",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ]
        },
        {
            "Action": [
                "ecs:RunTask"
            ],
            "Resource": [
                "${aws_ecs_task_definition.sdm_demo_ecs_task_definition.arn}"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "ecs:StopTask",
                "ecs:DescribeTasks"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "events:PutTargets",
                "events:PutRule",
                "events:DescribeRule"
            ],
            "Resource": [
                "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/SdmDemoGetEventsForECSTaskRule"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}


# ECS Tasks - role and executution roles

resource "aws_iam_role" "sdm_demo_ecs_task_execution_role" {
  name = "${var.project_name}ECS-TaskExecution-Role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "sdm_demo_ecs_task_role" {
  name = "${var.project_name}ECS-Task-Role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "sdm_demo_ecs_task_execution_role_policy_attachment" {
  role       = "${aws_iam_role.sdm_demo_ecs_task_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

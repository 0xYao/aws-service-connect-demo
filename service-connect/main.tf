# ---------------------------------------- Networking configuration start --------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_region" "current" {}


module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp"]
  egress_rules        = ["all-all"]
}
# ---------------------------------------- Networking configuration end ----------------------------------------

resource "aws_lb_target_group" "webserver_lb_tg" {
  name        = "webserver-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_lb" "webserver_lb" {
  name               = "webserver-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [module.security_group.security_group_id]
  subnets         = data.aws_subnets.all.ids
}

resource "aws_lb_listener" "webserver_lb_listener" {
  load_balancer_arn = aws_lb.webserver_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webserver_lb_tg.arn
  }
}

resource "aws_service_discovery_http_namespace" "webserver_service_connect_namespace" {
  name = "webserver-service-connect"
}

resource "aws_ecs_cluster" "webserver_ecs_cluster" {
  name = "webserver-cluster"

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.webserver_service_connect_namespace.arn
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonECS_FullAccess", "arn:aws:iam::aws:policy/AWSLambda_FullAccess"]
}

resource "aws_iam_policy" "ecs_task_policy" {
  name = "ecs-task-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy", "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

resource "aws_iam_policy_attachment" "ecs_task_policy_attachment" {
  name       = "ecs-task-policy-attachment"
  roles      = [aws_iam_role.ecs_task_role.name]
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

resource "aws_cloudwatch_log_group" "webserver_service_container_log" {
  name = "/ecs/webserver-nginx-container"
}

resource "aws_ecs_task_definition" "webserver_task" {
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  family                   = "webserver"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "public.ecr.aws/docker/library/nginx:latest"
      essential = true
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/webserver-nginx-container",
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = "webserver-nginx-container"
        }
      }
      memory = 512
      portMappings = [
        {
          name          = "nginx-port"
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_cloudwatch_log_group" "webserver_service_container_log_2" {
  name = "/ecs/webserver-nginx-container-2"
}

resource "aws_ecs_task_definition" "webserver_task_2" {
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  family                   = "webserver"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "public.ecr.aws/docker/library/nginx:latest"
      essential = true
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/webserver-nginx-container-2",
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = "webserver-nginx-container"
        }
      }
      memory = 512
      portMappings = [
        {
          name          = "nginx-port"
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_cloudwatch_log_group" "webserver_service_connect_log" {
  name = "/ecs/webserver-nginx"
}

resource "aws_ecs_service" "webserver" {
  name            = "webserver-service"
  cluster         = aws_ecs_cluster.webserver_ecs_cluster.id
  task_definition = aws_ecs_task_definition.webserver_task.arn
  desired_count   = 1
  depends_on      = [aws_lb_listener.webserver_lb_listener]

  launch_type            = "FARGATE"
  enable_execute_command = true

  service_connect_configuration {
    enabled = true
    service {
      # Match the name of the portMappings in the container definitions
      port_name = "nginx-port"
      client_alias {
        port     = 80
        dns_name = "nginx"
      }
    }
    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/webserver-nginx"
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "webserver-nginx"
      }
    }
  }

  network_configuration {
    assign_public_ip = true
    subnets          = data.aws_subnets.all.ids
    security_groups  = [module.security_group.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.webserver_lb_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }
}

resource "aws_cloudwatch_log_group" "webserver_service_connect_log_2" {
  name = "/ecs/webserver-nginx-2"
}

resource "aws_ecs_service" "webserver_2" {
  name            = "webserver-service"
  cluster         = aws_ecs_cluster.webserver_ecs_cluster.id
  task_definition = aws_ecs_task_definition.webserver_task_2.arn
  desired_count   = 1

  launch_type            = "FARGATE"
  enable_execute_command = true

  service_connect_configuration {
    enabled = true
    service {
      # Match the name of the portMappings in the container definitions
      port_name = "nginx-port"
      client_alias {
        port     = 80
        dns_name = "nginx"
      }
    }
    log_configuration {
      log_driver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/webserver-nginx-2"
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "webserver-nginx"
      }
    }
  }

  network_configuration {
    assign_public_ip = true
    subnets          = data.aws_subnets.all.ids
    security_groups  = [module.security_group.security_group_id]
  }
}


# Get default VPC
data "aws_vpcs" "default" {
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

locals {
  default_vpc_id = data.aws_vpcs.default.ids[0]
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [local.default_vpc_id]
  }
}


resource "aws_iam_role" "ecs_task_execution" {
  # name = "docker-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role      = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



# Security Group
resource "aws_security_group" "strapi_sg" {
  name   = "docker-strapi-sg1-one"
  vpc_id = local.default_vpc_id

  ingress {
    from_port      = 1337
    to_port        = 1337
    protocol       = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]
  }

  ingress {
    from_port      = 5432
    to_port        = 5432
    protocol       = "tcp"
    cidr_blocks    = ["0.0.0.0/0"]
  }
  

  egress {
    from_port   = 0
    to_port        = 0
    protocol      = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "strapi" {
  name                     = "/ecs/docker-strapi-con"
  retention_in_days = 7
}

# aws cluster
resource "aws_ecs_cluster" "cluster" {
  name = "docker-strapi-cluster"
 
}


resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = var.ecr_image
      essential = true
      portMappings = [{
        containerPort = 1337
        hostPort      = 1337
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.strapi_log_group.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs/strapi"
        }
      }
    }
  ])

  depends_on = [aws_cloudwatch_log_group.strapi_log_group]
}

# ECS Service (using FARGATE SPOT!)
resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  # Add this load balancer configuration
  load_balancer {
    target_group_arn = aws_lb_target_group.blue_tg.arn # Initial target group
    container_name   = "strapi"
    container_port   = 1337
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [
      task_definition, # CodeDeploy will manage this
      load_balancer    # CodeDeploy will handle traffic shifting
    ]
  }
}

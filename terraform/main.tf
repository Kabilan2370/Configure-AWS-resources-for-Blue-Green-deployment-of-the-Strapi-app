
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
  name   = "strapi-docker-sg1"
  vpc_id = local.default_vpc_id

  ingress {
    from_port      = 1337
    to_port        = 1337
    protocol       = "tcp"
    security_groups    = [aws_security_group.alb.id]
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


resource "aws_ecs_task_definition" "strapi" {
  family                   			= "docker-strapi-task"
  requires_compatibilities 	  	= ["FARGATE"]
  network_mode             	  	= "awsvpc"
  cpu                      			= 512
  memory                   			= 1024
  execution_role_arn       	  	= aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
  {
    name      = "placeholder"
    image     = var.image_uri
    essential = true


    portMappings = [
      { containerPort = 1337 }
    ]


    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         	= "/ecs/docker-strapi-con"
        "awslogs-region"        	= "eu-north-1"
        "awslogs-stream-prefix" 	= "ecs"
      }
    }

    

    environment = [

      { name = "DATABASE_CLIENT", value = "postgres" },
      { name = "DATABASE_HOST", value = aws_db_instance.strapi.address },
      { name = "DATABASE_PORT", value = "5432" },
      { name = "DATABASE_NAME", value = "strapi" },
      { name = "DATABASE_USERNAME", value = "strapi" },
      { name = "DATABASE_PASSWORD", value = "StrapiPassword123!" },

      { name = "DATABASE_SSL", value = "true" },
      { name = "DATABASE_SSL_REJECT_UNAUTHORIZED", value = "false" },

      { name = "APP_KEYS", value = "r9pQ7fC0y6nYvP1H0M8z2KZ+FZt9JqYpR8aM1s3EwQ4=,m3L2V7N+Kx0T9fQWJ5p8E4rZPZCq+S6A1yH0MdnYv8=,FZ+P9Jq3sM0yQ7r8aK6L1Tz4VnH2E5CwWmRZx=,xZ9E1r2V7p8C6Wq0mM5QJH3N4Y+LZsAFTk=" },
      { name = "API_TOKEN_SALT", value = "S8Z3xH0QJ7r2p9C6yF5M+K4TnE1A=" },
      { name = "ADMIN_JWT_SECRET", value = "Z1x8K9yH3pQF7J0+E2C4rV6mN5A=" },
      { name = "JWT_SECRET", value = "H5N6M8JZ9QF0y+K7pE3x1rC4V2A=" }
    ]

    }
  ])
}

resource "aws_ecs_service" "service" {
  name            	= "docker-strapi-ecs-service"
  cluster         	= aws_ecs_cluster.cluster.id
  task_definition 	= aws_ecs_task_definition.strapi.arn
  desired_count   	= 1
  launch_type     	= "FARGATE"

  network_configuration {
    subnets                  = data.aws_subnets.default.ids
    security_groups          = [aws_security_group.strapi_sg.id]
    assign_public_ip          = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue_strapi.arn
    container_name   = "placeholder"
    container_port   = 1337
  }

  deployment_controller {
    type = "CODE_DEPLOY" 
  }

  depends_on = [
      aws_lb_listener.http
  ]


}

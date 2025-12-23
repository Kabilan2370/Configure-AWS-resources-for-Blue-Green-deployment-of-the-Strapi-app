
# security group for alb
resource "aws_security_group" "alb" {
  name        = "docker-strapi-alb-sg2"
  description = "Allow HTTP inbound"
  vpc_id      = local.default_vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# blue target group for application load balancer
resource "aws_lb_target_group" "blue_strapi" {
  name        = "blue-docker-strapi-tg2"
  port        = 1337
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.default_vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# green target group for application load balancer
resource "aws_lb_target_group" "green_strapi" {
  name        = "green-docker-strapi-tg2"
  port        = 1337
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.default_vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb" "strapi" {
  name               = "docker-strapi-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
}

# load balancer listener attached with 2 target groups

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.strapi.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue_strapi.arn
  }
}


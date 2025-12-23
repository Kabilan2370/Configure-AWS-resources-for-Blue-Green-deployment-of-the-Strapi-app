# iam role for code deploy
resource "aws_iam_role" "codedeploy_role" {
  name = "ecs-codedeploy-docker-strapi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# code deploy application
resource "aws_codedeploy_app" "ecs_app" {
  name = "ecs-docker-strapi-deploy"
  compute_platform = "ECS"
}

# code deployment group
resource "aws_codedeploy_deployment_group" "ecs_deployment_group" {
  app_name              = aws_codedeploy_app.ecs_app.name
  deployment_group_name = "ecs-strapi-dg"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
  

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.service.name
  }

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.blue_strapi.name
      }
      target_group {
        name = aws_lb_target_group.green_strapi.name
      }

      prod_traffic_route {
        listener_arns = [aws_lb_listener.http.arn]
      }

    
    }
  }

  # Enable automatic rollback on failure
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

  deployment_ready_option {
    action_on_timeout = "CONTINUE_DEPLOYMENT"
}

    
    
}


}



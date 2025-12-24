# Configure-AWS-resources-for-Blue-Green-deployment-of-the-Strapi-app

# **Blue/Green Deployment for Strapi on AWS**

### What is placeholder ?
Placeholder = temporary container used only Later, Before your real CI/CD pipeline pushes your custom Strapi image, codeDeploy replaces it with your real app image. There is no difference between the strapi image vs placeholder strapi image.

### 1. Create ECS Cluster

Create an ECS Cluster with Fargate


### 2. I have created 2 Security Groups

1. ALB Security Group

Allow inbound traffic from the internet:

HTTP → Port 80   HTTPS → Port 443

2. ECS Service Security Group

Allow inbound traffic only from ALB:

Port: 1337

Source: ALB Security Group
   

### 3. Create Application Load Balancer (ALB)

Created an Application Load Balancer with 2 different target groups aattached with this

1. Bule target group
2. Green target group

### What is the usage of creating multiple target groups ?
Creating multiple target groups allows for complex traffic routing, such as directing different request types or traffic from internal/external sources to specific backends.

### Suppose you have:

/api → Strapi

/admin → Admin panel

/static → Static site

You can create one ALB and three target groups


### 4. Configure ALB Listeners
Listener on Port 80 (HTTP)

Default action → Forward traffic to Blue Target Group

Listener on Port 443

Default action → Forward traffic to Blue Target Group

During deployments, CodeDeploy will automatically shift traffic between Blue ↔ Green target groups.


### 5. Create ECS Task Definition (Placeholder)


Created a Task definition with Fargate and default vpc and subnet.

Container:

Image: nginx:latest placeholder image

Container port: 1337

This task definition will be dynamically updated by CI/CD.


### 6. Create ECS Service (Blue/Green Enabled)

Create ECS Service with Fargate

Deployment controller: CODE_DEPLOY

Attach:

ALB attached with Blue and green Target Group

Assign : ECS Security Group

### 7. Create AWS CodeDeploy Application

Created a CodeDeploy Application choose the Compute platform as ECS

### 8. Create CodeDeploy Deployment Group

Configure Deployment Group with:

⚙️ Deployment Settings

Deployment type: Blue/Green

Traffic control: ALB

### Deployment strategy: CodeDeployDefault.ECSCanary10Percent5Minutes
When I deploy a new ECS version, send only 10% of traffic to it first, wait 5 minutes, then (if healthy) send 100% traffic.

### AWSCodeDeployRoleForECS
This policy allows CodeDeploy to:

1. Create new ECS task sets
2. Shift ALB traffic
3. Stop old tasks
4. Roll back on failure

### What this means:

1. BLUE_GREEN → old & new versions exist at same time

2. WITH_TRAFFIC_CONTROL → ALB traffic is shifted gradually

### deployment_ready_option
If new task doesn’t become “ready” in time, Still continue deployment


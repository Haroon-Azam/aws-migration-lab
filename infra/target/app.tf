variable "my_ip" {
  description = "My laptop's public IP as x.x.x.x/32 (only I can reach the load balancer for now)"
  type        = string
}

variable "repo_url" {
  description = "Where app servers download the code from"
  type        = string
  default     = "https://github.com/Haroon-Azam/aws-migration-lab.git"
}

# Latest Amazon Linux 2023 image
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# --- Firewalls ---------------------------------------------------------------

# Load balancer: HTTP from my laptop only
resource "aws_security_group" "alb" {
  name        = "target-alb-sg"
  description = "Load balancer: HTTP from my IP"
  vpc_id      = aws_vpc.target.id

  ingress {
    description = "HTTP from my laptop"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "target-alb-sg" }
}

# App servers: port 4000 only from the load balancer's security group
resource "aws_security_group" "app" {
  name        = "target-app-sg"
  description = "App servers: API from the load balancer only"
  vpc_id      = aws_vpc.target.id

  ingress {
    description     = "API from the load balancer"
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Out through the NAT Gateway (packages, GitHub, Secrets Manager) and to RDS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "target-app-sg" }
}

# --- Badge for app servers -----------------------------------------------------

resource "aws_iam_role" "app" {
  name = "target-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Session Manager (a terminal with no SSH)
resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Least privilege: read ONE secret, the RDS password, and nothing else
resource "aws_iam_role_policy" "app_read_db_secret" {
  name = "read-db-secret"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = aws_db_instance.target.master_user_secret[0].secret_arn
    }]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "target-app-profile"
  role = aws_iam_role.app.name
}

# --- The recipe for an app server ----------------------------------------------

resource "aws_launch_template" "app" {
  name_prefix            = "target-app-"
  image_id               = data.aws_ssm_parameter.al2023.insecure_value
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  metadata_options {
    http_tokens = "required"
  }

  user_data = base64encode(templatefile("${path.module}/app-user-data.sh.tftpl", {
    repo_url   = var.repo_url
    region     = "ca-central-1"
    secret_arn = aws_db_instance.target.master_user_secret[0].secret_arn
    db_host    = aws_db_instance.target.address
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "target-app-server"
      Project     = "mig-lab"
      Environment = "target"
    }
  }
}

# --- Load balancer -------------------------------------------------------------

resource "aws_lb" "app" {
  name               = "target-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.target["public-a"].id, aws_subnet.target["public-b"].id]
}

resource "aws_lb_target_group" "app" {
  name                 = "target-app-tg"
  port                 = 4000
  protocol             = "HTTP"
  vpc_id               = aws_vpc.target.id
  deregistration_delay = 30

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# --- Keep 2 servers running, one per zone --------------------------------------

resource "aws_autoscaling_group" "app" {
  name                      = "target-app-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.target["app-a"].id, aws_subnet.target["app-b"].id]
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # When the recipe changes, replace servers one batch at a time, keeping half healthy
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "target-app-server"
    propagate_at_launch = true
  }

  # Servers need the NAT route to install packages at boot
  depends_on = [aws_route.private_to_internet]
}

output "app_url" {
  value = "http://${aws_lb.app.dns_name}"
}

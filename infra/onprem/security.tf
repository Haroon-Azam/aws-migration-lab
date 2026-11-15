# The bouncer: my laptop can reach the API; the target app subnets can reach MySQL
resource "aws_security_group" "legacy_server" {
  name        = "onprem-legacy-server-sg"
  description = "Legacy app server: API from my IP only"
  vpc_id      = aws_vpc.onprem.id

  ingress {
    description = "Node.js API from my laptop"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "MySQL from target app subnets (DMS), over peering"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.1.11.0/24", "10.1.12.0/24"]
  }

  egress {
    description = "Server can reach the internet (packages, GitHub)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "onprem-legacy-server-sg" }
}

# The badge: lets the server use AWS services without stored keys
resource "aws_iam_role" "legacy_server" {
  name = "onprem-legacy-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# What the badge allows: Session Manager (a terminal with no SSH)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.legacy_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# The clip that attaches the badge to a server
resource "aws_iam_instance_profile" "legacy_server" {
  name = "onprem-legacy-server-profile"
  role = aws_iam_role.legacy_server.name
}

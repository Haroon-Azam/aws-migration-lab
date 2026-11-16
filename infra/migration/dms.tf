# --- Look up what other folders built ---
data "aws_subnet" "app_a" {
  tags = { Name = "target-app-a" }
}

data "aws_subnet" "app_b" {
  tags = { Name = "target-app-b" }
}

data "aws_instance" "legacy" {
  filter {
    name   = "tag:Name"
    values = ["onprem-legacy-server"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_db_instance" "target" {
  db_instance_identifier = "target-mysql"
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_db_instance.target.master_user_secret[0].secret_arn
}

locals {
  rds_creds = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)
}

# --- The role DMS needs to work inside a VPC (the name must be exactly this) ---
resource "aws_iam_role" "dms_vpc" {
  name = "dms-vpc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "dms.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dms_vpc" {
  role       = aws_iam_role.dms_vpc.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

# --- Firewall: DMS only connects out, never in ---
resource "aws_security_group" "dms" {
  name        = "dms-replication-sg"
  description = "DMS replication instance: outbound only"
  vpc_id      = data.aws_vpc.target.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "dms-replication-sg" }
}

# --- Where DMS lives: the target app subnets (RDS already allows them) ---
resource "aws_dms_replication_subnet_group" "main" {
  replication_subnet_group_id          = "mig-lab-dms-subnets"
  replication_subnet_group_description = "Target app subnets for DMS"
  subnet_ids                           = [data.aws_subnet.app_a.id, data.aws_subnet.app_b.id]

  depends_on = [aws_iam_role_policy_attachment.dms_vpc]
}

# --- The replication server ---
resource "aws_dms_replication_instance" "main" {
  replication_instance_id     = "mig-lab-dms"
  replication_instance_class  = "dms.t3.small"
  allocated_storage           = 20
  publicly_accessible         = false
  multi_az                    = false
  replication_subnet_group_id = aws_dms_replication_subnet_group.main.id
  vpc_security_group_ids      = [aws_security_group.dms.id]
  apply_immediately           = true
}

# --- Source: the legacy MySQL 8.0, reached over the peering ---
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "legacy-mysql-source"
  endpoint_type = "source"
  engine_name   = "mysql"
  server_name   = data.aws_instance.legacy.private_ip
  port          = 3306
  username      = "root"
  password      = var.source_db_password
}

# --- Target: RDS MySQL 8.4, credentials from Secrets Manager ---
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "rds-mysql-target"
  endpoint_type = "target"
  engine_name   = "mysql"
  server_name   = data.aws_db_instance.target.address
  port          = 3306
  username      = local.rds_creds["username"]
  password      = local.rds_creds["password"]
}

output "legacy_private_ip" {
  value = data.aws_instance.legacy.private_ip
}

variable "db_multi_az" {
  description = "Keep a standby copy in the second zone (doubles the cost)"
  type        = bool
  default     = false
}

# Which subnets RDS may use: the two database subnets
resource "aws_db_subnet_group" "target" {
  name       = "target-db-subnets"
  subnet_ids = [aws_subnet.target["db-a"].id, aws_subnet.target["db-b"].id]
  tags       = { Name = "target-db-subnets" }
}

# Only the app subnets can reach MySQL
resource "aws_security_group" "db" {
  name        = "target-db-sg"
  description = "MySQL from the app subnets only"
  vpc_id      = aws_vpc.target.id

  ingress {
    description = "MySQL from the app tier"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [local.subnets["app-a"].cidr, local.subnets["app-b"].cidr]
  }

  tags = { Name = "target-db-sg" }
}

# The managed database
resource "aws_db_instance" "target" {
  identifier     = "target-mysql"
  engine         = "mysql"
  engine_version = "8.4"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "webappdb"
  username                    = "admin"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.target.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  # Never get enrolled in paid Extended Support by accident
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"

  # Lab settings; production would keep backups longer and protect against deletion
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = { Name = "target-mysql" }
}

output "db_endpoint" {
  value = aws_db_instance.target.address
}

output "db_secret_arn" {
  value = aws_db_instance.target.master_user_secret[0].secret_arn
}

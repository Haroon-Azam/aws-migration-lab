# Look up the latest Amazon Linux 2023 image for this region
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# The legacy server: one machine running the API and MySQL
resource "aws_instance" "legacy_server" {
  ami                    = data.aws_ssm_parameter.al2023.insecure_value
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.onprem_public.id
  vpc_security_group_ids = [aws_security_group.legacy_server.id]
  iam_instance_profile   = aws_iam_instance_profile.legacy_server.name

  # The startup script, with the variables filled in
  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    db_password = var.db_password
    repo_url    = var.repo_url
  })
  user_data_replace_on_change = true

  # Security: require IMDSv2 for the instance metadata service
  metadata_options {
    http_tokens = "required"
  }

  # Encrypted disk
  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = "onprem-legacy-server" }
}

output "legacy_server_id" {
  value = aws_instance.legacy_server.id
}

output "legacy_api_url" {
  value = "http://${aws_instance.legacy_server.public_ip}:4000"
}

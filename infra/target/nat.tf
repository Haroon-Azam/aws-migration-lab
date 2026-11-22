# A fixed public IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "target-nat-eip" }
}

# The exit door: lives in a public subnet, lets private servers reach out
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.target["public-a"].id
  tags          = { Name = "target-nat" }

  depends_on = [aws_internet_gateway.target]
}

# Private subnets: anything for the internet goes through the NAT Gateway
resource "aws_route" "private_to_internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

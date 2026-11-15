# The building: our private network
resource "aws_vpc" "onprem" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "onprem-vpc" }
}

# One floor: a public subnet in zone a
resource "aws_subnet" "onprem_public" {
  vpc_id                  = aws_vpc.onprem.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ca-central-1a"
  map_public_ip_on_launch = true
  tags = { Name = "onprem-public-a" }
}

# The front door to the internet
resource "aws_internet_gateway" "onprem" {
  vpc_id = aws_vpc.onprem.id
  tags   = { Name = "onprem-igw" }
}

# The hallway signs: internet traffic goes out the front door
resource "aws_route_table" "onprem_public" {
  vpc_id = aws_vpc.onprem.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.onprem.id
  }

  # infra/migration adds a peering route to this table; don't remove it
  lifecycle {
    ignore_changes = [route]
  }

  tags = { Name = "onprem-public-rt" }
}

# Put the signs up on our floor
resource "aws_route_table_association" "onprem_public" {
  subnet_id      = aws_subnet.onprem_public.id
  route_table_id = aws_route_table.onprem_public.id
}

# Print the IDs after apply
output "vpc_id" {
  value = aws_vpc.onprem.id
}

output "subnet_id" {
  value = aws_subnet.onprem_public.id
}

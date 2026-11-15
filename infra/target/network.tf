# The plan for all 6 subnets in one table
locals {
  subnets = {
    public-a = { cidr = "10.1.1.0/24",  az = "ca-central-1a", tier = "public" }
    public-b = { cidr = "10.1.2.0/24",  az = "ca-central-1b", tier = "public" }
    app-a    = { cidr = "10.1.11.0/24", az = "ca-central-1a", tier = "app" }
    app-b    = { cidr = "10.1.12.0/24", az = "ca-central-1b", tier = "app" }
    db-a     = { cidr = "10.1.21.0/24", az = "ca-central-1a", tier = "db" }
    db-b     = { cidr = "10.1.22.0/24", az = "ca-central-1b", tier = "db" }
  }
}

# The new building
resource "aws_vpc" "target" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "target-vpc" }
}

# All 6 floors, created from the table above
resource "aws_subnet" "target" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.target.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.tier == "public"

  tags = {
    Name = "target-${each.key}"
    Tier = each.value.tier
  }
}

# Front door, used only by the public subnets
resource "aws_internet_gateway" "target" {
  vpc_id = aws_vpc.target.id
  tags   = { Name = "target-igw" }
}

# Public signs: internet traffic goes out the front door
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.target.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.target.id
  }

  tags = { Name = "target-public-rt" }
}

# Private signs: no internet route at all, traffic stays inside the VPC
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.target.id
  tags   = { Name = "target-private-rt" }
}

# Attach each subnet to the right signs: public or private
resource "aws_route_table_association" "target" {
  for_each = local.subnets

  subnet_id      = aws_subnet.target[each.key].id
  route_table_id = each.value.tier == "public" ? aws_route_table.public.id : aws_route_table.private.id
}

output "vpc_id" {
  value = aws_vpc.target.id
}

output "subnet_ids" {
  value = { for name, subnet in aws_subnet.target : name => subnet.id }
}

# Look up the two networks built by infra/onprem and infra/target (by their Name tags)
data "aws_vpc" "onprem" {
  tags = { Name = "onprem-vpc" }
}

data "aws_vpc" "target" {
  tags = { Name = "target-vpc" }
}

data "aws_route_table" "onprem_public" {
  tags = { Name = "onprem-public-rt" }
}

data "aws_route_table" "target_private" {
  tags = { Name = "target-private-rt" }
}

# The private bridge between the two networks
resource "aws_vpc_peering_connection" "onprem_to_target" {
  vpc_id      = data.aws_vpc.onprem.id
  peer_vpc_id = data.aws_vpc.target.id
  auto_accept = true
  tags        = { Name = "onprem-to-target" }
}

# Sign in on-prem: to reach 10.1.x, take the bridge
resource "aws_route" "onprem_to_target" {
  route_table_id            = data.aws_route_table.onprem_public.id
  destination_cidr_block    = data.aws_vpc.target.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.onprem_to_target.id
}

# Sign in target (private subnets): to reach 10.0.x, take the bridge
resource "aws_route" "target_to_onprem" {
  route_table_id            = data.aws_route_table.target_private.id
  destination_cidr_block    = data.aws_vpc.onprem.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.onprem_to_target.id
}

output "peering_id" {
  value = aws_vpc_peering_connection.onprem_to_target.id
}

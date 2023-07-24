resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = merge(
    { "Name" = "${var.name}-vpc" },
    var.tags,
  )
}

################################################################################
# PUBLIC SUBNET
################################################################################

resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  cidr_block        = var.public_subnets[count.index]
  vpc_id            = aws_vpc.main.id
  #availability_zone = "us-east-1a"

  tags = merge(
    { "Name" = "PublicSubnet-${count.index}" },
    var.tags,
  )
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    { "Name" = "Test-igw" },
    var.tags,
  )
}
resource "aws_route_table" "public" {
  count  = length(var.public_subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.public_subnets[count.index]
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(
    { "Name" = "Public-route-${count.index}" },
    var.tags,
  )
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route" "public_internet_gateway" {
  count = length(var.public_subnets)

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id

  timeouts {
    create = "5m"
  }
  depends_on = [aws_internet_gateway.gw]
}

################################################################################
# PRIVATE SUBNET
################################################################################

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  cidr_block        = var.private_subnets[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1a"

  tags = merge(
    { "Name" = "PrivateSubnet-${count.index}" },
    var.tags,
  )
}

resource "aws_eip" "nat" {
  vpc = "true"

  tags = var.tags

}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.private[0].id

    tags = merge(
    { "Name" = "${var.name}-ngw" },
    var.tags,
  )
    depends_on = [aws_subnet.private]
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets)

  vpc_id = aws_vpc.main.id

  tags = merge(
    { "Name" = "PrivateRouteTable-${count.index}" },
    var.tags,
  )
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private[0].id
}




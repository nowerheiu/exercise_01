resource "aws_vpc" "js_vpc" {
  cidr_block                     = "10.0.0.0/16"
  enable_dns_hostnames           = true
  enable_dns_support             = true
  enable_classiclink_dns_support = true
 
  tags = merge(var.project_tags, {
    Name = "js_vpc"
  })
}

### Subnets ###

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.js_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(var.project_tags, {
    Name = "js_public-subnet"
  })
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.js_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = merge(var.project_tags, {
    Name = "js_private-subnet"
  })
}

### Gateways ###

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id            = aws_vpc.js_vpc.id

  tags = merge(var.project_tags, {
    Name = "js_internet_gw"
  })
}

resource "aws_eip" "nat_gateway" {
  vpc = true
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = merge({
    Name = "js_NAT_gw"
  }, var.project_tags)
}

### Route tables ###

resource "aws_route_table" "public" {
  vpc_id            = aws_vpc.js_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = merge(var.project_tags, {
    Name = "js_public_rt"
  })
}

resource "aws_route_table" "private" {
  vpc_id            = aws_vpc.js_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = merge(var.project_tags, {
    Name = "js_private_rt"
  })
}


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "js_security_group" {
  name              = "HTTP and SSH"
  vpc_id            = aws_vpc.js_vpc.id

  ingress {
    protocol   = "tcp"
    cidr_block = ["0.0.0.0/0"]
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    cidr_block = ["118.189.0.0/16","116.206.0.0/16","223.25.0.0/16"]
    from_port  = 80
    to_port    = 80
  }


  egress {
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  tags = merge(var.project_tags, {
    Name = "js_nacl"
  })
}

### NACLs ###

# resource "aws_network_acl" "public" {
#   vpc_id            = aws_vpc.js_vpc.id

#   egress {
#     protocol   = "tcp"
#     rule_no    = 110
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   egress {
#     protocol   = "tcp"
#     rule_no    = 150
#     action     = "allow"
#     cidr_block = "10.0.1.0/24"
#     from_port  = 22
#     to_port    = 22

#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 120
#     action     = "allow"
#     cidr_block = var.public_ip
#     from_port  = 22
#     to_port    = 22

#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 110
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 443
#     to_port    = 443
#   }

#   tags = merge(var.project_tags, {
#     Name = "public-nacl"
#   })
# }

# resource "aws_network_acl" "private" {
#   vpc_id            = aws_vpc.js_vpc.id

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 120
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 22
#     to_port    = 22
#   }

#   ingress {
#     protocol   = "tcp"
#     rule_no    = 100
#     action     = "allow"
#     cidr_block = ["118.189.0.0/16","116.206.0.0/16","223.25.0.0/16"]
#     from_port  = 80
#     to_port    = 80
#   }

#   tags = merge(var.project_tags, {
#     Name = "private-nacl"
#   })

# }

# resource "aws_network_acl_association" "public" {
#   network_acl_id = aws_network_acl.public.id
#   subnet_id      = aws_subnet.public.id
# }

# resource "aws_network_acl_association" "private" {
#   network_acl_id = aws_network_acl.private.id
#   subnet_id      = aws_subnet.private.id
# }
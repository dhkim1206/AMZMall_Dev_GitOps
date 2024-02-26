# C:\AMZMall_Dev_GitOps\terraform\examples\complete\vpc.tf
# VPC
resource "aws_vpc" "amz_draw_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = var.infra_name
  }
}

# 퍼블릭 서브넷 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.amz_draw_vpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = var.azs[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.infra_name}_public_subnet_1"
    "kubernetes.io/role/elb" = "1"
  }
}

# 퍼블릭 서브넷 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.amz_draw_vpc.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = var.azs[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.infra_name}_public_subnet_2"
    "kubernetes.io/role/elb" = "1"
  }
}

# 프라이빗 서브넷 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.amz_draw_vpc.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = var.azs[0]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.infra_name}_private_subnet_1"
  }
}

# 프라이빗 서브넷 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.amz_draw_vpc.id
  cidr_block        = "192.168.4.0/24"
  availability_zone = var.azs[1]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.infra_name}_private_subnet_2"
  }
}

# 인터넷 게이트웨이 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.amz_draw_vpc.id
  tags = {
    Name = "${var.infra_name}_igw"
  }
}


################################################################################
# NAT Instance
################################################################################

# 보안그룹 - NAT Instance
resource "aws_security_group" "nat_instance_sg" {
  name        = "nat-instance-sg"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.amz_draw_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nat-instance-sg"
  }
}

# NAT Instance 1
resource "aws_instance" "nat_instance_1" {
  ami           = "ami-08074b02473276b92"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_1.id # 첫 번째 퍼블릭 서브넷의 ID
  security_groups = [aws_security_group.nat_instance_sg.id]

  associate_public_ip_address = true
  source_dest_check = false

  tags = {
    Name = "${var.infra_name}-NAT-Instance"
  }
}

# 탄력적 ip 할당
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# 탄력적 ip 연결
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.nat_instance_1.id
  allocation_id = aws_eip.nat_eip.id
}


################################################################################
# NAT GateWay
################################################################################


# resource "aws_eip" "nat_eip_1" {
#   domain = "vpc"
#   depends_on = [aws_internet_gateway.igw]
# }

# resource "aws_nat_gateway" "nat_gw_1" {
#   allocation_id = aws_eip.nat_eip_1.id
#   subnet_id     = aws_subnet.public_subnet_1.id
#   tags = {
#     Name = "${var.infra_name}_nat_gw_1"
#   }
# }

# resource "aws_eip" "nat_eip_2" {
#   domain = "vpc"
#   depends_on = [aws_internet_gateway.igw]
# }

# resource "aws_nat_gateway" "nat_gw_2" {
#   allocation_id = aws_eip.nat_eip_2.id
#   subnet_id     = aws_subnet.public_subnet_2.id
#   tags = {
#     Name = "${var.infra_name}_nat_gw_2"
#   }
# }
################################################################################
# private route table
################################################################################

# 프라이빗 라우팅 테이블 생성 및 서브넷 연결 ( 프라이빗 서브넷 -> NAT 용도 )
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.amz_draw_vpc.id
  tags = {
    Name = "${var.infra_name}_private_rt"
  }
}

# 라우팅 테이블에 서브넷 연결
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

# 라우팅 테이블에 서브넷 연결
resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}




################################################################################
# private route - NAT Instance
################################################################################

# 라우팅 지정 ( Private Subnet -> NAT )
resource "aws_route" "private_to_nat" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id = data.aws_network_interface.nat_instance_1_ni.id
}

# 네트워크 인터페이스 생성
data "aws_network_interface" "nat_instance_1_ni" {
  filter {
    name   = "attachment.instance-id"
    values = [aws_instance.nat_instance_1.id]
  }
}

################################################################################
# private route table - NAT GW
################################################################################
# resource "aws_route" "private_rt_nat_gw_1" {
#   route_table_id         = aws_route_table.private_rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.nat_gw_1.id
# }
################################################################################
# public route table
################################################################################
# 퍼블릭 라우팅 테이블
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.amz_draw_vpc.id
  tags = {
    Name = "${var.infra_name}-public"
  }
}

# 라우팅 & CIDR 지정  (Public Subnet -> 인터넷 게이트웨이)
resource "aws_route" "public_rt_igw" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# 라우팅 테이블에 서브넷 id 할당 ( 퍼블릭 서브넷 )
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

# 라우팅 테이블에 서브넷 id 할당 ( 퍼블릭 서브넷 )
resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# resource "aws_default_network_acl" "amz_draw_vpc.default_network_acl" {
#   default_network_acl_id = aws_vpc.amz_draw_vpc.default_network_acl_id

#   tags = {
#     Name = "${var.infra_name}-default"
#   }

#     egress {
#     action          = "allow"
#     from_port       = 0
#     ipv6_cidr_block = "::/0"
#     protocol        = "-1"
#     rule_no         = 101
#     to_port         = 0
#   }

#   egress {
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     protocol   = "-1"
#     rule_no    = 100
#     to_port    = 0
#   }

#   ingress {
#     action          = "allow"
#     from_port       = 0
#     ipv6_cidr_block = "::/0"
#     protocol        = "-1"
#     rule_no         = 101
#     to_port         = 0
#   }

#   ingress {
#     action     = "allow"
#     cidr_block = "0.0.0.0/0"
#     from_port  = 0
#     protocol   = "-1"
#     rule_no    = 100
#     to_port    = 0
#   }
# }

resource "aws_default_security_group" "amz" {
  vpc_id = aws_vpc.amz_draw_vpc.id

  tags = {
    Name = "${var.infra_name}-default"
  }
}
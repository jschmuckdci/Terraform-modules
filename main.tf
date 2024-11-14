provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "My-VPC"
  }
}

module "public_subnet" {
  source = "./subnet_module"
  vpc = aws_vpc.my-vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-2a"
  map_public_on_launch = true
  name = "public"
}

module "private_subnet" {
  source = "./subnet_module"
  vpc = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2b"
  map_public_on_launch = false
  name = "private"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "Internet-Gateway"
  }
}

resource "aws_eip" "nat_eip" {
    vpc = true #may need depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = module.public_subnet.subnet_id

  tags = {
    Name = "NAT-Gateway"
  }
}

module "public_route_table" {
  source = "./route_table_module"
  vpc = aws_vpc.my-vpc.id
  internet_gateway = aws_internet_gateway.igw.id
  name = "public route table"
}

module "private_route_table" {
  source = "./route_table_module"
  vpc = aws_vpc.my-vpc.id
  nat_gateway = aws_nat_gateway.nat.id
  name = "private route table"
}

#associate the route tables with the subnets
module "public_subnet_association" {
  source = "./route_table_assoc_module"
  sub_id = module.public_subnet.subnet_id
  rt_id = module.public_route_table.my_rt_id
}

module "private_subnet_association" {
  source = "./route_table_assoc_module"
  sub_id = module.private_subnet.subnet_id
  rt_id = module.private_route_table.my_rt_id
}

# module "security_group" {
#   source = "./security_group_module"
#   vpc = aws_vpc.my-vpc.id
# }

resource "aws_security_group" "my_sg" {
  description = "sg allowing access on ports 22, 80 and 443"
  vpc_id = aws_vpc.my-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "public_instance" {
  source = "./ec2_module"
  sub_id = module.public_subnet.subnet_id
  sg = aws_security_group.my_sg.id
  name = "public instance"
}

module "private_instance" {
  source = "./ec2_module"
  sub_id = module.private_subnet.subnet_id
  sg = aws_security_group.my_sg.id
  name = "private instance"
}

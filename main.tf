provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Jim-VPC"
  }
}

module "public_subnet" {
  source = "./subnet_module"
  vpc = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_on_launch = true
}

module "private_subnet" {
  source = "./subnet_module"
  vpc = aws_vpc.my-vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_on_launch = false
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
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "NAT-Gateway"
  }
}

module "public_route_table" {
  source = "./route_table_module"
  vpc = aws_vpc.my-vpc.id
  internet_gateway = aws_internet_gateway.igw.id
}

module "private_route_table" {
  source = "./route_table_module"
  vpc = aws_vpc.my-vpc.id
  nat_gateway = aws_nat_gateway.nat.id

}

#associate the route tables with the subnets

#when you call a module, you pass in the variables

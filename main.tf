terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
 
provider "aws" {
  region = "ap-south-1"
}
 
resource "aws_vpc" "web_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "terraform-web-vpc" }
}
 
resource "aws_internet_gateway" "web_igw" {
  vpc_id = aws_vpc.web_vpc.id
  tags   = { Name = "terraform-web-igw" }
}
 
resource "aws_subnet" "web_subnet" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags                    = { Name = "terraform-web-subnet" }
}
 
resource "aws_route_table" "web_rt" {
  vpc_id = aws_vpc.web_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web_igw.id
  }
  tags = { Name = "terraform-web-rt" }
}
 
resource "aws_route_table_association" "web_rta" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.web_rt.id
}
 
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.web_vpc.id
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = { Name = "terraform-web-sg" }
}
 
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
 
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}
 
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.web_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data              = file("setup.sh")
 
  tags = { Name = "Terraform-Linux-WebServer" }
}
 
output "website_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}

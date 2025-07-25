variable "key_name" {
  description = "EC2 Key Pair Name"
  type        = string
  default     = "default-key" # Replace with your actual EC2 key pair name
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "internet-gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = 3
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet("10.0.1.0/24", 4, count.index)
  map_public_ip_on_launch = true
  availability_zone = ["us-east-1a", "us-east-1b", "us-east-1c"][count.index]
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public_association" {
  count          = 3
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "private_subnets" {
  count             = 3
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = cidrsubnet("10.0.100.0/24", 4, count.index)
  availability_zone = ["us-east-1a", "us-east-1b", "us-east-1c"][count.index]
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow ports 88, 22, 8080"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

resource "aws_instance" "ubuntu_ec2" {
  ami                         = "ami-0c02fb55956c7d316" # Ubuntu 22.04 LTS in us-east-1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnets[0].id
  security_groups             = [aws_security_group.web_sg.name]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name = "ubuntu-ec2"
  }
}

output "public_ip" {
  value = aws_instance.ubuntu_ec2.public_ip
}